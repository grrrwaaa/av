-- this code gets baked into the av application

-- add the modules search path:
package.path = './modules/?.lua;./modules/?/init.lua;'..package.path

-- load the modules we need:
local ffi = require "ffi"
local builtin = require "builtin"
local lua = require "lua"
	
-- a bit of helpful info:
print(string.format("using %s on %s (%s)", jit.version, jit.os, jit.arch))

-- basic file spawning. 
-- this will allow us to scale up to filewatching and multiple states in the future

function spawn(filename)
	-- create a child Lua state to run user code in:
	L = lua.open()
	L:openlibs()
	-- 'prime' this state with the module search path and built-in FFI header:
	L:dostring([[

		package.path = './modules/?.lua;./modules/?/init.lua;'..package.path; 

		local builtin_header = ...
		local ffi = require 'ffi'
		ffi.cdef(builtin_header)
		
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

spawn("start.lua")