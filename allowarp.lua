#!/usr/bin/env luajit
local av = require "av"
local ffi = require "ffi"
local C = ffi.C

local vec2 = require "vec2"
local vec3 = require "vec3"
local vec4 = require "vec4"
local mat4 = require "mat4"
local quat = require "quat"

local field3D = require "field3D"

local gl = require "gl"
local texture = require "texture"
local sin, cos = math.sin, math.cos
local pi, twopi = math.pi, math.pi * 2

local dim = 32
local voxels = field3D(dim, dim, dim)
voxels:set(function(x, y, z)
	return (x > z and 0 or 1) + 0.1 * (math.random() - 0.5)
end)

ffi.cdef[[
int open(const char * path, int code);
int close(int fd);
int read(int fd, void * dst, size_t sz);
]]

local function standard_warp()
	local p = {
		viewport = { l=0, b=0, w=1, h=1 },
		blend = nil,
		params = nil,
	}
	local w, h = 512, 512
	local elems = w*h
	local data = ffi.new("vec4f[?]", elems)
	for y = 0, h-1 do
		for x = 0, w-1 do
			local nx, ny = x/(w-1), y/(h-1)
			local idx = x + y*w
			local cy = cos(pi * ny)
			data[idx]:set(
				cy * sin(twopi * nx),
				sin(pi * ny),
				cy * cos(twopi * nx),
				0
			)
		end
	end
	p.width = w
	p.height = h
	p.aspect = w/h
	p.elems = elems
	p.map3D = data
	
	-- wrap map3D as a texture:			
	p.map3Dtex = texture(p.width, p.height)
	p.map3Dtex.internalformat = gl.RGB32F_ARB
	p.map3Dtex.type = gl.FLOAT
	p.map3Dtex.format = gl.RGBA
	p.map3Dtex.data = ffi.cast("float *", p.map3D)
	return p
end

local allo = {
	hostname = io.popen("hostname"):read("*l"),
	
	-- all the machines loaded so far:
	-- (each machine is a list of projections)
	machines = {},
	-- the current machine:
	current = {
		fullscreen = false,
		active = false,
		resolution = 1024,
		
		standard_warp(),
	},
}
-- temporary override:
--allo.hostname = "gr04"

print("I am", allo.hostname)

local datapath, blobpath
if ffi.os == "OSX" then
	datapath = "/Users/grahamwakefield/calibration-current/"
	blobpath = "/Users/grahamwakefield/calibration-data/"
else
	datapath = "/home/sphere/calibration-current/"
	blobpath = "/alloshare/calibration/data/"
end

function load_calibration(hostname)
	local filename = string.format("%s%s.lua", datapath, hostname)
	print("loading", filename)
	local ok, err = pcall(dofile, filename)
	if not ok then print(err) else
		allo.machines[hostname] = projections
		projections.hostname = hostname

		for i, p in ipairs(projections) do
			local filename = datapath .. p.warp.file
			print("reading", filename)
			local f = C.open(filename, 0)
			assert(f ~= -1, filename)	
			local dim = ffi.new("int32_t[2]")
			C.read(f, dim, ffi.sizeof(dim))
			local w = dim[1]
			local h = dim[0] / 3
			local elems = w*h	
			print(string.format("%s x %s pixels (%s total)", w, h, elems))
			local t = ffi.new("float[?]", elems)
			local u = ffi.new("float[?]", elems)
			local v = ffi.new("float[?]", elems)
			C.read(f, t, ffi.sizeof(t))
			C.read(f, u, ffi.sizeof(u))
			C.read(f, v, ffi.sizeof(v))	
			local data = ffi.new("vec4f[?]", elems)
			for y = 0, h-1 do
				for x = 0, w-1 do
					local idx = y*w + x
					local v = vec3(t[idx], u[idx], v[idx])
			
					-- now fit it:
					--if options.import_use_fitting then
					--	v = allosphere:capsuleFitting(v) 
					--end
			
					data[idx].x = v.x
					data[idx].y = v.y
					data[idx].z = v.z
			
				end
			end
			C.close(f)
	
			-- p already has p.viewport (l, b, w, h)
			p.width = w
			p.height = h
			p.aspect = w/h
			p.elems = elems
			p.map3D = data
			
			-- wrap map3D as a texture:			
			p.map3Dtex = texture(p.width, p.height)
			p.map3Dtex.internalformat = gl.RGB32F_ARB
			p.map3Dtex.type = gl.FLOAT
			p.map3Dtex.format = gl.RGBA
			p.map3Dtex.data = ffi.cast("float *", p.map3D)
			
			-- TODO
			-- p.blend.file
			-- p.params.file
		end
		allo.current = projections
	end
end

load_calibration(allo.hostname)

local shader = require "shader"
local window = require "window"

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

