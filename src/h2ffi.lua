#!/usr/bin/luajit

local args = {...}
local input = assert(args[1], "specify file to parse")
local output = assert(args[2], "output name required")

local r = {
	string.format("-- generated from %s on %s", input, os.date()),
	string.format("print('Binary built on %s')", os.date()),
	"local header = [[",
}

local h = io.popen(string.format("gcc -E -P %s", input))
for l in h:lines() do
	local s = l:gsub("(#[^\n]+)", "")
	if #s > 0 then
		r[#r+1] = s
	end
end

r[#r+1] = "]]"
r[#r+1] = "local ffi = require 'ffi'"
r[#r+1] = "ffi.cdef(header)"
r[#r+1] = "return header"

local c = {}
c[#c+1] = string.format('const char * %s = ""', output)
for i, line in ipairs(r) do
	c[#c+1] = string.format('"%s \\n"', line)
end
c[#c] = c[#c]..";"


c[#c+1] = 'const char * av_main = ""'
local h = io.open("main.lua")
for line in h:lines() do
	c[#c+1] = string.format('"%s \\n"', line:gsub('\"', '\\"'))
end
c[#c] = c[#c]..";"

local ccode = table.concat(c, "\n")
io.open(output .. ".cpp", "w"):write(ccode)