local ffi = require "ffi"
local C = require "darwin"
local sin, cos = math.sin, math.cos
local abs = math.abs
local pi = math.pi
local floor = math.floor
local sqrt = math.sqrt
local min, max = math.min, math.max
local random = math.random
local srandom = function() return random()*2-1 end

local gl = require "gl"
local vec2 = require "vec2"
local vec3 = require "vec3"
local vec4 = require "vec4"
local nav3 = require "nav3"
local mat4 = require "mat4"
local quat = require "quat"
local displaylist = require "displaylist"
local shader = require "shader"
local texture = require "texture"
local fbo = require "fbo"
local cubefbo = require "cubefbo"
local allosphere = require "allosphere"

local usefitting = true
local datapath = "/Users/grahamwakefield/code/calibration-current"
local projectors = {}

--[[

If we have the camera in the right place (at the center of projection), the projected image on the surface looks almost like a proper rectangle. There should be a way to use this fact to derive the pose of projection (pos + unit vectors). Facts:
- lines between adjacent pixels are near horizontal (or vertical)
- spacing between pixels is even
- aspect ratio of pixels is regular

There's a lot of data to work from, so this is a good candidate for optimization.

We assume the projector has a regular perspective and view matrix, and project the raw points through this matrix to get the screen locations. Then optimize this matrix by stages:

1. move view until lines become straight (but not parallel)
	- initial guess from eyeballing
	- mutate projector location
	- pick random pairs on a row or column
		-> unit vector error between near and far neighbors is minimized
2. orient view (XY) until lines become parallel/orthogonal
	- initial guess from projection-to-center and mid-side axes
	- mutate X or Y rotation
		- probably mostly X rotation (off-axis center for table/ceiling-style 
	- pick random pairs of h or v lines
		-> unit vector error between lines is minimized
	- pick random pairs of h and v lines
		-> orthogonality error between h/v lines is minimizedprojectors)

[possible to interleave steps (1) and (2)]		
	
3. orient view (Z) until lines become properly horizontal/vertical
	-> simple rotation, probably minimal
4. derive scale parameters from corners
	- scale by fovy/fovx (fovy, aspect)
	- initial guess of aspect from projector resolution
5. derive shift parameters from center
	- shift by off-axis projection matrix

If the assumption holds, then we should be able to project a raw map3D point (on the surface of the screen) through the matrix and get the corresponding UV coordinate of the point back with minimal error. 

We could plot the error to see how close we got, and see what shape the error surface has. The most important places to be correct are the edges (overlaps). If using several matrices is better, we can do that and interpolate between them.

The last step is to bake a cubemap of projected points.

Calculating depth is trickier, but tractable
Calculating stereo offset is also trickier

--------------------------------------------------------------------------------

The assumption: there is an imaginary projection plane where the UV origin is exactly 1 unit distance from the lens. The desired UV coordinates are on this plane. We need to know the orientation of the plane, and where the UV origin is relative to the projector. The orientation of the plane can be given in terms of the two (orthogonal) vectors on the surface. The position of UV origin can be given as a unit vector relative to the projector.

Initial guesses can be made:
	The UV origin could be the unit vector from projector to the center pixel.
	The V vector direction can be estimated from the top and bottom middle pixels (but what about magnitude?)
	Same for the U.

Then for any vertex, we only need to 
	1) make it relative to the plane
	2) intersect it with the plane

Another way: we need to find the center of projection axis (probably near to the bottom or top edge), and the UV scaling factors. The projection plane is centered on that axis, and then UV coordinates are shifted & scaled.

--]]

local phong = shader()
phong:vertex[[
	uniform float lighting;
	uniform vec3 ambient, diffuse, specular;
	uniform vec3 lightpos;
	varying vec4 color;
	void main(){
		color = gl_Color;
		vec4 vertex = gl_ModelViewMatrix * gl_Vertex;
		vec3 normal = gl_NormalMatrix * gl_Normal;
		vec3 V = vertex.xyz;
		vec3 eyeVec = normalize(-V);
		vec3 lightDir = normalize(lightpos); // - V);
		gl_Position = gl_ProjectionMatrix * vertex; 
		
		vec3 final_color = color.rgb * ambient;
		vec3 N = normalize(normal);
		vec3 L = lightDir;
		float lambertTerm = max(dot(N, L), 0.0);
		final_color += diffuse * color.rgb * lambertTerm;
		vec3 E = eyeVec;
		vec3 R = reflect(-L, N);
		float spec = pow(max(dot(R, E), 0.0), 0.9 + 1e-20);
		final_color += specular * spec;
		color = vec4(mix(color.rgb, final_color, lighting), color.a);
	}
]]
phong:fragment[[
	varying vec4 color;
	void main() {
		gl_FragColor = color;
	}
]]

