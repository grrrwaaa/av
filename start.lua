

-- dofile("test.lua")


-- set up a new state to run examples:

-- FFI binding to Lua API in order to create new states:
local lua = require "lua"
local ffi = require "ffi"
local builtin = require "builtin"

function spawn(filename)

	L = lua.open()
	L:openlibs()
	L:dostring([[

		package.path = './modules/?.lua;./modules/?/init.lua;'..package.path; 

		local builtin_header = ...
		local ffi = require 'ffi'
		ffi.cdef(builtin_header)
		
		print(string.rep("-", 80))

	]], builtin.header)

	L:dofile("test.lua")
	
	return L
end

function cancel(L)
	-- before calling L:close(), we need to unregister any application callbacks!
	ffi.C.av_state_reset(L)
	-- should be safe to shutdown now:
	L:close()
end

spawn("test.lua")
