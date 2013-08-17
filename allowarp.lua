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
local glu = require "glu"
local texture = require "texture"

local image = require "image"
local distance = require "distance"

local nn = require "nanomsg-ffi"

local sin, cos = math.sin, math.cos
local pi, twopi = math.pi, math.pi * 2
local abs = math.abs
local min, max = math.min, math.max

local blob_transform = mat4(
 -2.2672384e-01,   5.1928297e+00,  -9.0727532e-02,   2.1989945e+00,
  3.9574793e-03,  -9.0641179e-02,  -5.1977768e+00,  -5.1985686e-02,
 -5.1936207e+00,  -2.2675838e-01,   3.0413260e-16,  -5.1985686e-02,
  0.0000000e+00,   0.0000000e+00,   0.0000000e+00,   1.0000000e+00
)


-- scala
local data_scale = vec3(0.595, 0.595, 0.25)

local pollockpath

ffi.cdef [[
typedef struct shared {
	char hdr[5];
	quat view;
	vec3 eye;
} shared;
]]

local shared = ffi.new("shared")
shared.hdr = "ping|"
shared.eye = vec3(0.5, 0.5, 0.5)
shared.view:fromEuler(0, 0, 0)
local shared_size = ffi.sizeof(shared)


local datapath, blobpath
if ffi.os == "OSX" then
	datapath = "/Users/grahamwakefield/calibration-current/"
	blobpath = "/Users/grahamwakefield/calibration-data/"
	pollockpath = "/Users/grahamwakefield/code/pollock-work/pollock-data/"
else
	datapath = "/home/sphere/calibration-current/"
	blobpath = "/alloshare/calibration/data/"
	pollockpath = "/home/sphere/matt/pollock-work/pollock-data/"
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
	},
}

---[[
local ADDRESS = "tcp://192.168.0.15:5557"
local ismaster = false
if allo.hostname == "grrrwaaa.local" then
	ismaster = true
	ADDRESS = "tcp://192.168.0.150:5557"
elseif allo.hostname == "photon" then
	ismaster = true
end

local network
if ismaster then
	local pub, err = nn.socket( nn.PUB )
	assert( pub, nn.strerror(err) )
	
	local pid, err = pub:bind( ADDRESS )
	print(pid, err)
	assert( pid and pid >= 0 , nn.strerror(err) )
	
	print("publisher started")
	network = pub
else
	local sub, err = nn.socket( nn.SUB )
	assert( sub, nn.strerror(err) )

	local sid, err = sub:connect( ADDRESS )
	assert( sid and sid >= 0, nn.strerror(err) )
	
	local rc, err = sub:setsockopt( nn.SUB, nn.SUB_SUBSCRIBE, "ping" )
	assert( rc >= 0, nn.strerror(err) )
	
	print("subscriber started")
	network = sub
end
--]]

local dim = 100
local step = 1/dim
local voxels = field3D(dim, dim, dim)
local v = voxels:copy()
local v_next = v:copy()
local vd = v:copy()

-- prime the intensity field:
v:set(function()
	return math.random() < 0.1 and 1 or 0
end)

function gol(x, y, z)
	local C = v:get(x, y, z)
	
	local count = v:get(x+1, y, z)
				+ v:get(x+1, y, z+1)
				+ v:get(x+1, y, z-1)
				+ v:get(x+1, y+1, z)
				+ v:get(x+1, y+1, z+1)
				+ v:get(x+1, y+1, z-1)
				+ v:get(x+1, y-1, z)
				+ v:get(x+1, y-1, z+1)
				+ v:get(x+1, y-1, z-1)
				
				+ v:get(x-1, y, z)
				+ v:get(x-1, y, z+1)
				+ v:get(x-1, y, z-1)
				+ v:get(x-1, y+1, z)
				+ v:get(x-1, y+1, z+1)
				+ v:get(x-1, y+1, z-1)
				+ v:get(x-1, y-1, z)
				+ v:get(x-1, y-1, z+1)
				+ v:get(x-1, y-1, z-1)
				
				+ v:get(x, y, z+1)
				+ v:get(x, y, z-1)
				+ v:get(x, y+1, z)
				+ v:get(x, y+1, z+1)
				+ v:get(x, y+1, z-1)
				+ v:get(x, y-1, z)
				+ v:get(x, y-1, z+1)
				+ v:get(x, y-1, z-1)
	
	if C > 0 then
		if count <= 3 then
			return 0
		elseif count > 7 then
			return 0
		else
			return 1
		end
	else
		if count == 5 then 
			return 1
		else
			return 0
		end
	end
