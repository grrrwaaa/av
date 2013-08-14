#!/usr/bin/env luajit
local av = require "av"
local ffi = require "ffi"
local gl = require "gl"
local field3D = require "field3D"
local field2D = require "field2D"
local shader = require "shader"
local vec2 = require "vec2"
local vec3 = require "vec3"
local vec4 = require "vec4"
local nav3 = require "nav3"
local mat4 = require "mat4"
local quat = require "quat"
local displaylist = require "displaylist"
local texture = require "texture"
local fbo = require "fbo"
local draw3D = require "draw3D"

local min = math.min
local sin, cos = math.sin, math.cos

local dim = 32
local f = field3D(dim, dim, dim)
f.border = 1
f:set(function(x, y, z)
	return math.random() < 0.1 and 1 or 0
end)
local f_old = f:copy()

function compute_distance(t)
	t = t or 0.5
	f, f_old = f_old, f
	
end

local g = field2D(16, 16)
local g_old = g:copy()

g:set(function(x, y)
	return math.random()
end)

local scalar = 0.1
local sqrt2 = math.sqrt(2)
local thresh = 0.1
function step(x, y)
	-- check my own previous state:
	local C  = g_old:get(x, y)
	
	if C > thresh then
		-- check out the distance measurements of neighbors:
		local N  = g_old:get(x  , y+1) + (scalar)
		local E  = g_old:get(x+1, y  ) + (scalar)
		local S  = g_old:get(x  , y-1) + (scalar)
		local W  = g_old:get(x-1, y  ) + (scalar)
	
		local NE = g_old:get(x+1, y+1) + (sqrt2 * scalar)
		local SE = g_old:get(x+1, y-1) + (sqrt2 * scalar)
		local SW = g_old:get(x-1, y-1) + (sqrt2 * scalar)
		local NW = g_old:get(x-1, y+1) + (sqrt2 * scalar)
	
		-- nearest:
		local d = min(N, E, S, W, NE, SE, NW, SW)
	else
		return C
	end
end

local glsl_math = [[
vec4 quat_fromeuler(float az, float el, float ba) {
	float c1 = cos(az * 0.5);
	float c2 = cos(el * 0.5);
	float c3 = cos(ba * 0.5);
	float s1 = sin(az * 0.5);
	float s2 = sin(el * 0.5);
	float s3 = sin(ba * 0.5);
	// equiv Q1 = Qy * Qx; -- since many terms are zero
	float tw = c1*c2;
	float tx = c1*s2;
	float ty = s1*c2;
	float tz =-s1*s2;
	// equiv Q2 = Q1 * Qz; -- since many terms are zero
	return vec4(
		tx*c3 + ty*s3,
		ty*c3 - tx*s3,
		tw*s3 + tz*c3,
		tw*c3 - tz*s3
	);
}

//	q must be a normalized quaternion
vec3 quat_rotate(vec4 q, vec3 v) {
	vec4 p = vec4(
		q.w*v.x + q.y*v.z - q.z*v.y,	// x
		q.w*v.y + q.z*v.x - q.x*v.z,	// y
		q.w*v.z + q.x*v.y - q.y*v.x,	// z
		-q.x*v.x - q.y*v.y - q.z*v.z	// w
	);
	return vec3(
		p.x*q.w - p.w*q.x + p.z*q.y - p.y*q.z,	// x
		p.y*q.w - p.w*q.y + p.x*q.z - p.z*q.x,	// y
		p.z*q.w - p.w*q.z + p.y*q.x - p.x*q.y	// z
	);
}
]]

local vs = glsl_math .. [[

varying vec2 P;
void main() {
	P = gl_MultiTexCoord0.xy * 2. - 1.;
	gl_Position = vec4(P, 0., 1.);
}
]]
local fs = glsl_math .. [[
uniform float now;
varying vec2 P;

float scene(vec3 p) {
	vec3 c = vec3(5., 4., 3. + 0.1*cos(p.y));
	vec3 pr1 = mod(p,c)-0.5*c;
	//pr1 = quat_rotate(quat_fromeuler(sin(now + 3.*p.x), cos(now * 2.), sin(p.z)), pr1);
	vec3 box = vec3(0.4, 0.1, 0.8);
	return length(max(abs(pr1)-box, 0.0));
}

vec3 spherical(float az, float el) {
	float sy = sin(az);
	float cy = cos(az);
	float sx = sin(el);
	float cx = cos(el);
	return vec3(
		cy * cx,
		sy,
		cy * sx
	);
}

float eps = 0.01;
vec3 epsx = vec3(eps,0,0);
vec3 epsy = vec3(0,eps,0);
vec3 epsz = vec3(0,0,eps);

vec3 light1 = vec3(1, 2, 3);
vec3 light2 = vec3(2, -3, 1);
vec3 color1 = vec3(0.3, 0.7, 0.6);
vec3 color2 = vec3(0.6, 0.2, 0.8);
vec3 ambient = vec3(0.1, 0.1, 0.1);

void main() {

	// the ray origin:
	vec3 ro = vec3(0.);
	// the ray direction:
	vec3 rd = spherical(P.x, P.y);
	
	float near = 0.01;
	float far = 50.;
	float t = near;
	vec3 p = ro + rd * t;
	
	float d = scene(p);
	
	#define MAX_STEPS 50
	for (int i=0; i<MAX_STEPS; i++) {
		t += d;
		p = ro + rd * t;
		d = scene(p);
		if (d < near || t > far) { break; }
	}
	
	vec3 color = vec3(0, 0, 0) * now;

	if (t<far) {
			vec3 gradient = vec3( 
				scene(p+epsx) - scene(p-epsx),
				scene(p+epsy) - scene(p-epsy),
				scene(p+epsz) - scene(p-epsz)  
			);
			vec3 normal = normalize(gradient);
			vec3 ldir1 = normalize(light1 - p);
			vec3 ldir2 = normalize(light2 - p);
			color = ambient
					//+ color1 * max(0.,dot(ldir1, normal))  
					//+ color2 * max(0.,dot(ldir2, normal)) 
					+ color1 * abs(dot(ldir1, normal))  
					+ color2 * abs(dot(ldir2, normal)) 
					;
			float tnorm = t/far;
			color *= 1. - tnorm*tnorm;
		}

	gl_FragColor = vec4(color, 1.);
}
]]
local vshader = shader(vs, fs)

