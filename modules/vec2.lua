--- vec2: A simple 2-component vector

local sqrt = math.sqrt
local sin, cos = math.sin, math.cos
local atan2 = math.atan2
local random = math.random
local pi = math.pi
local twopi = pi * 2
local format = string.format

--- Create a new vector with components x, y:
-- @param x number (optional, default 0)
-- @param y number (optional, default 0)
function vec2(x, y) end

local vec2 = {}
vec2.__index = vec2

function vec2.new(x, y)
	return setmetatable({ x = x or 0, y = y or x or 0 }, vec2)
end

--- Create a copy of a vector:
-- @param v vector
function vec2.copy(v)
	return vec2.new(v.x, v.y)
end

--- Create a new vector of magnitude 1 in a uniformly random direction:
-- @return new vector
function vec2.random()
	local a = random() * pi * 2
	return vec2.new(cos(a), sin(a))
end

--- Create a vector from a polar form length and angle
-- @param length magnitude
-- @param angle in radians
function vec2.fromPolar(length, angle)
	return vec2.new(length * cos(angle), length * sin(angle))	
end

--- Add a vector (or number) to self (in-place)
-- @param v number or vector to add
-- @return self
function vec2:add(v)
	if type(v) == "number" then
		self.x = self.x + v
		self.y = self.y + v
		return self
	else
		self.x = self.x + v.x
		self.y = self.y + v.y
		return self
	end
end

--- Add two vectors (or numbers) to create a new vector
-- @param a vector or number
-- @param b vector or number
-- @return new vector
function vec2.addnew(a, b)
	if type(b) == "number" then
		return vec2.new(a.x + b, a.y + b)
	elseif type(a) == "number" then
		return vec2.new(a + b.x, a + b.y)
	else
		return vec2.new(a.x + b.x, a.y + b.y)
	end
end
vec2.__add = vec2.addnew
	
--- Subtract a vector (or number) to self (in-place)
-- @param v number or vector to sub
-- @return self
function vec2:sub(v)
	if type(v) == "number" then
		self.x = self.x - v
		self.y = self.y - v
		return self
	else
		self.x = self.x - v.x
		self.y = self.y - v.y
		return self
	end
end

--- Subtract two vectors (or numbers) to create a new vector
-- @param a vector or number
-- @param b vector or number
-- @return new vector
function vec2.subnew(a, b)
	if type(b) == "number" then
		return vec2.new(a.x - b, a.y - b)
	elseif type(a) == "number" then
		return vec2.new(a - b.x, a - b.y)
	else
		return vec2.new(a.x - b.x, a.y - b.y)
	end
end
vec2.__sub = vec2.subnew
	
--- Multiply a vector (or number) to self (in-place)
-- @param v number or vector to mul
-- @return self
function vec2:mul(v)
	if type(v) == "number" then
		self.x = self.x * v
		self.y = self.y * v
		return self
	else
		self.x = self.x * v.x
		self.y = self.y * v.y
		return self
	end
end

--- Multiply two vectors (or numbers) to create a new vector
-- @param a vector or number
-- @param b vector or number
-- @return new vector
function vec2.mulnew(a, b)
	if type(b) == "number" then
		return vec2.new(a.x * b, a.y * b)
	elseif type(a) == "number" then
		return vec2.new(a * b.x, a * b.y)
	else
		return vec2.new(a.x * b.x, a.y * b.y)
	end
end
vec2.__mul = vec2.mulnew
	
--- Divide a vector (or number) to self (in-place)
-- @param v number or vector to div
-- @return self
function vec2:div(v)
	if type(v) == "number" then
		self.x = self.x / v
		self.y = self.y / v
		return self
	else
		self.x = self.x / v.x
		self.y = self.y / v.y
		return self
	end
end

--- Divide two vectors (or numbers) to create a new vector
-- @param a vector or number
-- @param b vector or number
-- @return new vector
function vec2.divnew(a, b)
	if type(b) == "number" then
		return vec2.new(a.x / b, a.y / b)
	elseif type(a) == "number" then
		return vec2.new(a / b.x, a / b.y)
	else
		return vec2.new(a.x / b.x, a.y / b.y)
	end