end

function dist(x, y, z)
	if v:get(x, y, z) > 0 then
		return 0
	end

	-- the most naive method: keep iterating outward until an object is found:
	local p = vec3(x, y, z)
	for i = 1, dim/2 do
		local d = i*step
		-- try more samples as we go out:
		for j = 1, i*100 do
			local p1 = p + vec3.random(i)
			if v:get(p1.x, p1.y, p1.z) > 0 then
				return d
			end
		end
	end
	return 0.5	-- maximum distance possible in a toroidal space
end

function run_gol()
	
	-- change a random cell:
	v:set(math.random() < 0.5 and 1 or 0, math.random(dim), math.random(dim), math.random(dim))
	
	
	v_next:set(gol)
	v, v_next = v_next, v
	
	-- use it to compute the distance field:
	-- (maybe hashspace will help?)
	vd:set(dist)
end


function update_voxels()
	voxels:set(function(x, y, z)
		local nx = x/dim
		local ny = y/dim
		local nz = z/dim
		local snx = nx*2-1
		local sny = ny*2-1
		local snz = nz*2-1
		--return 0.5/dim * math.sqrt(nx*nx + ny*ny + nz*nz)
		--return math.sqrt(snx*snx + sny*sny + snz*snz)
		--[[
		local p = vec3(nx, ny, nz)
		local c = vec3(5., 4., 3.)
		local pr1 = (p % c) -0.5*c
		pr1.x = abs(pr1.x)
		pr1.y = abs(pr1.y)
		pr1.z = abs(pr1.z)
		local box = vec3(0.4, 0.1, 0.8)
		local p1 = (pr1 - box):max(0)
		return p1:length()
		--]]
	
		--local s = 2. * sin(nx * twopi) * sin(ny * twopi * 2) * sin(nz * twopi * 2)
	
		--return 0.1*(math.random()) + s --1.5-math.sqrt(snx*snx + sny*sny + snz*snz)
	
		-- put the space origin in the center of the texture:
		local p = vec3(nx, ny, nz) - 0.5
		--local p1 = vec3(sin(now()), cos(now()), 0.)
		
		
		local d1 = distance.sphere(p, sin(now() * pi)*0.3 + 0.3)
		local d2 = distance.box(p, vec3(0.4, 0.2, 0.3))
		local d3 = distance.union(d2, d1)
		
		--[[
		local d11 = distance.sphere(p1, sin(now())*0.03 + 0.06)
		local d12 = distance.box(p1, vec3(0.1, 0.02, 0.03))
		local d13 = distance.union(d11, d12)
		--]]
	
		return d3
	
	end)
end

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
			local sy = sin(pi * ny)
			local cy = cos(pi * ny)
			data[idx]:set(
				sy * sin(twopi * nx),
				cy,
				sy * cos(twopi * nx),
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
	
	p.blendtex = image(datapath .. "alpha1.png")
	return p
end

allo.current[1] = standard_warp()
-- temporary override:
--allo.hostname = "gr04"

print("I am", allo.hostname)


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
			local filename = datapath .. p.blend.file
			print("reading", filename)
			p.blendtex = image(filename)
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
uniform sampler2D map3D, blend;
uniform sampler3D voxels;
uniform vec3 eye;
uniform float parallax;
uniform float now;
varying vec2 T;
varying mat4 mv;


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


float near = 2.; //0.1;
float far = 20.;
float step = (far - near) * 0.05;
float eps = step * 0.1;
vec3 epsx = vec3(eps,0,0);
vec3 epsy = vec3(0,eps,0);
vec3 epsz = vec3(0,0,eps);

vec3 light1 = vec3(0.1, 0.2, 0.3) * far;
vec3 light2 = vec3(0.2, -0.3, 0.1) * far;
vec3 color1 = vec3(0.3, 0.7, 0.6);
vec3 color2 = vec3(0.6, 0.2, 0.8);
vec3 ambient = vec3(0.1, 0.1, 0.1);

// in eye space, never changes!
vec3 up = vec3(0., 1., 0.);


float scene(vec3 p) {
	/*
	vec3 c = vec3(10., 8., 6. + 0.1*cos(p.y));
	vec3 pr1 = mod(p,c)-0.5*c;
	pr1 = quat_rotate(quat_fromeuler(sin(now + 3.*p.x), cos(now * 2.), sin(p.z)), pr1);
	vec3 box = vec3(0.2, 0.1, 0.3);
	return length(max(abs(pr1)-box, 0.0));
	*/
	
	//return length(p) - 0.1;
	
	// convert p to a unit texcoord:
	p /= far;
	
	return texture3D(voxels, p).x * far;
}

void main() {
	vec3 color = vec3(0, 0, 0);
	
	// the ray origin:
	vec3 ro = (mv * vec4(0., 0., 0, 1.)).xyz;
	
	vec3 raw_rd = (texture2D(map3D, T).xyz);
	// rotate by view:
	vec3 rd = normalize((mv * vec4(raw_rd, 1.)).xyz - ro);
	
	// stereo shift:
	vec3 rdx = cross(normalize(rd), up);
	ro += rdx * parallax;
	
	float t = near;
	float c = 0.;
	float amp = step * 10.;
	
	vec3 p = ro + rd * t;
	
	
	float d = scene(p);
	
	
	#define MAX_STEPS 50
	for (int i=0; i<MAX_STEPS; i++) {
		t += d;
		p = ro + rd * t;
		d = scene(p);
		if (d < eps || t > far) { 
			//color.r = float(i)/float(MAX_STEPS);
			//color.g = d / 512.;
			break; 
		}
	}
	
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
				
		// fog effect:
		float tnorm = t/far;
		color *= 1. - tnorm*tnorm;
	}
	gl_FragColor = vec4(color, 1.) * texture2D(blend, vec2(T.x, 1.-T.y)).x;
}
]]
local distance_shader = shader(vs, fs)

