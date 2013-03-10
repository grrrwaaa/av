local ffi = require "ffi"
local gl = require "gl"
local sketch = gl.sketch

local floor = math.floor

local field2D = {}
field2D.__index = field2D

function field2D:index(x, y)
	x = floor(x and (x % self.width) or 0)
	y = floor(y and (y % self.height) or 0)
	return y*self.width + x
end

function field2D:index_raw(x, y)
	return y*self.width + x
end

function field2D:set(v, x, y)
	local idx = self:index(x, y)
	self.data[idx] = v or 0
	return self
end

function field2D:get(x, y)
	return self.data[self:index(x, y)]
end

function field2D:clear()
	ffi.fill(self.data, self.size)
end

function field2D:apply(func)
	for y = 0, self.height-1 do
		for x = 0, self.width-1 do
			local v = func(x, y)
			if v then
				local idx = self:index_raw(x, y)
				self.data[idx] = v
				--print(x, y, idx, self.data[idx])
			end	
		end
	end
end

-- NOTE: this also leaves the texture bound
function field2D:send(unit)
	self:bind(unit)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.LUMINANCE, self.width, self.height, 0, gl.LUMINANCE, gl.FLOAT, self.data)
end

-- NOTE: this also leaves the texture bound
function field2D:draw(x, y, w, h, unit)
	self:send(unit)
	sketch.quad(x or 0, y or 0, w or 1, h or 1)
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
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.LUMINANCE, self.width, self.height, 0, gl.LUMINANCE, gl.FLOAT, self.data)
		gl.BindTexture(gl.TEXTURE_2D, 0)		
	end
end

function field2D:bind(unit)
	--gl.ActiveTexture(gl.TEXTURE0 + (unit or 0))
	self:create()
	
	gl.BindTexture(gl.TEXTURE_2D, self.texID)
end

function field2D:unbind(unit)
	--gl.ActiveTexture(gl.TEXTURE0 + (unit or 0))
	gl.BindTexture(gl.TEXTURE_2D, 0)
end

return setmetatable(field2D, {
	__call = function(_, dimx, dimy)
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
	end,
})