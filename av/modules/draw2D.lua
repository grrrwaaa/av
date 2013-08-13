--- Draw2D: simple drawing primitives for 2D graphics

local gl = require "gl"
local GL = gl
local pi = math.pi
local twopi = pi * 2
local halfpi = pi/2
local rad2deg = 180/pi
local sin, cos = math.sin, math.cos

local draw2D = {}

--- Store the current transformation until the next pop()
-- Caches the current transform matrix into the matrix stack, and pushes a new copy of the matrix onto the top.
-- Note that the stack is limited in size (typically 32 items). 
function draw2D.push() 
	gl.PushMatrix()
end

--- Restore the transformation from the previous push()
-- Discards the current transformation matrix and restores the previous matrix from the matrix stack.
function draw2D.pop() 
	gl.PopMatrix()
end

--- Move the coordinate system origin to x, y 
-- (modifies the transformation matrix)
-- @param x coordinate of new origin
-- @param y coordinate of new origin
function draw2D.translate(x, y)
	gl.Translate(x, y, 0)
end

--- Scale the coordinate system
-- (modifies the transformation matrix)
-- @param x horizontal factor
-- @param y vertical factor
function draw2D.scale(x, y)
	gl.Scale(x, y or x, 1)
end

--- Rotate the coordinate system around the origin
-- (modifies the transformation matrix)
-- @param a the angle (in radians) to rotate
function draw2D.rotate(a)
	gl.Rotate(a * rad2deg, 0, 0, 1)
end

--- Draw a point at position x,y
-- @param x coordinate of center (optional, defaults to 0)
-- @param y coordinate of center (optional, defaults to 0)
function draw2D.point(x, y)	
	x = x or 0
	y = y or 0
	gl.Begin(GL.POINTS)
		gl.Vertex2d(x, y)
	gl.End()
end

--- Draw a line from x1,y1 to x2,y2
-- @param x1 start coordinate
-- @param y1 start coordinate
-- @param x2 end coordinate (optional, defaults to 0)
-- @param y2 end coordinate (optional, defaults to 0)
function draw2D.line(x1, y1, x2, y2)	
	x2 = x2 or 0
	y2 = y2 or 0
	gl.Begin(GL.LINES)
		gl.Vertex2d(x1, y1)
		gl.Vertex2d(x2, y2)
	gl.End()
end

--- Draw a rectangle at the point (x, y) with width w and height h
-- @param x coordinate of center (optional, defaults to 0)
-- @param y coordinate of center (optional, defaults to 0)
-- @param w width (optional, defaults to 1)
-- @param h height (optional, defaults to 1)
function draw2D.rect(x, y, w, h)
	x = x or 0
	y = y or 0
	w = w or 1
	h = h or w
	local w2 = w/2
	local h2 = h/2
	local x1 = x - w2
	local y1 = y - h2
	local x2 = x + w2
	local y2 = y + h2
	gl.Begin(GL.QUADS)
		gl.Vertex2d(x1, y1)
		gl.Vertex2d(x2, y1)
		gl.Vertex2d(x2, y2)
		gl.Vertex2d(x1, y2)
	gl.End()
end

--- Draw an ellipse at the point (x, y) with horizontal diameter w and vertical diameter h
-- @param x coordinate of center (optional, defaults to 0)
-- @param y coordinate of center (optional, defaults to 0)
-- @param w horizontal diameter (optional, defaults to 1)
-- @param h vertical diameter (optional, defaults to w)
function draw2D.ellipse(x, y, w, h)
	x = x or 0
	y = y or 0
	w = w and w/2 or 0.5
	h = h and h/2 or w
	gl.Begin(GL.TRIANGLE_FAN)
	for a = 0, twopi, 0.0436 do
		gl.Vertex2d(
			x + w * cos(a), 
			y + h * sin(a)
		)
	end
	gl.End()
end

--- Draw an ellipse at the point (x, y) with horizontal diameter d
-- @param x coordinate of center (optional, defaults to 0)
-- @param y coordinate of center (optional, defaults to 0)
-- @param d diameter (optional, defaults to 1)
function draw2D.circle(x, y, d)
	x = x or 0
	y = y or 0
	local r = d and d/2 or 0.5
	gl.Begin(GL.TRIANGLE_FAN)
	for a = 0, twopi, 0.0436 do
		gl.Vertex2d(x + r * cos(a), y + r * sin(a))
	end
	gl.End()
end

--- Draw an arc at the point (x, y) with horizontal diameter d
-- @param x coordinate of center (optional, defaults to 0)
-- @param y coordinate of center (optional, defaults to 0)
-- @param s start angle (optional, defaults to -pi/2)
-- @param e end angle (optional, defaults to pi/2)
-- @param w horizontal radius (optional, defaults to 1)
-- @param h vertical radius (optional, defaults to w)
function draw2D.arc(x, y, s, e, w, h)
	x = x or 0
	y = y or 0
	s = s or -halfpi
	e = e or halfpi
	w = w and w or 1
	h = h and h or w
	gl.Begin(GL.TRIANGLE_FAN)
	gl.Vertex2d(0, 0)
	for a = s, e, 0.0436 do
		gl.Vertex2d(
			x + w * cos(a), 
			y + h * sin(a)
		)
	end
	gl.End()
end

--- Set the rendering color
-- @param red value from 0 to 1 (optional, default 0)
-- @param green value from 0 to 1 (optional, default 0)
-- @param blue value from 0 to 1 (optional, default 0)
-- @param alpha (opacity) value from 0 to 1 (optional, default 1)
function draw2D.color(red, green, blue, alpha) end
draw2D.color = gl.Color

return draw2D