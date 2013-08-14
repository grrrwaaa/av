--- draw3D: utilities for 3D OpenGL

local mat4 = require "mat4"
local gl = require "gl"
local displaylist = require "displaylist"
local sketch = gl.sketch

local rad2deg = 180 / math.pi
local pi = math.pi
local twopi = pi * 2
local sin, cos = math.sin, math.cos

local draw3D = {}

--- Store the current transformation until the next pop()
-- Caches the current transform matrix into the matrix stack, and pushes a new copy of the matrix onto the top.
-- Note that the stack is limited in size (typically 32 items). 
function draw3D.push() 
	gl.PushMatrix()
end

--- Restore the transformation from the previous push()
-- Discards the current transformation matrix and restores the previous matrix from the matrix stack.
function draw3D.pop() 
	gl.PopMatrix()
end

--- Move the coordinate system origin to x, y 
-- (modifies the transformation matrix)
-- @param x coordinate of new origin
-- @param y coordinate of new origin
function draw3D.translate(x, y, z)
	gl.Translate(x, y, z)
end

--- Scale the coordinate system
-- (modifies the transformation matrix)
-- @param x horizontal factor
-- @param y vertical factor
function draw3D.scale(x, y, z)
	gl.Scale(x, y or x, z or 1)
end

--- Rotate the coordinate system around the origin
-- (modifies the transformation matrix)
-- @param a the angle (in radians) to rotate
-- @param axis the axis (vec3) to rotate around
function draw3D.rotate(a, axis)
	gl.Rotate(a * rad2deg, axis.x, axis.y, axis.z)
end

draw3D.glsl_include = [[

float pi = 3.141592653589793;

float M_1_PI = 0.31830988618379;
float M_PI = 3.14159265358979;
float M_2PI = 6.283185307179586;
float M_PI_2 = 1.5707963267948966;
float M_DEG2RAD = 0.017453292519943;

// create lookat matrix:
mat4 lookat1(in vec3 ux, in vec3 uy, in vec3 uz, in vec3 eye) {
	return mat4(
		ux.x, uy.x, uz.x, 0.,
		ux.y, uy.y, uz.y, 0.,
		ux.z, uy.z, uz.z, 0.,
		-dot(ux,eye), -dot(uy,eye), -dot(uz,eye), 1.
	);
}

mat4 lookat(in vec3 eye, in vec3 at, in vec3 up) {
	vec3 uz = normalize(eye-at);	
	vec3 uy = normalize(up);
	vec3 ux = normalize(cross(uz, up));
	return lookat1(ux, uy, uz, eye);
}

// create GLSL projection matrix:
mat4 perspective(in float fovy, in float aspect, in float near, in float far) {
	float f = 1./tan(fovy*M_DEG2RAD/2.);
	return mat4(
		f/aspect,	0., 0.,						0.,
		0.,			f,	0.,						0.,
		0.,			0., (far+near)/(near-far),	-1.,
		0.,			0., (2.*far*near)/(near-far),0.
	);
}

]]

function draw3D.enter()
	-- projection
	
	-- modelview
end

local stacks = 22
local slices = 22
local sphere = displaylist(function()
	local stackstep = pi / stacks
    local slicestep = twopi / slices
    for lat = 0, pi, stackstep do
    	gl.Begin(gl.QUAD_STRIP)
    	for lon = 0, twopi, slicestep do
    		local x, y, z
    		x = cos(lat) * sin(lon)
    		y = sin(lat) * sin(lon)
    		z = cos(lon)
    		gl.Normal(x, y, z)
    		gl.Vertex(x, y, z)  		
    		x = cos(lat + stackstep) * sin(lon)
    		y = sin(lat + stackstep) * sin(lon)
    		z = cos(lon)
    		gl.Normal(x, y, z)
    		gl.Vertex(x, y, z)
    	end
    	gl.End()
    end
end)

function draw3D.sphere()
	sphere:draw()
end