local showMap3D = shader()
showMap3D:vertex[[
	varying vec2 T;
	void main (void) {  
		T = gl_MultiTexCoord0.xy;		
		gl_Position = vec4(T*2.-1., 0., 1.); 
	}
]]
showMap3D:fragment[[
	uniform sampler2D map3D;
	varying vec2 T;
	void main (void) {	
		vec3 d = normalize(texture2D(map3D, T).rgb);
		d = 0.5 + (d * mod(d * 8., 1.));
		gl_FragColor = vec4(d * 0.5 + 0.5, 1);
	}
]]

local showDemo = shader()
showDemo:vertex[[
	varying vec2 T;
	void main (void) {  
		T = gl_MultiTexCoord0.xy;	
		gl_Position = vec4(T*2.-1., 0., 1.); 	
	}
]]
showDemo:fragment[[
	uniform sampler2D map3D;
	varying vec2 T;
	
	// q must be a normalized quaternion
	vec3 quat_rotate(in vec4 q, in vec3 v) {
		vec4 p = vec4(
			q.w*v.x + q.y*v.z - q.z*v.y,  // x
			q.w*v.y + q.z*v.x - q.x*v.z,  // y
			q.w*v.z + q.x*v.y - q.y*v.x,  // z
		   -q.x*v.x - q.y*v.y - q.z*v.z   // w
		);
		return vec3(
			-p.w*q.x + p.x*q.w - p.y*q.z + p.z*q.y,  // x
			-p.w*q.y + p.y*q.w - p.z*q.x + p.x*q.z,  // y
			-p.w*q.z + p.z*q.w - p.x*q.y + p.y*q.x   // z
		);
	}
	
	// SCENE: SIGNED DISTANCE ESTIMATION FUNCTIONS //
	float map(vec3 p) {
		vec3 c = vec3(5, 4, 3);
		vec3 pr1 = mod(p,c)-0.5*c;
		return length(max(abs(pr1)-vec3(0.4, 0.1, 0.8), 0.0));
	}
	
	void main(){	
		vec3 pos = vec3(0, 0, 1);
		vec4 quat = vec4(0, 0, 0, 1);
		float eyesep = 0.;
		vec3 light1 = pos + vec3(1, 2, 3);
		vec3 light2 = pos + vec3(2, -3, 1);
		vec3 color1 = vec3(0.3, 0.7, 0.6);
		vec3 color2 = vec3(0.6, 0.2, 0.8);
		vec3 ambient = vec3(0.1, 0.1, 0.1);

		vec3 nv = normalize(texture2D(map3D, T).rgb);
		vec3 rd = quat_rotate(quat, nv);
		vec3 up = vec3(0, 1, 0);
		vec3 rdx = cross(normalize(rd), up);
		vec3 eye = rdx * eyesep * 0.02;
		vec3 ro = pos + eye;
		
		float mindt = 0.01;	// how close to a surface we can get
		float mint = mindt;
		float maxt = 50.;
		float t=mint;
		float h = maxt;
		
		vec3 p = ro + mint*rd;
		int steps = 0;
		int maxsteps = 50;
		for (t; t<maxt;) {
			h = map(p);
			t += h;
			p = ro + t*rd;
			if (h < mindt) { break; }
			if (++steps > maxsteps) { t = maxt; break; }
		}

		vec3 color = vec3(0, 0, 0);
		if (t<maxt) {
			float eps = 0.01;
			vec3 grad = vec3( 
				map(p+vec3(eps,0,0)) - map(p-vec3(eps,0,0)),
				map(p+vec3(0,eps,0)) - map(p-vec3(0,eps,0)),
				map(p+vec3(0, 0, eps)) - map(p-vec3(0,0,eps))  
			);
			vec3 normal = normalize(grad);
			vec3 ldir1 = normalize(light1 - p);
			vec3 ldir2 = normalize(light2 - p);
			color = ambient
					+ color1 * max(0.,dot(ldir1, normal))  
					+ color2 * max(0.,dot(ldir2, normal)) 
					;
			float tnorm = t/maxt;
			color *= 1. - tnorm*tnorm;
		}
		gl_FragColor = vec4(color, 1);
	}
]]

