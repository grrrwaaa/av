-- main.lua

local exepath = select(1, ...) or "."
local filename = select(2, ...) or "start.lua"
local args = { select(3, ...) }

local startupscript = [[
	local exepath, builtin_header = ...
	_G.exepath = exepath
	
	-- also search in /modules for Lua modules:
	package.path = string.format('%s/modules/?.lua;%s/modules/?/init.lua;%s', exepath, exepath, package.path); 

	-- define the AV header in FFI:
	local ffi = require 'ffi'
	ffi.cdef(builtin_header)
	package.loaded.builtin = builtin_header
	
	-- initialize the window bindings:
	win = require "window"	
]]

-- load the modules we need:
local ffi = require "ffi"
local C = ffi.C
local builtin = require "builtin"

-- also search in /modules for Lua modules:
package.path = string.format('%s/modules/?.lua;%s/modules/?/init.lua;%s', exepath, exepath, package.path); 
local lua = require "lua"

-- a bit of helpful info:
print(string.format("Using %s on %s (%s)", jit.version, jit.os, jit.arch))

local watched = {}
local states = {}

function av_tick()
	-- filewatch:
	for filename, mtime in pairs(watched) do
		local t = C.av_filetime(filename)
		if t > mtime then
			watched[filename] = t
			spawn(filename)
		end
	end
end

-- basic file spawning. 
-- this will allow us to scale up to filewatching and multiple states in the future

function spawn(filename)
	if states[filename] then		
		cancel(states[filename])
	end
	
	print(string.rep("-", 80))
	-- create a child Lua state to run user code in:
	L = lua.open()
	L:openlibs()
	
	-- preload lpeg:
	L:getglobal("package")
	L:getfield(-1, "preload")
	L:pushcfunction(C.luaopen_lpeg)
	L:setfield(-2, "lpeg")
	L:pushcfunction(C.luaopen_http_parser)
	L:setfield(-2, "http.parser")
	L:settop(0)
	
	states[filename] = L
	
	-- 'prime' this state with the module search path and built-in FFI header:
	L:dostring(startupscript, exepath, builtin.header)
	---[[
	
	print(string.format("running %s at %s", filename, os.date()))
	print(string.rep("-", 80))

	L:dofile(filename, unpack(args))
	
	return L
	--]]
end

function cancel(L)
	if L then
		print('canceling', filename)
		-- before calling L:close(), we need to unregister any application callbacks!
		C.av_state_reset(L)
		-- should be safe to shutdown now:
		L:close()
		print(string.rep("-", 80))
	end
end

function watch(filename)
	watched[filename] = 0
end

watch(filename)

