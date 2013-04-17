--- draw3D: utilities for 3D OpenGL

local gl = require "gl"
local sketch = gl.sketch

local draw3D = {}

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


-- primitives center at 0, 0, 0
-- and have radius 1
function draw3D.cube()
	-- TODO: cache this in a displaylist or static buffer
	gl.Begin(gl.QUADS)
		-- +x
		gl.Normal(1, 0, 0)
		gl.Vertex(1, -1, 1)
		gl.Normal(1, 0, 0)
		gl.Vertex(1, -1, -1)
		gl.Normal(1, 0, 0)
		gl.Vertex(1, 1, -1)
		gl.Normal(1, 0, 0)
		gl.Vertex(1, 1, 1)
		-- -x
		gl.Normal(-1, 0, 0)
		gl.Vertex(-1, -1, -1)
		gl.Normal(-1, 0, 0)
		gl.Vertex(-1, -1, 1)
		gl.Normal(-1, 0, 0)
		gl.Vertex(-1, 1, 1)
		gl.Normal(-1, 0, 0)
		gl.Vertex(-1, 1, -1)
		-- +y
		gl.Normal(0, 1, 0)
		gl.Vertex(-1, 1, 1)
		gl.Normal(0, 1, 0)
		gl.Vertex(1, 1, 1)
		gl.Normal(0, 1, 0)
		gl.Vertex(1, 1, -1)
		gl.Normal(0, 1, 0)
		gl.Vertex(-1, 1, -1)
		-- -y
		gl.Normal(0, -1, 0)
		gl.Vertex(1, -1, 1)
		gl.Normal(0, -1, 0)
		gl.Vertex(-1, -1, 1)
		gl.Normal(0, -1, 0)
		gl.Vertex(-1, -1, -1)
		gl.Normal(0, -1, 0)
		gl.Vertex(1, -1, -1)
		-- +z
		gl.Normal(0, 0, 1)
		gl.Vertex(-1, -1, 1)
		gl.Normal(0, 0, 1)
		gl.Vertex(1, -1, 1)
		gl.Normal(0, 0, 1)
		gl.Vertex(1, 1, 1)
		gl.Normal(0, 0, 1)
		gl.Vertex(-1, 1, 1)
		-- -z
		gl.Normal(0, 0, -1)
		gl.Vertex(1, -1, -1)
		gl.Normal(0, 0, -1)
		gl.Vertex(-1, -1, -1)
		gl.Normal(0, 0, -1)
		gl.Vertex(-1, 1, -1)
		gl.Normal(0, 0, -1)
		gl.Vertex(1, 1, -1)
	gl.End()
end	


return draw3D