local fs = glsl_math .. [[
uniform sampler2D map3D, blend;
uniform sampler3D voxels;
uniform vec3 data_scale;
uniform vec4 view;
uniform vec3 eye;
uniform float parallax;
uniform float now;
varying vec2 T;
varying mat4 mv;


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


float near = 0.3; //0.1;
float far = 2.;
float step = (far - near) * 0.02;
float eps = step * 0.1;
vec3 epsx = vec3(eps,0,0);
vec3 epsy = vec3(0,eps,0);
vec3 epsz = vec3(0,0,eps);

vec3 light1 = vec3(0.1, 0.2, 0.3) * far;
vec3 light2 = vec3(0.2, -0.3, 0.1) * far;
vec3 color1 = vec3(0.3, 0.7, 0.6);
vec3 color2 = vec3(0.6, 0.2, 0.8);
vec3 ambient = vec3(0.1, 0.1, 0.1);

// in eye space, never changes!
vec3 up = vec3(0., 1., 0.);

vec3 hi = vec3(4, 0, 0);
vec3 lo = vec3(0, 1, 1);

void main() {
	vec3 color = vec3(0, 0, 0);
	
	// the ray origin:
	vec3 ro = eye;
	
	vec3 raw_rd = (texture2D(map3D, T).xyz);
	// rotate by view:
	vec3 rd = quat_rotate(view, normalize(raw_rd));
	
	// stereo shift:
	vec3 rdx = cross(normalize(rd), up);
	ro += rdx * parallax;
	
	float t = near;
	float c = 0.;
	float amp = 0.05;
	
	vec3 p = ro + rd * t;
	float vraw0 = 0.;
	float thresh = 3.;
	
	for (;t < far;) {
		
		// is next point out of range?
		float t1 = t + step;
		//step = step * 1.25;
		vec3 p1 = ro + t1 * rd;
		
		// get density at current point
		float vraw = texture3D(voxels, p1 * data_scale / far).r;
		float v = vraw * amp;
		
		if (vraw > thresh) {
			// find the intersection point:
			float tinterp = (thresh-vraw0)/(vraw - vraw0);
			float tnew = t + tinterp * (t1 - t);
			
			p1 = ro + tnew * rd;
			vraw = texture3D(voxels, p1 * data_scale / far).r;
			v = vraw * amp;
			
			//color += v; //mix(lo, hi, v * 2.) * v;
			
			color = vec3(v * 4.); //vec3(tinterp);
			
			break;
		} 
		
		// accumulate color
		//color += v; //mix(lo, hi, v * 2.) * v;
		
		// move to next point
		vraw0 = vraw;
		p = p1;
		t = t1;
	}
	gl_FragColor = vec4(color, 1.) * texture2D(blend, vec2(T.x, 1.-T.y)).x;
}
]]
local volume_shader = shader(vs, fs)

function ondestroy()
	print("DESTROYING")
	
	distance_shader:destroy()
	voxels:destroy()
	
	for k, m in pairs(allo.machines) do
		for i, p in ipairs(m) do
			if p.map3Dtex then p.map3Dtex:destroy() end
			if p.blendtex then p.blendtex:destroy() end
		end
	end
