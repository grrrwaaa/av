-- A collection of highly re-usable Lua utilities
local util = {}

local format = string.format
local concat = table.concat

-- weak-valued map of objects that have a gc sentinel referencing them:
local gcmap = {}
setmetatable(gcmap, { __mode = 'v' })

--- return an object that will call func when it is garbage collected:
-- (Sentinel pattern)
-- Note: this is not necessary in Lua 5.2 where tables can have __gc metamethods
-- @param self an object to pass to this gcfunc
-- @param gcfunc a function to call
-- @return obj (for method chaining)
function util.gc(self, gcfunc)
	-- create new raw userdata with metatable:
	local gc = newproxy(true)
	getmetatable(gc).__gc = function() gcfunc(self) end
	-- keep gc alive as long as self exists:
	gcmap[gc] = self
	-- return self for method chaining (also like ffi.gc)
	return self
end

--- return a pretty-formatted string representation of a table:
-- @param t the table to print
-- @return string
function util.table_tostring(t) end
local table_tostring

-- TODO: handle multiple references without error (but not recursion)
-- TODO: handle recursion without error

local keywords = {
	["and"] = true,       
	["break"] = true,     
	["do"] = true,        
	["else"] = true,      
	["elseif"] = true,
    ["end"] = true,       
    ["false"] = true,     
    ["for"] = true,       
    ["function"] = true,  
    ["if"] = true,
    ["in"] = true,        
    ["local"] = true,     
    ["nil"] = true,       
    ["not"] = true,       
    ["or"] = true,
    ["repeat"] = true,    
    ["return"] = true,    
    ["then"] = true,      
    ["true"] = true,      
    ["until"] = true,     
    ["while"] = true,
}

local varpat = "^%a[%w_]*$"

local function dict_keylist_sorter(a, b)
	local ta,tb = type(a), type(b)
	if ta == tb then
		return a < b
	else 
		return ta > tb
	end
end

local function dict_keylist(t)
	local res = {}
	for k, v in pairs(t) do
		res[#res+1] = k
	end
	table.sort(res, dict_keylist_sorter)
	return res
end

local function dict_keystr(k, ind)
	if type(k) == "string" and k:match(varpat) and not keywords[k] then	
		return k
	elseif type(k) == "number" and k == math.floor(k) then
		return format("%d", k)
	else
		return format("[%q]", k)
	end
end	

local function dict_valstr(v, ind, memo)
	if type(v) == "string" then	-- TODO: and no invalid chars!
		return format("%q", v)
	elseif type(v) == "table" then
		return table_tostring(v, ind, memo)
	else
		return tostring(v)
	end
end	

local function list_tostring(t, ind, ind1)
	-- try one-liner:
	local s = format("{ %s }", concat(t, ", "))
	if #s + #ind < 70 then
		return s
	else
		-- spill over lines:
		return format("{\n%s%s\n%s}", ind1, concat(t, format(",\n%s", ind1)), ind)
	end
end

local function dict_tostring(t, ind, memo)
	local ind1 = ind .. "  "
	local keys = dict_keylist(t)
	local res = {}
	for i, k in ipairs(keys) do
		res[#res+1] = format("%s = %s",
			dict_keystr(k, ind1),
			dict_valstr(t[k], ind1, memo)
		)
	end
	return list_tostring(res, ind, ind1)
end	

local function array_tostring(t, ind, memo)
	local ind1 = ind .. "  "
	local res = {}
	for i, v in ipairs(t) do
		res[i] = table_tostring(v, ind, memo)
	end
	return list_tostring(res, ind, ind1)
end	

table_tostring = function(t, ind, memo)
	ind = ind or ""
	-- memoization to trap multiple refs/recursion
	if memo then
		if memo[t] then 
			error("multiple references not supported") 
		end
	else
		memo = {}
	end
	memo[t] = true
	
	if type(t) == "table" then
		-- what kind of table is it?
		if next(t) then
			-- dict:
			return dict_tostring(t, ind, memo)
		else
			-- array:
			return array_tostring(t, ind, memo)
		end
	else
		return tostring(t)
	end	
end

util.table_tostring = table_tostring

return util