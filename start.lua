

--dofile("test.lua")


-- set up a new state to run examples:

-- FFI binding to Lua API in order to create new states:
local lua = require "lua"


local L = lua.open()
L:openlibs()
print(L)