end

function draw()
	glu.assert("draw")
	
	-- go 3D:
	local near, far = 0.1, 100
	local fovy, aspect = 80, 1.2
	
	if ismaster then	
		
		local a = t * 0.03
		
		--shared.at = vec3(0, 0, now())
		shared.view = quat.fromEuler(a, 0, 0) 
		shared.eye = vec3(0.5, 0.5, 0.5) + shared.view:uz() * 0.5
		--print(shared.eye)
		--print(shared.at, shared.eye)
		--shared.at = shared.eye + dir * 0.1
		--shared.up = up
		--local msg = string.format("nav|ping from photon %f", now())
		local ptr = ffi.cast("void *", shared)
		local rc, err = network:send( ptr, shared_size )
   		assert( rc > 0, 'send failed' )    
	else
		local msg, err = network:recv_zc(nn.DONTWAIT)
		if msg then
			local sz = tonumber(msg.size)
			local ptr = ffi.cast("char *", msg.ptr)
			assert(sz == shared_size, "shared size mismatch")
			ffi.copy(shared, ptr, sz)
			
		elseif err == 35 or err == 11 then
			-- ignore temporarily unavailable error
		elseif err then
			print(string.format("err code:%d err:%s\n",
			err, nn.strerror(err)))
		end
	end
	
	--run_gol() voxels = vd
	--update_voxels()
	
	gl.MatrixMode(gl.PROJECTION)
	gl.LoadMatrix(mat4.perspective(fovy, aspect, near, far))
	gl.MatrixMode(gl.MODELVIEW)
	local mv = mat4.lookatu(shared.eye, shared.view:ux(), shared.view:uy(), shared.view:uz())
	gl.LoadMatrix(mv)
	
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
		
		glu.assert(i)
		
		local s = distance_shader
		local s = volume_shader
		s:bind()
		--s:uniform("now", now())
		local eyesep = 0.003
		s:uniform("map3D", 0)
		if window.eye == "right" then
			s:uniform("parallax", eyesep)
		elseif window.eye == "left" then
			s:uniform("parallax", -eyesep)
		else
			s:uniform("parallax", 0)
		end
		s:uniform("voxels", 1)
		s:uniform("blend", 2)
		s:uniform("eye", shared.eye.x, shared.eye.y, shared.eye.z)
		s:uniform("view", shared.view.x, shared.view.y, shared.view.z, shared.view.w)
		s:uniform("data_scale", data_scale.x, data_scale.y, data_scale.z)
		--
		voxels:send(1)
		--[[
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_S, gl.REPEAT)
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_T, gl.REPEAT)
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_R, gl.REPEAT)
		--]]
		--[[
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_S, gl.CLAMP)
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_T, gl.CLAMP)
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_R, gl.CLAMP)
		--]]
		---[[
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_BORDER)
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_BORDER)
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_R, gl.CLAMP_TO_BORDER)
		--]]
		p.map3Dtex:bind(0)
		p.blendtex:bind(2)
		gl.Begin(gl.QUADS)
			gl.TexCoord2f(0, 0) 	gl.Vertex3f(0, 0, 0)
			gl.TexCoord2f(1, 0)		gl.Vertex3f(1, 0, 0)
			gl.TexCoord2f(1, 1)		gl.Vertex3f(1, 1, 0)
			gl.TexCoord2f(0, 1)		gl.Vertex3f(0, 1, 0)
		gl.End()
		p.blendtex:unbind(2)
		voxels:unbind(1)
		p.map3Dtex:unbind(0)
		
		s:unbind()
		
		-- axes:
		--[=[
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
		--]=]
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
	
	glu.assert("end draw")
end

function loadpollocks()
	local SIZE_X = 100 --862
	local SIZE_Y = 100 --1062
	local SIZE_Z = 100 --1027
	local sizeToRead = SIZE_X * SIZE_Y * SIZE_Z
	local volumeData = ffi.new("char[?]", sizeToRead)
	local filename = pollockpath .. "DistanceData-400x400x400" --"DistanceData-100x100x100"
	local f = C.open(filename, 0)
	assert(f ~= -1, filename)	
	C.read(f, volumeData, ffi.sizeof(volumeData))
	for i = 1, 10 do
		print(i, volumeData[i])
	end
	
	local vol = field3D(100, 100, 100)
	for i = 0, 1000000-1 do
		vol.data[i] = volumeData[i]
	end
	voxels = vol
end

loadpollocks()

if ffi.os == "Linux" then
	window.fullscreen = true
	window.stereo = true
end
av.run()
--return allo