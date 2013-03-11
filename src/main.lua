-- this code gets baked into the av application
local args = ...

for i, v in ipairs{ args } do
	print(i, v)
end

-- add the modules search path:
package.path = './modules/?.lua;./modules/?/init.lua;'..package.path

-- load the modules we need:
local ffi = require "ffi"
local builtin = require "builtin"
local lua = require "lua"
	
-- a bit of helpful info:
print(string.format("using %s on %s (%s)", jit.version, jit.os, jit.arch))

local filename = "start.lua"

local watched = {}
local states = {}

function av_tick()
	-- filewatch:
	for filename, mtime in pairs(watched) do
		local t = ffi.C.av_filetime(filename)
		if t > mtime then
			print('canceling', filename)
			cancel(states[filename])
			
			print('spawning', filename)
			spawn(filename)
		end
	end
end

-- basic file spawning. 
-- this will allow us to scale up to filewatching and multiple states in the future

function spawn(filename)
	watched[filename] = ffi.C.av_filetime(filename)
	
	-- create a child Lua state to run user code in:
	L = lua.open()
	L:openlibs()
	states[filename] = L
	
	-- 'prime' this state with the module search path and built-in FFI header:
	L:dostring([[
		-- also search in /modules for Lua modules:
		package.path = './modules/?.lua;./modules/?/init.lua;'..package.path; 

		-- define the AV header in FFI:
		local builtin_header = ...
		local ffi = require 'ffi'
		ffi.cdef(builtin_header)

		-- initialize the window bindings:
		win = require "window"
		
		-- ready!
		print(string.rep("-", 80))
	]], builtin.header)

	L:dofile(filename)
	
	
	return L
end

function cancel(L)
	-- before calling L:close(), we need to unregister any application callbacks!
	ffi.C.av_state_reset(L)
	-- should be safe to shutdown now:
	L:close()
end

spawn(filename)