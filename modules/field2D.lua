--- Field2D: an object representing a 2D densely packed array.

local ffi = require "ffi"
local gl = require "gl"
local sketch = gl.sketch

local floor = math.floor

local field2D = {}
field2D.__index = field2D

function field2D:reduce(func, result)
	for y = 0, self.height-1 do
		for x = 0, self.width-1 do
			result = func(result, self.data[self:index_raw(x, y)], x, y)
		end
	end
	return result
end

-- e.g.:
function field2D:sum()
	return self:reduce(function(total, cell)
		return total + cell
	end, 0)
end

-- field:find(predicate), to return a list of coordinates usable by a range map?
-- gets closer to a jquery style of select -> apply (find -> map)

-- field:map(func)
-- field:map(func, 10, 10)
-- does it mean range 2..4 or only use indices 2,4 ? 
-- field:map(func, { 2, 4 }, { 4, 6 })
-- field:map(func, iterator)
--[[
function field2D:map(range, func)
	if func == nil then
		-- no range given, apply to whole field:
		return self:map(self, range)
	
	if type(range) == "function" then
		-- keep calling range() until nil:
		for x, y in range() do
			self:set(f(x, y), x, y)
		end
	else
		-- assume object:
		
	end
end
--]]
function field2D:index(x, y)
	x = floor(x and (x % self.width) or 0)
	y = floor(y and (y % self.height) or 0)
	return y*self.width + x
end

function field2D:index_raw(x, y)
	return y*self.width + x
end

--- set the value of a cell, or of all cells.
-- If the x,y coordinate is not specified, it will apply the value for all cells.
-- If the value to set is a function, this function is called (passing the x, y coordinates as arguments). If the function returns a value, the cell is set to this value; otherwise the cell is left unchanged.
-- @tparam number|function value to set
-- @tparam ?int x coordinate (row) to set a single cell
-- @tparam ?int y coordinate (column) to set a single cell
function field2D:set(value, x, y)
	if x then
		local idx = self:index(x, y or 0)
		self.data[idx] = (type(value) == "function" and value(x, y)) or (value and tonumber(value)) or 0
		return self
	elseif type(value) == "function" then
		for y = 0, self.height-1 do
			for x = 0, self.width-1 do
				local result = value(x, y)
				if result then
					local idx = self:index_raw(x, y)
					self.data[idx] = result
				end	
			end
		end
	else
		value = value and tonumber(value) or 0
		for y = 0, self.height-1 do
			for x = 0, self.width-1 do
				local idx = self:index_raw(x, y)
				self.data[idx] = value
			end
		end
	end
	return self
end

--- return the value of a cell
-- If x or y is out of range of the field, it wraps around (positive modulo)
-- If x or y are not integers, the fractional component is discarded (rounded down)
-- @tparam ?int x coordinate (row) to get a single cell
-- @tparam ?int y coordinate (column) to get a single cell
function field2D:get(x, y)
	return self.data[self:index(x, y)]
end

--- return the value at a normalized index (0..1 range maps to field dimensions)
-- Uses linear interpolation between nearest cells.
-- Indexes out of range will wrap.
-- @param x coordinate (0..1) to sample
-- @param y coordinate (0..1) to sample
function field2D:sample(x, y)
	assert(x, "missing x coordinate for sampling")
	assert(y, "missing y coordinate for sampling")
	local x = x and ((x * self.width) % self.width) or 0
	local y = y and ((y * self.height) % self.height) or 0
	local x0 = floor(x)
	local y0 = floor(y)
	local x1 = (x0 + 1) % self.width
	local y1 = (y0 + 1) % self.height
	local xb = x - x0
	local yb = y - y0
	local xa = 1 - xb
	local ya = 1 - yb
	local v00 = self.data[self:index_raw(x0, y0)]
	local v10 = self.data[self:index_raw(x1, y0)]
	local v01 = self.data[self:index_raw(x0, y1)]
	local v11 = self.data[self:index_raw(x1, y1)]
	return v00 * xa * ya
		 + v10 * xb * ya
		 + v01 * xa * yb
		 + v11 * xb * yb
end

