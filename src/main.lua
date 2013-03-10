-- this code should be 'baked in' to the app?
package.path = './modules/?.lua;./modules/?/init.lua;'..package.path
print("using", jit.version)

-- basic file spawning. 
-- this will allow us to scale up to filewatching and multiple states in the future

function spawn(filename)
	-- create a child Lua state to run user code in:
	local lua = require "lua"
	L = lua.open()
	L:openlibs()
	-- 'prime' this state with the module search path and built-in FFI header:
	local builtin = require "builtin"
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
	local ffi = require "ffi"
	ffi.C.av_state_reset(L)
	-- should be safe to shutdown now:
	L:close()
end

spawn("first.lua")