local showCube = shader()
showCube:vertex[[
	varying vec2 T;
	void main (void) {  
		T = gl_MultiTexCoord0.xy;		
		gl_Position = vec4(T*2.-1., 0., 1.); 
	}
]]
showCube:fragment[[
	uniform sampler2D map3D;
	//uniform sampler2D alphaMap;
	uniform samplerCube cubeMap;
	varying vec2 T;
	
	void main (void){
		vec3 v = normalize(texture2D(map3D, T).rgb);
		vec3 rgb = textureCube(cubeMap, v).rgb; // * texture2D(alphaMap, T).rgb;		
		gl_FragColor = vec4(rgb, 1.);
	}
]]

local cubeCapture = shader()
cubeCapture:vertex[[
	uniform float lighting;
	uniform vec3 ambient, diffuse, specular;
	uniform vec3 lightpos;
	varying vec4 color;
	
	
	// @omni_eye: the eye parallax distance. 	
	//	This will be zero for mono, and positive/negative for right/left eyes.
	//	Pass this uniform to the shader in the OmniStereoDrawable callback 
	uniform float omni_eye;
		
	// @omni_face: the GL_TEXTURE_CUBE_MAP face being rendered. 	
	//	For a typical forward-facing view, this should == 5.	
	//	Pass this uniform to the shader in the OmniStereoDrawable callback 
	uniform int omni_face;	

	// @omni_near: the near clipping plane. 	
	uniform float omni_near;	

	// @omni_far: the far clipping plane. 	
	uniform float omni_far;	
		
	// omni_render(vertex)	
	// @vertex: the eye-space vertex to be rendered.	
	//	Typically gl_Position = omni_render(gl_ModelViewMatrix * gl_Vertex);	
	vec4 omni_render(in vec4 vertex) {	
		// unit direction vector:	
		vec3 vn = normalize(vertex.xyz);	
		// omni-stereo effect (in eyespace XZ plane)	
		// cross-product with up vector also ensures stereo fades out at Y poles	
		//v.xyz -= omni_eye * cross(vn, vec3(0, 1, 0));	
		// simplified:	
		vertex.xz += vec2(omni_eye * vn.z, omni_eye * -vn.x);	
		// convert eye-space into cubemap-space:	
		// GL_TEXTURE_CUBE_MAP_POSITIVE_X  	
			 if (omni_face == 0) { vertex.xyz = vec3(-vertex.z, -vertex.y, -vertex.x); }	
		// GL_TEXTURE_CUBE_MAP_NEGATIVE_X	
		else if (omni_face == 1) { vertex.xyz = vec3( vertex.z, -vertex.y,  vertex.x); }	
		// GL_TEXTURE_CUBE_MAP_POSITIVE_Y  	
		else if (omni_face == 2) { vertex.xyz = vec3( vertex.x,  vertex.z, -vertex.y); }	
		// GL_TEXTURE_CUBE_MAP_NEGATIVE_Y 	
		else if (omni_face == 3) { vertex.xyz = vec3( vertex.x, -vertex.z,  vertex.y); }	
		// GL_TEXTURE_CUBE_MAP_POSITIVE_Z  	
		else if (omni_face == 4) { vertex.xyz = vec3( vertex.x, -vertex.y, -vertex.z); }	
		// GL_TEXTURE_CUBE_MAP_NEGATIVE_Z   
		else					 { vertex.xyz = vec3(-vertex.x, -vertex.y,  vertex.z); }	
		// convert into screen-space:	
		// simplified perspective projection since fovy = 90 and aspect = 1	
		vertex.zw = vec2(	
			(vertex.z*(omni_far+omni_near) + vertex.w*omni_far*omni_near*2.)/(omni_near-omni_far),	
			-vertex.z	
		);	
		return vertex;	
	}
	
	void main(){
		vec4 vertex = gl_ModelViewMatrix * gl_Vertex;
		gl_Position = omni_render(vertex);
		
		// the rest is a typical phong effect
		color = gl_Color;
		vec3 normal = gl_NormalMatrix * gl_Normal;
		vec3 V = vertex.xyz;
		vec3 eyeVec = normalize(-V);
		vec3 lightDir = normalize(lightpos); // - V);
		vec3 final_color = color.rgb * ambient;
		vec3 N = normalize(normal);
		vec3 L = lightDir;
		float lambertTerm = max(dot(N, L), 0.0);
		final_color += diffuse * color.rgb * lambertTerm;
		vec3 E = eyeVec;
		vec3 R = reflect(-L, N);
		float spec = pow(max(dot(R, E), 0.0), 0.9 + 1e-20);
		final_color += specular * spec;
		color = vec4(mix(color.rgb, final_color, lighting), color.a);
	}
]]
cubeCapture:fragment[[
	varying vec4 color;
	void main (void) {	
		gl_FragColor = color;
	}
]]