function draw()
	---[[
	gl.Clear()
	local s = vshader
	s:bind()
	s:uniform("now", now())
	gl.Begin(gl.QUADS)
	gl.TexCoord2f(0, 0) 	gl.Vertex3f(0, 0, 0)
	gl.TexCoord2f(1, 0)		gl.Vertex3f(1, 0, 0)
	gl.TexCoord2f(1, 1)		gl.Vertex3f(1, 1, 0)
	gl.TexCoord2f(0, 1)		gl.Vertex3f(0, 1, 0)
	gl.End()
	s:unbind()
	--]]
	g, g_old = g_old, g
	g:set(step)
	
	--g:draw()
end

local vs = glsl_math .. [[

varying vec4 V, E;
varying vec3 T;
void main() {
	T = gl_MultiTexCoord0.xyz;
	V = gl_Vertex;
	E = gl_ModelViewMatrix * V;
	gl_Position = gl_ProjectionMatrix * E;
	gl_Position.z = 0.;
}
]]
local fs = glsl_math .. [[
uniform float now;
uniform sampler3D tex;
uniform vec3 eye;
varying vec4 V, E;
varying vec3 T;

vec3 spherical(float az, float el) {
	float sy = sin(az);
	float cy = cos(az);
	float sx = sin(el);
	float cx = cos(el);
	return vec3(
		cy * cx,
		sy,
		cy * sx
	);
}

float eps = 0.01;
vec3 epsx = vec3(eps,0,0);
vec3 epsy = vec3(0,eps,0);
vec3 epsz = vec3(0,0,eps);

vec3 light1 = vec3(1, 2, 3);
vec3 light2 = vec3(2, -3, 1);
vec3 color1 = vec3(0.3, 0.7, 0.6);
vec3 color2 = vec3(0.6, 0.2, 0.8);
vec3 ambient = vec3(0.1, 0.1, 0.1);

void main() {

	vec3 ro = T;
	vec3 rd = normalize(V.xyz - eye);
	
	float near = 0.1;
	float far = 2.;
	
	float t = near;
	float step = 0.01;
	
	float c = 0.;
	float amp = step;
	vec3 p = ro + t * rd;
	
	for (;t < far;) {
		// get density at current point
		float v = texture3D(tex, p).r * amp;
		
		// is next point out of range?
		float t1 = t + step;
		vec3 p1 = ro + t1 * rd;
		if (p1.x < 0. || p1.x > 1. || p1.y < 0. || p1.y > 1. || p1.z < 0. || p1.z > 1.) {
			// accumulate only a portion of it
			float a = 0.5;
			
			c += v*0.5;
			break;
		} 
		
		// accumulate color
		c += v;
		// move to next point
		p = p1;
		t = t1;
	}
	
	vec3 color = vec3(c);

	gl_FragColor = vec4(color, 1.);
}
]]
local vshader = shader(vs, fs)

local at  = vec3(0, 0, 0)
local up  = vec3(0, 1, 0)

f:set(function()
	return math.random()
end)

local once = true

function draw()
	gl.Clear()
	gl.Enable(gl.CULL_FACE)
	gl.CullFace(gl.BACK)
	-- go 3D:
	local near, far = 0.1, 100
	local fovy, aspect = 80, 1.2
	local a = t * 1
	local eye = vec3(cos(a), 0, sin(a)) * 1.25
	
	gl.MatrixMode(gl.PROJECTION)
	gl.LoadMatrix(mat4.perspective(fovy, aspect, near, far))
	gl.MatrixMode(gl.MODELVIEW)
	gl.LoadMatrix(mat4.lookat(eye, at, up))
	
	f:bind(0)	
	gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_BORDER)
	gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_BORDER)
	gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_R, gl.CLAMP_TO_BORDER)
	local color = ffi.new("float[4]")
	gl.TexParameterfv(gl.TEXTURE_3D, gl.TEXTURE_BORDER_COLOR, color)
	local s = vshader
	s:bind()
	
	s:uniform("eye", eye.x, eye.y, eye.z)
	-- draw a cube.
	draw3D.cube()
	s:unbind()
	f:unbind(0)
	
	if once then gl.extensions() once = nil end
	
end

av.run()