--- fill the field with a diffused copy of another
function field2D:diffuse(sourcefield, diffusion, passes)
	passes = passes or 10
	
	local optr = self.data
	local iptr = sourcefield.data
	--local div = 1.0/((1.+6.*diffusion))
	local div = 1.0/((1.+4.*diffusion))
	
	local w, h = sourcefield.width, sourcefield.height
	
	-- Gauss-Seidel relaxation scheme:
	for n = 1, passes do
		--for z = 0, self.dim.z-1 do
			for y = 0, h-1 do
				for x = 0, w-1 do
					local pre =	iptr[self:index_raw(x, y)]
					local va0 =	optr[self:index(x-1,y  )]
					local vb0 =	optr[self:index(x+1,y  )]
					local v0a =	optr[self:index(x,	y-1)]
					local v0b =	optr[self:index(x,	y+1)]
					--[[
					local pre  =	iptr[self:index(x,	y,	z  )]
					local va00 =	optr[self:index(x-1,y,	z  )]
					local vb00 =	optr[self:index(x+1,y,	z  )]
					local v0a0 =	optr[self:index(x,	y-1,z  )]
					local v0b0 =	optr[self:index(x,	y+1,z  )]
					local v00a =	optr[self:index(x,	y,	z-1)]
					local v00b =	optr[self:index(x,	y,	z+1)]
					--]]
					optr[self:index(x,y,z)] = div*(
						pre +
						diffusion * (
							va0 + vb0 +
							v0a + v0b
						)
					)
				end
			end
		--end
	end
end

function field2D:clear()
	ffi.fill(self.data, self.size)
end

function field2D:map(func)
	for y = 0, self.height-1 do
		for x = 0, self.width-1 do
			local idx = self:index_raw(x, y)
			local v = func(self.data[idx], x, y)
			if v then
				self.data[idx] = v
				--print(x, y, idx, self.data[idx])
			end	
		end
	end
end

--- Draw the field in greyscale from 0..1
-- @param x left coordinate (optional, defaults to 0)
-- @param y bottom coordinate (optional, defaults to 0)
-- @param w width (optional, defaults to 1)
-- @param h height (optional, defaults to 1)
-- @param unit texture unit to use (defaults to 0)
function field2D:draw(x, y, w, h, unit)
	self:send(unit)
	sketch.quad(x or 0, y or 0, w or 1, h or 1)
	self:unbind(unit)
end

--- Draw the field as a Hue spectrum from red to blue
-- @param range the maximum field value (renders as blue) 
function field2D:drawHueRange(range) end
field2D.drawHueRange = (function()
	local program = nil
	local program_scale = 0
	return function(self, range)
		if not program then
			local vert = gl.CreateVertexShader[[
			varying vec2 T;
			void main() {
				T = vec2(gl_MultiTexCoord0);
				gl_Position = vec4(T*2.-1., 0, 1);
			}
			
			]]
			local frag = gl.CreateFragmentShader[[
			uniform sampler2D tex;
			uniform float scale;
			varying vec2 T;
			
			vec3 hsv(float h,float s,float v) { 
				vec3 rgb = abs(fract(h+vec3(3.,2.,1.)/3.)*6.-3.) - 1.;
				return v * mix(vec3(1.), clamp(rgb,0.,1.), s); 
			}
			
			void main() {
				float v = texture2D(tex, T).x;
				// convert to HSV:
				vec3 rgb = hsv(v * 6. * scale, 0.75, 1.);
				gl_FragColor = vec4(rgb, 1);
			}
			
			]]
			program = gl.Program(vert, frag)
			gl.assert("creating shader")
			gl.UseProgram(program)
			program_scale = gl.GetUniformLocation(program, "scale")
			gl.assert("binding shader")
		else
			gl.UseProgram(program)
		end
		
		gl.Uniformf(program_scale, 1/(range or 1))
		self:send(0)
		sketch.quad(0, 0, 1, 1)
		gl.UseProgram(0)
		self:unbind(unit)
	end
end)()

field2D.drawRGB = (function()
	local program = nil
	local program_r = 0
	local program_g = 0
	local program_b = 0
	return function(red, green, blue)
		assert(red, "missing field arguments (requires 3 fields)")
		assert(green, "missing field arguments (requires 3 fields)")
		assert(blue, "missing field arguments (requires 3 fields)")
		if not program then
			local vert = gl.CreateVertexShader[[
			varying vec2 T;
			void main() {
				T = vec2(gl_MultiTexCoord0);
				vec4 pos = vec4(T*2.-1., 0, 1);
				gl_Position = pos;
			}
			
			]]
			local frag = gl.CreateFragmentShader[[
			uniform sampler2D red;
			uniform sampler2D green;
			uniform sampler2D blue;
			varying vec2 T;
			
			void main() {
				float r = texture2D(red, T).x;
				float g = texture2D(green, T).x;
				float b = texture2D(blue, T).x;
				
				gl_FragColor = vec4(r, g, b, 1); //vec4(r, g, b, 1);
			}
			
			]]
			program = gl.Program(vert, frag)
			gl.assert("creating shader")
			gl.UseProgram(program)
			program_r = gl.GetUniformLocation(program, "red")
			program_g = gl.GetUniformLocation(program, "green")
			program_b = gl.GetUniformLocation(program, "blue")	
			gl.assert("binding shader")
		else
			gl.UseProgram(program)
		end
		
		blue:send(2)
		green:send(1)
		red:send(0)
			gl.Uniformi(program_r, 0)
			gl.Uniformi(program_g, 1)
			gl.Uniformi(program_b, 2)		
		sketch.quad(0, 0, 1, 1)
		gl.UseProgram(0)
		blue:unbind(2)
		green:unbind(1)
		red:unbind(0)
	end
end)()