-- this is the ideal one: displaces vertices prior to rendering:
local showPerv = shader()
showPerv:vertex[[

	vec4 perv_render(vec4 vertex) {
		// get world direction:
		vec3 dir = normalize(vertex.xyz);
		// convert unit vector dir into vec2 offset from view axis
		// this could in fact be baked into a cubemap...
		vec3 d = length(vertex.xyz);
		// use d for depth, perspective division & clipping
		return vertex;
	}
	
	varying vec4 C;
	void main (void) {  
		vec4 vertex = gl_ModelViewMatrix * gl_Vertex;
		gl_Position = perv_render(vertex);
		C = gl_Color;
	}
]]
showPerv:fragment[[
	varying vec4 C;
	void main (void) {	
		gl_FragColor = C;
	}
]]

-- initial guesses as to the locations of the projectors:
local initial_estimates = {
	--[[
	vec3(allosphere.capsuleRadius, allosphere.doorwayY, 0),
	vec3(allosphere.capsuleRadius, allosphere.doorwayY, 0),
	vec3(allosphere.capsuleRadius, allosphere.doorwayY, 0),
	vec3(allosphere.capsuleRadius, allosphere.doorwayY, 0),
	
	vec3(-allosphere.capsuleRadius, allosphere.doorwayY, 0),
	vec3(-allosphere.capsuleRadius, allosphere.doorwayY, 0),
	vec3(-allosphere.capsuleRadius, allosphere.doorwayY, 0),
	vec3(-allosphere.capsuleRadius, allosphere.doorwayY, 0),
	
	vec3( 1, -2, -0.5 ),
	vec3( -1, -2, -0.5 ),
	vec3( -1, -2, 0.5 ),
	vec3( -1, -2, 0.5 ),
	--]]
	
	-- PDs
	vec3(4.852,		0.8325,		0.444),	
	vec3(4.804,		0.793,		-0.591),
	-- these two might be the wrong way around... can't remember
	vec3(4.804,		0.795,		-0.23),
	vec3(4.169916, 1.124892, 0.029404), --vec3(4.828,		0.765,		0.088),
	
	vec3(-4.857,	0.8175,		-0.447),
	vec3(-4.792,	0.787,		0.592),
	-- these two might be the wrong way around... can't remember
	vec3(-4.82,		0.812,		0.232),
	vec3(-4.847,	0.765,		-0.117),
	
	-- Barcos
	vec3(0.767164, -3.608163, -1.083599), --vec3(0.735, 	-3.5465,	-0.962),
	vec3(-0.755,	-3.5295,	-0.958),
	vec3(-0.786,	-3.5585,	0.946),
	vec3(0.768,		-3.5495,	0.942),
}



function configure(self)
	local pos = self.projector_position
	local map3D = self.map3D
	local w, h = self.width, self.height
	
	function getpixel(x, y) 
		local v = map3D[floor(y)*w + floor(x)] 
		return vec3(v.x, v.y, v.z)
	end
	
	local bl = getpixel(0, h-1)
	local bm = getpixel(w/2, h-1)
	local br = getpixel(w-1, h-1)
	local tl = getpixel(0, 0)
	local tm = getpixel(w/2, 0)
	local tr = getpixel(w-1, 0)
	local mid = getpixel(w/2, h/2)
	
	-- unit component of vector to projector:
	local posu = pos:normalizenew()
	-- unit components of vectors to top-middle and bottom-middle:
	local tmu = tm:normalizenew()
	local bmu = bm:normalizenew()
	-- far corner of parallelogram
	local posu2 = posu * 2
	
	-- ratio of triangle areas:
	local v1 = posu2:cross(bmu):normalize()
	local v2 = tmu:cross(bmu):normalize()
	local ratio_top = v1/v2
	
	-- where the ratio is even is the plane we care about
	local plane = ratio_top * tmu - pos
	local planeu = plane:normalizenew()
	
	local normal = (-pos):dot(planeu) * planeu + pos
	local normald = #normal
	local normalu = normal / normald
	
	-- find the uv intersection of screen corners
	local tld = (tl-pos):dot(normalu)
	local trd = (tr-pos):dot(normalu)
	local bld = (bl-pos):dot(normalu)
	local brd = (br-pos):dot(normalu)
	
	local tl_intersect = (tl-pos) / tld + pos
	local tr_intersect = (tr-pos) / trd + pos
	local bl_intersect = (bl-pos) / bld + pos
	local br_intersect = (br-pos) / brd + pos
	
	-- vector elements of the uv coordinate
	-- hopefully these should be perpendicular to each other
	local xvec = tr_intersect - tl_intersect
	local yvec = bl_intersect - tl_intersect
	
	self.pos = pos
	self.xvec = xvec
	self.yvec = yvec
	self.normal = normalu
	
	self.mid = mid
	self.bl = bl
	self.br = br
	self.bm = bm
	self.tl = tl
	self.tr = tr
	self.tm = tm
