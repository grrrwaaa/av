

local input, output, libname = ...

local ffy = {}

if input then
	local f = assert(io.popen(string.format("gcc -E %s", input)), "failed to open "..input)
	local pp = f:read("*a")
	f:close()
	
	local f = assert(io.open(input), "failed to open "..input)
	local raw = f:read("*a")
	f:close()
	
	local res = {
		"local ffi = require 'ffi'",
		"local m = {}",
	}
	
	for l in raw:gmatch("%s[^%c]+") do
		local def, val = l:match("%s#define%s([%w_]+)(.*)")
		if def then
			if val then
				val = val:match("%s([^%s]+)")
				if val and not tonumber(val) then
					val = string.format("m[%q]", val)
				end
			end
			val = val or "1"
			res[#res+1] = string.format("m[%q] = %s", def, val)
		end
	end
	
	res[#res+1] = "m.header = [["
	
	local cdef = {}
	local capture = true
	for l in pp:gmatch("%s[^%c]+") do
		local line, file = l:match("%s#%s(%d+)%s\"([%w/%.]+)")
		if file then 
			capture = file == input
			--print(file, capture) 
		elseif capture then
			if l:match("%s#") then
				-- skip @pragmas etc.
			else
				l = l:gsub("__attribute__ %b()%s", "")
				l = l:gsub("[\n]+", "\n")
				if #l > 0 then
					cdef[#cdef+1] = l
				end
			end
		end
	end
	-- remove the first line
	print("removed", table.remove(cdef, 1))
		
	res[#res+1] = table.concat(cdef)
	res[#res+1] = "]]"
	res[#res+1] = "ffi.cdef(m.header)"
	
	if libname then
		res[#res+1] = string.format([[
local lib = ffi.load("%s")
setmetatable(m, {
	__index = lib,
})		
		]], libname)
	end
	res[#res+1] = "return m"
	
	res = table.concat(res, "\n")
	
	if output then
		local f = io.open(output, "w")
		f:write(res)
		f:close()
		print("wrote to ", output)
	end
end

return ffy
