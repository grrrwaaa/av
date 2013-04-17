local ffi = require "ffi"
local C = require "darwin"
local sin, cos = math.sin, math.cos
local pi = math.pi
ffi.cdef [[
typedef struct vec4f {
	float x, y, z, w;
} vec4f;
]]

local gl = require "gl"
local vec3 = require "vec3"
local nav3 = require "nav3"
local mat4 = require "mat4"
local displaylist = require "displaylist"
local shader = require "shader"
local texture = require "texture"
local fbo = require "fbo"
local cubefbo = require "cubefbo"
local allosphere = require "allosphere"

local usefitting = true
local datapath = "/Users/grahamwakefield/code/calibration-current"
local projectors = {}

function import(filename)
	local f = C.open(filename, C.O_RDONLY)
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
			if usefitting then
				v = allosphere:capsuleFitting(v) 
			end
			
			data[idx].x = v.x
			data[idx].y = v.y
			data[idx].z = v.z
			
		end
	end
	C.close(f)
	
	return {
		width = w,
		height = h,
		elems = elems,
		
		map3D = data,
	}
end




local ptest = shader()
ptest:vertex[[
	varying vec4 C;
	void main (void) {  
		vec4 vertex = gl_ModelViewMatrix * gl_Vertex;
		// the ray direction vector for this pixel:
		vec3 d = normalize(gl_Vertex.xyz);
		gl_Position = gl_ProjectionMatrix * vertex;
		C = vec4(d * 0.5 + 0.5, 0.5);
	}
]]
ptest:fragment[[
	varying vec4 C;
	void main (void) {
		gl_FragColor = C;
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
	varying vec4 C;
	
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
	
	void main (void) {  
		vec4 vertex = gl_ModelViewMatrix * gl_Vertex;
		gl_Position = omni_render(vertex);
		C = gl_Color;
	}
]]
cubeCapture:fragment[[
	varying vec4 C;
	void main (void) {	
		gl_FragColor = C;
	}
]]

for i = 1, 6 do
	local self = import(string.format("%s/map3D%s.bin", datapath, i))
	
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
	projectors[i] = self
end

local fbos = fbo(512, 512, #projectors)
local cubefbos = cubefbo(1024, 1024)
nav3.pos.z = 10

local currentshader = showCube

function draw()
	-- always update nav: 
	nav3:update()
	
	-- offline capture a world into a cubeFBO:
	cubefbos:startcapture()
	for face = 0, 5 do
		cubefbos:face(face)
		gl.Enable(gl.DEPTH_TEST)
		gl.ClearColor(0.1,0,0)
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
		
		-- draw axes:
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
		
		cubeCapture:unbind()
	end
	cubefbos:endcapture()
	cubefbos:generatemipmap()
	
	
	gl.ClearColor(0,0,0)
	
	-- offline capturing:
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
				p.map3Dtex.internalformat = gl.RGB32F_ARB
				p.map3Dtex.type = gl.FLOAT
				p.map3Dtex.format = gl.RGBA
				p.map3Dtex.data = ffi.cast("float *", p.map3D)
			end
			
			currentshader:bind()
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
			
			currentshader:unbind()
		end	
	end)
	fbos:generatemipmap()	
		
	-- go 3D:
	gl.Viewport(0, 0, win.width, win.height)
	gl.MatrixMode(gl.PROJECTION)
	gl.LoadMatrix(mat4.perspective(60, win.width/win.height, 0.1, 100))
	gl.MatrixMode(gl.MODELVIEW)
	gl.LoadMatrix(mat4.lookatu(nav3.pos, nav3.ux, nav3.uy, nav3.uz))
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
	
	gl.Color(1,1,1, 0.5)
	allosphere:drawframe()
	
	-- render each projector:
	--ptest:bind()
	for i, p in ipairs(projectors) do
		fbos:bind(0, i)	
		p.quads:draw()
		fbos:unbind()
	end
	--ptest:unbind()
end

function update()

end

function keydown(k)
	if not nav3:keydown(k) then
		print(k)
	end
end

function keyup(k)
	nav3:keyup(k)
end
