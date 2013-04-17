--- displaylist: A friendly wrapper for OpenGL display lists

local gl = require "gl"

local displaylist = {}
displaylist.__index = displaylist

local function new(ctor)
	return setmetatable({
		ctor = ctor,
		id = nil
	}, displaylist)
end

function displaylist:destroy()
	gl.DeleteLists(self.id, 1)
	self.id = nil
end

function displaylist:draw()
	if not self.id then
		local id = gl.GenLists(1)
		gl.NewList(id, gl.COMPILE)
		self.ctor()
		gl.EndList()
		gl.assert("displaylist")
		self.id = id
	end
	gl.CallList(self.id)
end
displaylist.__call = displaylist.draw

setmetatable(displaylist, {
	__call = function(t, f)
		return new(f)
	end
})

return displaylist