varying vec2 T;
varying mat4 mv;
void main() {
	T = gl_MultiTexCoord0.xy;
	gl_Position = vec4(T.x*2.-1., 1.-T.y*2., 0., 1.);
	//gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
	
	mv = gl_ModelViewMatrix;
}
]]
local fs = glsl_math .. [[
uniform sampler2D map3D;
uniform sampler3D voxels;
uniform vec3 eye;
uniform float parallax;
uniform float now;
varying vec2 T;
varying mat4 mv;

float scene(vec3 p) {
	/*
	vec3 c = vec3(5., 4., 3. + 0.1*cos(p.y));
	vec3 pr1 = mod(p,c)-0.5*c;
	//pr1 = quat_rotate(quat_fromeuler(sin(now + 3.*p.x), cos(now * 2.), sin(p.z)), pr1);
	vec3 box = vec3(0.4, 0.1, 0.8);
	return length(max(abs(pr1)-box, 0.0));
	*/
	return texture3D(voxels, p).x;
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

// in eye space, never changes!
vec3 up = vec3(0., 1., 0.);

void main() {
	// the ray origin:
	vec3 ro = (mv * vec4(0., 0., 0, 1.)).xyz;
	
	vec3 raw_rd = (texture2D(map3D, T).xyz);
	// rotate by view:
	vec3 rd = normalize((mv * vec4(raw_rd, 1.)).xyz - ro);
	
	// stereo shift:
	vec3 rdx = cross(normalize(rd), up);
	ro += rdx * parallax;
	
	float near = 0.1;
	float step = 0.1;
	float far = 50.;
	float t = near;
	float c = 0.;
	float amp = step * 10.;
	
	vec3 p = ro + rd * t;
	
	float d = scene(p);
	
	/*
	#define MAX_STEPS 50
	for (int i=0; i<MAX_STEPS; i++) {
		t += d;
		p = ro + rd * t;
		d = scene(p);
		if (d < near || t > far) { break; }
	}
	vec3 color = vec3(0, 0, 0);
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
	*/
	
	
	for (;t < far;) {
		// get density at current point
		float v = texture3D(voxels, p).r * amp;
		
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

function ondestroy()
	vshader:destroy()
	
	for k, m in pairs(allo.machines) do
		for i, p in ipairs(m) do
			if p.map3Dtex then p.map3Dtex:destroy() end
		end
	end
end

function draw()
	
	-- go 3D:
	local near, far = 0.1, 100
	local fovy, aspect = 80, 1.2
	local a = t * 0.1
	local at = vec3(0, 0, 2)
	local eye = at + vec3(cos(a), 0, sin(a)) * 4
	local up = vec3(0, 1, 0)
	
	gl.MatrixMode(gl.PROJECTION)
	gl.LoadMatrix(mat4.perspective(fovy, aspect, near, far))
	gl.MatrixMode(gl.MODELVIEW)
	local mv = mat4.lookat(eye, at, up)
	gl.LoadMatrix(mv)
	

	---[[
	gl.Enable(gl.SCISSOR_TEST)
	for i, p in ipairs(allo.current) do
		
		local l = p.viewport.l * window.width
		local b = p.viewport.b * window.height
		local w = p.viewport.w * window.width
		local h = p.viewport.h * window.height
		gl.Viewport(l, b, w, h) 
		gl.Scissor(l, b, w, h) 
		gl.Enable(gl.DEPTH_TEST)
		gl.Clear()
		
		--[[
		gl.Begin(gl.LINES)
		for i = 1, 100 do
			gl.Vertex(0, 0, 0)
			gl.Vertex(math.random()*2-1, math.random()*2-1, 0)
		end
		gl.End()
		--]]
		
		local s = vshader
		s:bind()
		--s:uniform("now", now())
		s:uniform("map3D", 0)
		if window.eye == "right" then
			s:uniform("parallax", 0.1)
		elseif window.eye == "left" then
			s:uniform("parallax", -0.1)
		else
			s:uniform("parallax", 0)
		end
		s:uniform("voxels", 1)
		
		voxels:send(1)
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_S, gl.REPEAT)
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_T, gl.REPEAT)
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_R, gl.REPEAT)
		
		p.map3Dtex:bind(0)
		gl.Begin(gl.QUADS)
			gl.TexCoord2f(0, 0) 	gl.Vertex3f(0, 0, 0)
			gl.TexCoord2f(1, 0)		gl.Vertex3f(1, 0, 0)
			gl.TexCoord2f(1, 1)		gl.Vertex3f(1, 1, 0)
			gl.TexCoord2f(0, 1)		gl.Vertex3f(0, 1, 0)
		gl.End()
		voxels:unbind(1)
		p.map3Dtex:unbind(0)
		
		s:unbind()
		
		-- axes:
		gl.Begin(gl.LINES)
			gl.Normal(1, 1, 1) gl.Color(0,1,1) gl.Vertex(-0.1, 0, 0)
			gl.Normal(1, 1, 1) gl.Color(1,0,0) gl.Vertex(1, 0, 0)
			gl.Normal(1, 1, 1) gl.Color(1,0,1) gl.Vertex(0, -0.1, 0)
			gl.Normal(1, 1, 1) gl.Color(0,1,0) gl.Vertex(0, 1, 0)
			gl.Normal(1, 1, 1) gl.Color(1,1,0) gl.Vertex(0, 0, -0.1)
			gl.Normal(1, 1, 1) gl.Color(0,0,1) gl.Vertex(0, 0, 1)
		gl.End()
		-- allosphere:
		gl.Color(1,1,1,0.25)
		gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
		--allosphere:drawframe()
		gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
		
		--[=[
		-- data:
		gl.Begin(gl.POINTS)
		for i = 0, p.elems do
			--local px = p.pix[i]
			local pt = p.map3D[i]
			--gl.Color(px.x, px.y, 0.3)
			gl.Vertex(pt.x, pt.y, pt.z)
		end
		gl.End()
		--]=]
	end
	gl.Disable(gl.SCISSOR_TEST)
	--]]
end

if ffi.os == "Linux" then
	window.stereo = true
	window.fullscreen = true
end
av.run()
--return allo