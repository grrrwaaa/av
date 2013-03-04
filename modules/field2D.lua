local ffi = require "ffi"

local field2D = {}
field2D.__index = field2D

function field2D:index(x, y)
	x = x and (x % self.dimx) or 0
	y = y and (y % self.dimy) or 0
	return y*dimx + x
end

function field2D:set(v, x, y)
	self.data[self:index(x, y)] = v or 0
	return self
end

function field2D:get(x, y)
	return self.data[self:index(x, y)]
end

-- NOTE: this leaves the texture bound
function field2D:send(unit)
	unit = unit or 0
	gl.BindTexture(gl.TEXTURE_2D + unit, self.texID)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.LUMINANCE, self.dimx, self.dimy, 0, gl.LUMINANCE, gl.FLOAT, self.data)
end

function field2D:bind(unit)
	unit = unit or 0
	if not self.texID then
		self.texID = gl.GenTextures(1)
		gl.BindTexture(gl.TEXTURE_2D, self.texID)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP)
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.LUMINANCE, self.dimx, self.dimy, 0, gl.LUMINANCE, gl.FLOAT, self.data)
	end
	gl.BindTexture(gl.TEXTURE_2D + unit, self.texID)
end

function field2D:unbind(unit)
	unit = unit or 0
	gl.BindTexture(gl.TEXTURE_2D + unit, 0)
end

return setmetatable(field2D, {
	__call = function(_, dimx, dimy)
		dimx = dimx or 64
		dimy = dimy or dimx
		local data = ffi.new("float[?]", dimx*dimy)
		
		return setmetatable({
			data = data,
			dimx = dimx,
			dimy = dimy,
		}, field2D)
	end,
})