end
vec2.__div = vec2.divnew
	
--- Raise to power a vector (or number) to self (in-place)
-- @param v number or vector to pow
-- @return self
function vec2:pow(v)
	if type(v) == "number" then
		self.x = self.x ^ v
		self.y = self.y ^ v
		return self
	else
		self.x = self.x ^ v.x
		self.y = self.y ^ v.y
		return self
	end
end

--- Raise to power two vectors (or numbers) to create a new vector
-- @param a vector or number
-- @param b vector or number
-- @return new vector
function vec2.pownew(a, b)
	if type(b) == "number" then
		return vec2.new(a.x ^ b, a.y ^ b)
	elseif type(a) == "number" then
		return vec2.new(a ^ b.x, a ^ b.y)
	else
		return vec2.new(a.x ^ b.x, a.y ^ b.y)
	end
end
vec2.__pow = vec2.pownew
	
--- Calculate modulo a vector (or number) to self (in-place)
-- @param v number or vector to mod
-- @return self
function vec2:mod(v)
	if type(v) == "number" then
		self.x = self.x % v
		self.y = self.y % v
		return self
	else
		self.x = self.x % v.x
		self.y = self.y % v.y
		return self
	end
end

--- Calculate modulo two vectors (or numbers) to create a new vector
-- @param a vector or number
-- @param b vector or number
-- @return new vector
function vec2.modnew(a, b)
	if type(b) == "number" then
		return vec2.new(a.x % b, a.y % b)
	elseif type(a) == "number" then
		return vec2.new(a % b.x, a % b.y)
	else
		return vec2.new(a.x % b.x, a.y % b.y)
	end
end
vec2.__mod = vec2.modnew


--- interpolate from self to v by factor of f
-- @param v vector
-- @param f interpolation factor from self to v (0 = none, 1 = full)
-- @return self
function vec2:lerp(v, f)
	return self:add(v:sub(self):mul(f))
end

--- create a vector from the linear interpolation of two vectors:
-- @param a vector
-- @param b vector
-- @param f interpolation factor from a to b (0 = none, 1 = full)
-- @return new vector
function vec2.lerpnew(a, b, f)
	return a + (b - a) * f
end

--- return the dot product of two vectors:
-- @param a vector
-- @param b vector
-- @return dot product
function vec2.dot(a, b)
	return a.x * b.x + a.y * b.y
end

--- return the length of a vector
-- @return length
function vec2:length()
	return sqrt(self:dot(self))
end
vec2.__len = vec2.length

--- set the length of the vector to 1 (unit vector)
-- @return self
function vec2:normalize()
	local r = self:length()
	if r > 0 then
		local div = 1 / r
		self.x = self.x * div
		self.y = self.y * div
	else
		-- no particular direction; pick one at random!
		local a = random() * twopi
		self.x = cos(a)
		self.y = sin(a)
	end
	return self
end

--- Rotate a vector by an angle
-- @param angle in radians
-- @return self
function vec2:rotate(angle)
	local c = cos(angle)
	local s = sin(angle)
	local x, y = self.x, self.y
	self.x = v.x * c + v.y * s
	self.y = v.y * c - v.x * s
	return self
end

--- Create a vector by rotating a vector by an angle
-- @param angle in radians
-- @return new vector
function vec2:rotatenew(angle)
	local c = cos(angle)
	local s = sin(angle)
	return vec2.new(
		self.x * c + self.y * s,
		self.y * c - self.x * s
	)
end

--- Return the magnitude and angle (polar form):
-- @return length, angle (in radians)
function vec2:polar()
	local r = self:length()
	local t = atan2(self.y, self.x)
	return r, t
end

function vec2:__tostring()
	return format("vec2(%f, %f)", self.x, self.y)
end

setmetatable(vec2, {
	__call = function(t, x, y)
		return vec2.new(x, y)
	end
})

return vec2