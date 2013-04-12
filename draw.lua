local gl = require "gl"
local field2D = require "field2D"

-- allocate a 2D array:
local field = field2D()

-- how to render the scene (toggle fullscreen with the Esc key):
function draw(w, h)	
	-- draw the field:
	field:draw()
end

-- handle keypress events:
function keydown(k)
	if k == "c" then
		field:clear()
	end
end

-- handle mouse events:
function mouse(e, btn, x, y)
	if e == "down" or e == "drag" then
		field:set(1, x * field.width, y * field.height)
	end
end

-- continual processing:
function update()
	field:set(function(x, y)
		return field:get(x, y) * 0.995
	end)
end
