--- Field3D: an object representing a 3D densely packed array.

local ffi = require "ffi"
local gl = require "gl"
local sketch = gl.sketch

local floor = math.floor

local field3D = {}
field3D.__index = field3D



function field3D:index(x, y, z)
	x = floor(x and (x % self.width) or 0)
	y = floor(y and (y % self.height) or 0)
	z = floor(z and (z % self.depth) or 0)
	return z*self.height*self.width + y*self.width + x
end

function field3D:index_raw(x, y, z)
	return z*self.height*self.width + y*self.width + x
end


--- set the value of a cell, or of all cells.
-- If the x,y,z coordinate is not specified, it will apply the value for all cells.
-- If the value to set is a function, this function is called (passing the x, y, z coordinates as arguments). If the function returns a value, the cell is set to this value; otherwise the cell is left unchanged.
-- @tparam number|function value to set
-- @tparam ?int x coordinate (row) to set a single cell
-- @tparam ?int y coordinate (column) to set a single cell
-- @tparam ?int z coordinate (layer) to set a single cell
function field3D:set(value, x, y, z)
	if x then
		local idx = self:index(x, y or 0, z or 0)
		self.data[idx] = (type(value) == "function" and value(x, y, z)) or (value and tonumber(value)) or 0
		return self
	elseif type(value) == "function" then
		for z = 0, self.depth-1 do
			for y = 0, self.height-1 do
				for x = 0, self.width-1 do
					local idx = self:index_raw(x, y, z)
					local result = value(x, y, z)
					if result then
						self.data[idx] = result
					end	
				end
			end
		end
	else
		value = value and tonumber(value) or 0
		for z = 0, self.depth-1 do
			for y = 0, self.height-1 do
				for x = 0, self.width-1 do
					local idx = self:index_raw(x, y, z)
					self.data[idx] = value
				end
			end
		end
	end
	return self
end

function field3D:get(x, y, z)
	return self.data[self:index(x, y, z)]
end

function field3D:clear()
	ffi.fill(self.data, self.size)
end

function field3D:map(func)
	for z = 0, self.depth-1 do
		for y = 0, self.height-1 do
			for x = 0, self.width-1 do
				local idx = self:index_raw(x, y, z)
				local v = func(self.data[idx], x, y, z)
				if v then
					self.data[idx] = v
				end	
			end
		end
	end
end

--[[
-- NOTE: this also leaves the texture bound
function field3D:draw(x, y, w, h, unit)
	self:send(unit)
	sketch.quad(x or 0, y or 0, w or 1, h or 1)
end
--]]

-- NOTE: this also leaves the texture bound
function field3D:send(unit)
	self:bind(unit)
	gl.TexImage3D(
		gl.TEXTURE_3D, 0, 
		gl.LUMINANCE32F_ARB, 
		self.width, self.height, self.depth, 
		self.border, gl.LUMINANCE, 
		gl.FLOAT, self.data)
end

function field3D:destroy()
	gl.DeleteTextures(self.texID)
	self.texID = nil
end

function field3D:create()
	-- turn this one even if we already created it.
	gl.Enable(gl.TEXTURE_3D)
		
	if not self.texID then
		self.texID = gl.GenTextures(1)
		gl.BindTexture(gl.TEXTURE_3D, self.texID)
		if self.drawsmooth then
			gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
			gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
		else
			gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
			gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
		end		
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_S, gl.CLAMP)
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_T, gl.CLAMP)
		gl.TexParameteri(gl.TEXTURE_3D, gl.TEXTURE_WRAP_R, gl.CLAMP)
		self:send()	
		gl.BindTexture(gl.TEXTURE_3D, 0)	
	end
end

function field3D:bind(unit)
	gl.ActiveTexture(gl.TEXTURE0 + (unit or 0))
	self:create()
	
	gl.BindTexture(gl.TEXTURE_3D, self.texID)
end

function field3D:unbind(unit)
	gl.ActiveTexture(gl.TEXTURE0 + (unit or 0))
	gl.BindTexture(gl.TEXTURE_3D, 0)
end

function field3D:copy()
	local f2 = field3D.new(self.width, self.height, self.depth)
	-- copy data:
	ffi.copy(self.data, f2.data, f2.size)
	return f2
end

function field3D.new(dimx, dimy, dimz)
	dimx = dimx or 64
	dimy = dimy or dimx
	dimz = dimz or dimy
	local data = ffi.new("float[?]", dimx*dimy*dimz)
	
	return setmetatable({
		data = data,
		-- dimensions:
		dim = { dimx, dimy, dimz, },
		-- human-readable...
		width = dimx,
		height = dimy,
		depth = dimz,
		
		border = 0,
		drawsmooth = true,
		-- size in bytes:
		size = ffi.sizeof(data),
	}, field3D)
end

return setmetatable(field3D, {
	__call = function(_, ...)
		return field3D.new(...)
	end,
})