-- primitives center at 0, 0, 0
-- and have radius 1
local cube = displaylist(function()
	-- TODO: cache this in a displaylist or static buffer
	gl.Begin(gl.QUADS)
		-- +x
		gl.Normal(1, 0, 0)
		gl.TexCoord(1, 0, 1)
		gl.Vertex(1, -1, 1)
		
		gl.Normal(1, 0, 0)
		gl.TexCoord(1, 0, 0)
		gl.Vertex(1, -1, -1)
		
		gl.Normal(1, 0, 0)
		gl.TexCoord(1, 1, 0)
		gl.Vertex(1, 1, -1)
		
		gl.Normal(1, 0, 0)
		gl.TexCoord(1, 1, 1)
		gl.Vertex(1, 1, 1)
		-- -x
		gl.Normal(-1, 0, 0)
		gl.TexCoord(0, 0, 0)
		gl.Vertex(-1, -1, -1)
		
		gl.Normal(-1, 0, 0)
		gl.TexCoord(0, 0, 1)
		gl.Vertex(-1, -1, 1)
		
		gl.Normal(-1, 0, 0)
		gl.TexCoord(0, 1, 1)
		gl.Vertex(-1, 1, 1)
		
		gl.Normal(-1, 0, 0)
		gl.TexCoord(0, 1, 0)
		gl.Vertex(-1, 1, -1)
		-- +y
		gl.Normal(0, 1, 0)
		gl.TexCoord(0, 1, 1)
		gl.Vertex(-1, 1, 1)
		
		gl.Normal(0, 1, 0)
		gl.TexCoord(1, 1, 1)
		gl.Vertex(1, 1, 1)
		
		gl.Normal(0, 1, 0)
		gl.TexCoord(1, 1, 0)
		gl.Vertex(1, 1, -1)
		
		gl.Normal(0, 1, 0)
		gl.TexCoord(0, 1, 0)
		gl.Vertex(-1, 1, -1)
		-- -y
		gl.Normal(0, -1, 0)
		gl.TexCoord(1, 0, 1)
		gl.Vertex(1, -1, 1)
		
		gl.Normal(0, -1, 0)
		gl.TexCoord(0, 0, 1)
		gl.Vertex(-1, -1, 1)
		
		gl.Normal(0, -1, 0)
		gl.TexCoord(0, 0, 0)
		gl.Vertex(-1, -1, -1)
		
		gl.Normal(0, -1, 0)
		gl.TexCoord(1, 0, 0)
		gl.Vertex(1, -1, -1)
		-- +z
		gl.Normal(0, 0, 1)
		gl.TexCoord(0, 0, 1)
		gl.Vertex(-1, -1, 1)
		
		gl.Normal(0, 0, 1)
		gl.TexCoord(1, 0, 1)
		gl.Vertex(1, -1, 1)
		
		gl.Normal(0, 0, 1)
		gl.TexCoord(1, 1, 1)
		gl.Vertex(1, 1, 1)
		
		gl.Normal(0, 0, 1)
		gl.TexCoord(0, 1, 1)
		gl.Vertex(-1, 1, 1)
		-- -z
		gl.Normal(0, 0, -1)
		gl.TexCoord(1, 0, 0)
		gl.Vertex(1, -1, -1)
		
		gl.Normal(0, 0, -1)
		gl.TexCoord(0, 0, 0)
		gl.Vertex(-1, -1, -1)
		
		gl.Normal(0, 0, -1)
		gl.TexCoord(0, 1, 0)
		gl.Vertex(-1, 1, -1)

		gl.Normal(0, 0, -1)
		gl.TexCoord(1, 1, 0)
		gl.Vertex(1, 1, -1)
	gl.End()
end)

function draw3D.cube()
	cube:draw()
end


--- Set the rendering color
-- @param red value from 0 to 1 (optional, default 0)
-- @param green value from 0 to 1 (optional, default 0)
-- @param blue value from 0 to 1 (optional, default 0)
-- @param alpha (opacity) value from 0 to 1 (optional, default 1)
function draw3D.color(red, green, blue, alpha) end
draw3D.color = gl.Color

return draw3D