field2D.drawWeird = (function()
	local program = nil
	local program_scale = 0
	return function(self, range)
		if not program then
			local vert = gl.CreateVertexShader[[
			uniform sampler2D tex;
			varying vec2 T;
			void main() {
				T = vec2(gl_MultiTexCoord0);
				float v = texture2D(tex, T).x;
				vec4 pos = vec4(T*2.-1., 0, 1);
				//pos.z = -v * 0.1;
				gl_Position = pos;
			}
			
			]]
			local frag = gl.CreateFragmentShader[[
			uniform sampler2D tex;
			uniform float scale;
			varying vec2 T;
			
			vec3 hsv(float h,float s,float v) { 
				vec3 rgb = abs(fract(h+vec3(3.,2.,1.)/3.)*6.-3.) - 1.;
				return v * mix(vec3(1.), clamp(rgb,0.,1.), s); 
			}
			
			void main() {
				float v = texture2D(tex, T).x;
				// convert to HSV:
				vec3 rgb = hsv(v * 6. * scale, 0.75, 1.);
				gl_FragColor = vec4(rgb, 1);
			}
			
			]]
			program = gl.Program(vert, frag)
			gl.assert("creating shader")
			gl.UseProgram(program)
			program_scale = gl.GetUniformLocation(program, "scale")
			gl.assert("binding shader")
		else
			gl.UseProgram(program)
		end
		
		gl.Uniformf(program_scale, 1/(range or 1))
		self:send(0)
		-- draw as a big mesh
		local xstep = 1/self.width
		local ystep = 1/self.height
		for x = 0, 1, xstep do
			gl.Begin(gl.QUAD_STRIP)
			for y = 0, 1, ystep do
				gl.TexCoord(x, y)
				gl.Vertex(x, y)
				gl.TexCoord(x+xstep, y)
				gl.Vertex(x+xstep, y)
			end
			gl.End()
		end
		--sketch.quad(0, 0, 1, 1)
		gl.UseProgram(0)
		self:unbind(unit)
	end
end)()

-- NOTE: this also leaves the texture bound
function field2D:send(unit)
	self:bind(unit)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.LUMINANCE32F_ARB, self.width, self.height, 0, gl.LUMINANCE, gl.FLOAT, self.data)
end

function field2D:create()
	-- turn this one even if we already created it.
	gl.Enable(gl.TEXTURE_2D)
		
	if not self.texID then
		self.texID = gl.GenTextures(1)
		gl.BindTexture(gl.TEXTURE_2D, self.texID)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP)
		self:send()	
		gl.BindTexture(gl.TEXTURE_2D, 0)	
	end
end

function field2D:bind(unit)
	gl.ActiveTexture(gl.TEXTURE0 + (unit or 0))
	self:create()
	
	gl.BindTexture(gl.TEXTURE_2D, self.texID)
end

function field2D:unbind(unit)
	gl.ActiveTexture(gl.TEXTURE0 + (unit or 0))
	gl.BindTexture(gl.TEXTURE_2D, 0)
end


function field2D.new(dimx, dimy)
	dimx = dimx or 64
	dimy = dimy or dimx
	local data = ffi.new("float[?]", dimx*dimy)
	
	return setmetatable({
		data = data,
		-- dimensions:
		dim = { dimx, dimy },
		-- human-readable...
		width = dimx,
		height = dimy,
		-- size in bytes:
		size = ffi.sizeof(data),
	}, field2D)
end

--- Create a copy of the field with the same dimensions and contents
function field2D:copy()
	local f2 = field2D.new(self.width, self.height)
	-- copy data:
	ffi.copy(self.data, f2.data, f2.size)
	return f2
end

return setmetatable(field2D, {
	__call = function(_, ...)
		return field2D.new(...)
	end,
})