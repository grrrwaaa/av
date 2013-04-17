-- A collection of highly re-usable Lua utilities
local util = {}

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

return util