end

for i = 9, 9 do
	local self = import(string.format("%s/map3D%s.bin", datapath, i))
	
	self.projector_position = initial_estimates[i]
	
	
	self.getpixel = function(self, x, y) 
		local v = self.map3D[floor(y)*self.width + floor(x)] 
		return vec3(v.x, v.y, v.z)
	end
	
	configure(self)
	
	self.quads = displaylist(function()
		local jump = 32
		local function drawprojquad(self, x, y)
			local idx = y*self.width + x
			local v = self.map3D[idx]
			gl.TexCoord(x / self.width, y / self.height)
			gl.Vertex(v.x, v.y, v.z)
		end
		gl.Begin(gl.QUADS)
			local data = self.map3D
			for y = 0, self.height-jump-1, jump do
				for x = 0, self.width-jump-1, jump do
					drawprojquad(self, x, y)
					drawprojquad(self, x+jump, y)
					drawprojquad(self, x+jump, y+jump)
					drawprojquad(self, x, y+jump)
				end 
			end
		gl.End()
	end)
	projectors[#projectors+1] = self
end

function drawWorld()
	gl.Begin(gl.LINES)
		gl.Color(0,1,1) gl.Vertex(-0.1, 0, 0)
		gl.Color(1,0,0) gl.Vertex(1, 0, 0)
		gl.Color(1,0,1) gl.Vertex(0, -0.1, 0)
		gl.Color(0,1,0) gl.Vertex(0, 1, 0)
		gl.Color(1,1,0) gl.Vertex(0, 0, -0.1)
		gl.Color(0,0,1) gl.Vertex(0, 0, 1)
	gl.End()
	
	gl.Color(1,1,1,1)
	allosphere:drawframe()
end

local fbos = fbo(512, 512, #projectors)
local cubefbos = cubefbo(1024, 1024)
nav3.pos.z = 10

local currentshader = showDemo --showCube
local cubecaptured = false
local screen = 1
local fovy = 60
local pmat, vmat

function compute_parallel_error(pv1, pv2, pv3)
		
	-- get the relative vectors
	local r1 = (pv1 - pv2):normalize()
	local r2 = (pv1 - pv3):normalize()
	-- compute error in terms of absolute angle between these:
	local err = max(0, 1 - abs(r1:dot(r2)))
	return err
end

function compute_orthogonal_error(x1, x2, y1, y2)
	-- we only care about the xy components:
	-- get the relative vectors
	local r1 = (x1 - x2):normalize()
	local r2 = (y1 - y2):normalize()
	
	return max(0, min(1, abs(r1:dot(r2))))
end

function estimate() end
local estimate = coroutine.wrap(function(p)
	-- the closer this gets to zero, the more parallel are the lines:
	local parallel_err = 1
	local parallel_move = 1
	local orthogonal_err = 1
	local orthogonal_turn = 1
	
	local parallel_point_set = {}
	local screen_point_set = {}

	-- generate a set of points to apply the parallel test to:
	local numtests = 400
	if #parallel_point_set == 0 then
		parallel_move = 1
		orthogonal_turn = 1
		for i = 1, numtests do			
			-- vertical:
			local c = math.random(p.width)-1		
			local r1 = math.random(p.height)-1
			local r2 = math.random(p.height)-1
			local r3 = math.random(p.height)-1
			table.insert(parallel_point_set, 
				vec4.fromvec3(p:getpixel(c, r1)))
			table.insert(parallel_point_set, 
				vec4.fromvec3(p:getpixel(c, r2)))
			table.insert(parallel_point_set, 
				vec4.fromvec3(p:getpixel(c, r3)))
			
			-- and horizontal:
			local c1 = math.random(p.width)-1		
			local c2 = math.random(p.width)-1		
			local c3 = math.random(p.width)-1		
			local r = math.random(p.height)-1
			table.insert(parallel_point_set, 		
				vec4.fromvec3(p:getpixel(c1, r)))
			table.insert(parallel_point_set, 
				vec4.fromvec3(p:getpixel(c2, r)))
			table.insert(parallel_point_set, 
				vec4.fromvec3(p:getpixel(c3, r)))		
		end
	end
	
	-- initial error:
	local errtotal = 0
	for i = 1, #screen_point_set, 3 do
		local err = compute_parallel_error(
			screen_point_set[i+0],
			screen_point_set[i+1],
			screen_point_set[i+2]
		)
		errtotal = errtotal + sqrt(err)
	end
	parallel_err = (errtotal / numtests) * (errtotal / numtests)
	
	
	local tries = 0
	while tries < 100 do
		tries = tries + 1
		
		for pass = 1, 10 do
			-- try adjusting the position:
			local newpos = nav3.pos + vec3.random(parallel_move)
			local q1 = nav3.q
			local vmat = mat4.lookatu(newpos, q1:ux(), q1:uy(), q1:uz())
			for i, v in ipairs(parallel_point_set) do	
				-- transform by current vmat:
				local v1 = pmat:transform(vmat:transform(v))
				-- only care about xy positions:
				local v2 = vec2(v1.x / v1.w, v1.y / v1.w)
				screen_point_set[i] = v2
			end
			
			local errtotal = 0
			for i = 1, #screen_point_set, 3 do
				local err = compute_parallel_error(
					screen_point_set[i+0],
					screen_point_set[i+1],
					screen_point_set[i+2]
				)
				errtotal = errtotal + sqrt(err)
			end
			local new_parallel_err = (errtotal / numtests) * (errtotal / numtests)
			
			parallel_move = parallel_move * 0.99
			if new_parallel_err < parallel_err then
				-- keep it:
				nav3.pos = newpos
				parallel_err = new_parallel_err
				tries = 0
			end
			
			
		end
		
		print("parallel_err", parallel_err, new_parallel_err, parallel_move)
		print(nav3.pos)
		gl.LineWidth(0.3)
		gl.Color(1, 1, 1, 0.1)
		gl.Begin(gl.LINES)
		for i = 1, #screen_point_set, 3 do
			gl.Vertex(screen_point_set[i+0].x, screen_point_set[i+0].y)
			gl.Vertex(screen_point_set[i+1].x, screen_point_set[i+1].y)
			gl.Vertex(screen_point_set[i+0].x, screen_point_set[i+0].y)
			gl.Vertex(screen_point_set[i+2].x, screen_point_set[i+2].y)
		end
		gl.End()
		
		coroutine.yield()
	end
	
	print("next orient:")
	
	-- initial error:
	local errtotal = 0
	for i = 1, #screen_point_set, 6 do
		local err = compute_orthogonal_error(
			screen_point_set[i+0],
			screen_point_set[i+1],
			screen_point_set[i+3],
			screen_point_set[i+4]
		)
		errtotal = errtotal + sqrt(err)
	end
	orthogonal_err = (errtotal / numtests) * (errtotal / numtests)
		
	
	local tries = 0
	while tries < 100 do
		tries = tries + 1
		
		for pass = 1, 10 do
			-- orthogonal testing:
			-- orientation:
			local turn =  quat.fromAxisY(srandom() * orthogonal_turn * 0.05)
						* quat.fromAxisX(srandom() * orthogonal_turn * 0.05)
						* quat.fromAxisZ(srandom() * orthogonal_turn * 0.01)
			turn:normalize()
			local q1 = nav3.q * turn
			q1:normalize()
			local vmat = mat4.lookatu(nav3.pos, q1:ux(), q1:uy(), q1:uz())
			
			for i, v in ipairs(parallel_point_set) do	
				-- transform by current vmat:
				local v1 = pmat:transform(vmat:transform(v))
				-- only care about xy positions:
				local v2 = vec2(v1.x / v1.w, v1.y / v1.w)
				screen_point_set[i] = v2
			end
			
			local errtotal = 0
			for i = 1, #screen_point_set, 6 do
				local err = compute_orthogonal_error(
					screen_point_set[i+0],
					screen_point_set[i+1],
					screen_point_set[i+3],
					screen_point_set[i+4]
				)
				errtotal = errtotal + sqrt(err)
			end
			local new_orthogonal_err = (errtotal / numtests) * (errtotal / numtests)
			
			--orthogonal_turn = orthogonal_turn * 0.999
			if new_orthogonal_err < orthogonal_err then
				-- keep it:
				nav3.q = q1
				orthogonal_err = new_orthogonal_err
				tries = 0
			end
			
		end
		-- average error:
		print("orthogonal_err", orthogonal_err, new_orthogonal_err, orthogonal_turn)
		
		gl.LineWidth(0.3)
		gl.Color(1, 1, 1, 0.1)
		gl.Begin(gl.LINES)
		for i = 1, #screen_point_set, 3 do
			gl.Vertex(screen_point_set[i+0].x, screen_point_set[i+0].y)
			gl.Vertex(screen_point_set[i+1].x, screen_point_set[i+1].y)
			gl.Vertex(screen_point_set[i+0].x, screen_point_set[i+0].y)
			gl.Vertex(screen_point_set[i+2].x, screen_point_set[i+2].y)
		end
		gl.End()
		
		coroutine.yield()
	end
	
	print("done")
	
	while true do
		coroutine.yield()
	end
end)


function draw()
	-- always update nav: 
	nav3:update()
	
	-- offline capture a world into a cubeFBO:
	if not cubecaptured then
		cubefbos:startcapture()
		for face = 0, 5 do
			cubefbos:face(face)
			gl.Enable(gl.DEPTH_TEST)
			gl.ClearColor(0.1,0.1,0.1)
			gl.Clear(gl.COLOR_BUFFER_BIT, gl.DEPTH_BUFFER_BIT)
		
			gl.MatrixMode(gl.PROJECTION)
			local near, far = 0.1, 100
			local D = far-near	
			local D2 = far+near
			local D3 = far*near*2
			gl.LoadMatrix{
				1,	0,	0,		0,
				0,	1,	0,		0,
				0,	0,	-D2/D,	-1,
				0,	0,	-D3/D,	0
			}
			gl.MatrixMode(gl.MODELVIEW)
			gl.LoadIdentity()
			
			-- a little scene:
			cubeCapture:bind()
			cubeCapture:uniform("omni_face", face)
			cubeCapture:uniform("omni_eye", 0.)
			cubeCapture:uniform("omni_near", 0.1)
			cubeCapture:uniform("omni_far", 100)
				
			cubeCapture:uniform("lighting", 1)
			cubeCapture:uniform("lightpos", 10, 10, 10)
			cubeCapture:uniform("ambient", 0.2, 0.2, 0.2)
			cubeCapture:uniform("diffuse", 0.8, 0.8, 0.8)
			cubeCapture:uniform("specular", 1, 1, 1)
			
			-- draw axes:
			drawWorld()
			
			cubeCapture:unbind()
		end
		cubefbos:endcapture()
		cubefbos:generatemipmap()
		cubecaptured = true
	end		
	
	gl.ClearColor(0,0,0)
	
	-- simulate the allosphere projector renders:
	fbos:capture(function()
		for i, p in ipairs(projectors) do
			fbos:settexture(i)
			gl.Enable(gl.DEPTH_TEST)
			gl.Clear(gl.COLOR_BUFFER_BIT, gl.DEPTH_BUFFER_BIT)
		
			gl.MatrixMode(gl.PROJECTION)
			gl.LoadIdentity()
			gl.MatrixMode(gl.MODELVIEW)
			gl.LoadIdentity()
			
			-- bind the map3D texture into unit 0:
			if not p.map3Dtex then
				p.map3Dtex = texture(p.width, p.height)
				p.map3Dtex.internalformat = gl.RGB32F
				p.map3Dtex.type = gl.FLOAT
				p.map3Dtex.format = gl.RGBA
				p.map3Dtex.data = ffi.cast("float *", p.map3D)
			end
			
			currentshader:bind()
			if currentshader == showPerv then
				
				-- bind the antiwarp / send param uniforms...
				
				drawWorld()
				
			else
				currentshader:uniform("map3D", 0)
				if currentshader == showCube then
					cubefbos:bind(2)
					currentshader:uniform("cubeMap", 2)
				end
				
				-- bind the map3D texture data:
				p.map3Dtex:bind(0)
				gl.Color(1, 1, 1)
				gl.Begin(gl.QUADS)
					gl.TexCoord(0, 0) gl.Vertex(-1, -1, 0)
					gl.TexCoord(1, 0) gl.Vertex(1, -1, 0)
					gl.TexCoord(1, 1) gl.Vertex(1, 1, 0)
					gl.TexCoord(0, 1) gl.Vertex(-1, 1, 0)
				gl.End()
				if currentshader == showCube then
					cubefbos:unbind(2)
				end	
				p.map3Dtex:unbind(0)
				
			end
			currentshader:unbind()
		end	
	end)
	fbos:generatemipmap()	
	
	-- additive blending:
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE)
	
	-- now show the results:
	gl.Viewport(0, 0, win.width, win.height)
	if true and screen and projectors[screen] then
		-- show the view from one screen only:
		gl.MatrixMode(gl.PROJECTION)
		gl.LoadIdentity()
		gl.MatrixMode(gl.MODELVIEW)
		gl.LoadIdentity()
		
		fbos:settexture(screen)
		
		fbos:bind()
		gl.Color(1, 1, 1)
		gl.Begin(gl.QUADS)
			-- upside down...
			gl.TexCoord(0, 1) gl.Vertex(-1, -1, 0)
			gl.TexCoord(1, 1) gl.Vertex(1, -1, 0)
			gl.TexCoord(1, 0) gl.Vertex(1, 1, 0)
			gl.TexCoord(0, 0) gl.Vertex(-1, 1, 0)
		gl.End()
		fbos:unbind()
	else
		-- go 3D:
		local aspect = win.width/win.height
		
		pmat = mat4.perspective(fovy, aspect, 0.1, 100)
		gl.MatrixMode(gl.PROJECTION)
		gl.LoadMatrix(pmat)
		--gl.LoadMatrix(mat4.ortho(-aspect, aspect, -1, 1, 0.1, 100))
		gl.MatrixMode(gl.MODELVIEW)
		vmat = mat4.lookatu(nav3.pos, nav3.ux, nav3.uy, nav3.uz)
		gl.LoadMatrix(vmat)
		gl.Disable(gl.DEPTH_TEST)
		
		-- draw axes:
		gl.Begin(gl.LINES)
			gl.Color(0,1,1) gl.Vertex(-0.1, 0, 0)
			gl.Color(1,0,0) gl.Vertex(1, 0, 0)
			gl.Color(1,0,1) gl.Vertex(0, -0.1, 0)
			gl.Color(0,1,0) gl.Vertex(0, 1, 0)
			gl.Color(1,1,0) gl.Vertex(0, 0, -0.1)
			gl.Color(0,0,1) gl.Vertex(0, 0, 1)
		gl.End()
		
		-- draw projectors:
		for i, p in ipairs(projectors) do
			gl.Begin(gl.LINES)
			--[[
			gl.Color(0, 0, 1)
			gl.Vertex(p.pos)
			gl.Vertex(p.pos + p.normal)
			gl.Color(1, 0, 0)
			gl.Vertex(p.pos)
			gl.Vertex(p.pos + p.xvec)
			gl.Color(0, 1, 0)
			gl.Vertex(p.pos)
			gl.Vertex(p.pos + p.yvec)
			--]]
			gl.Color(1, 1, 1)
			gl.Vertex(p.pos) gl.Vertex(p.tl)
			gl.Vertex(p.pos) gl.Vertex(p.tr)
			gl.Vertex(p.pos) gl.Vertex(p.bl)
			gl.Vertex(p.pos) gl.Vertex(p.br)
			gl.End()
		end
		
		--[[
		phong:bind()
		phong:uniform("lighting", 1)
		phong:uniform("lightpos", 10, 10, 10)
		phong:uniform("ambient", 0.2, 0.2, 0.2)
		phong:uniform("diffuse", 0.8, 0.8, 0.8)
		phong:uniform("specular", 1, 1, 1)
		gl.Color(1,1,1, 0.2)
		allosphere:drawframe()
		phong:unbind()
		--]]
		
		gl.Color(0.5, 0.5, 0.5, 0.5)
		gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
		allosphere:drawframe()
		gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
		
		
		--gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
		-- render each projector:
		gl.Color(1,1,1, 0.8)
		for i, p in ipairs(projectors) do
			fbos:bind(0, i)	
			p.quads:draw()
			fbos:unbind()
		end
		gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
		
		-- draw overlay:
		
		-- return to default matrix:
		gl.MatrixMode(gl.PROJECTION)
		gl.LoadIdentity()
		gl.MatrixMode(gl.MODELVIEW)
		gl.LoadIdentity()
		gl.Disable(gl.DEPTH_TEST)
		
		
		if screen then
			local p = projectors[screen]
			
			estimate(p)
		end	
	end
end

function lookat_projector(i)
	local p = projectors[i]
	nav3.pos:set(p.pos)
	-- face it
	local uz = (p.pos - p.mid):normalize()
	local uy = (p.tm - p.bm):normalize()
	local ux = uz:cross(uy):normalize()
	local uy = uz:cross(ux):normalize()
	nav3.q:set(quat.fromUnitVectors(ux, uy, uz))
end

function keydown(k)
	local n = tonumber(k)
	if n and n < 10 then
		if screen == n then 
			screen = nil
		else 
			screen = n 
			lookat_projector(screen)
			keydown("!")
		end
	elseif k == "*" then
		-- restart estimation:
		parallel_err = 1
		parallel_point_set = {}
	elseif k == "!" then
		lookat_projector(1)
	elseif k == "=" then
		fovy = fovy + 1
	elseif k == "-" then
		fovy = fovy - 1
	elseif not nav3:keydown(k) then
		print(k)
	end
end

function keyup(k) nav3:keyup(k) end

--lookat_projector(1)












