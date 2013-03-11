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
				local idx = self:index_raw(x, y)
				local result = value(x, y)
				if result then
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

function field2D:get(x, y)
	return self.data[self:index(x, y)]
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

function field2D:copy()
	local f2 = field2D.new(self.width, self.height)
	-- copy data:
	ffi.copy(self.data, f2.data, f2.size)
	return f2
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

return setmetatable(field2D, {
	__call = function(_, ...)
		return field2D.new(...)
	end,
})