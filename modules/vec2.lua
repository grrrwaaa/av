--- vec2: A simple 2-component vector

local sqrt = math.sqrt
local sin, cos = math.sin, math.cos
local atan2 = math.atan2
local acos = math.acos
local random = math.random
local pi = math.pi
local twopi = pi * 2
local format = string.format

--- Create a new vector with components x, y:
-- (Can also be used to duplicate a vector: vec2(v))
-- @param x number or vector (optional, default 0)
-- @param y number (optional, default 0)
function vec2(x, y) end

local vec2 = {}
vec2.__index = vec2

local function new(x, y)
	return setmetatable({ x = x, y = y }, vec2)
end

--- Create a copy of a vector:
-- @param v vector
function vec2.copy(v)
	return new(v.x, v.y)
end

--- Set the components of a vector:
-- @param x component
-- @param y component
-- @return self
function vec2:set(x, y)
	if type(x) == "number" or type(x) == "nil" then
		self.x = x or 0
		self.y = y or 0
	else
		self.x = x.x or 0
		self.y = x.y or 0
	end
	return self
end

--- Create a unit (length 1) vector from an angle
-- @param angle in radians
function vec2.fromAngle(angle)
	return new(cos(angle), sin(angle))	
end

--- Create a vector from a polar form length and angle
-- @param length magnitude
-- @param angle in radians
function vec2.fromPolar(length, angle)
	return new(length * cos(angle), length * sin(angle))	
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
		return new(a.x + b, a.y + b)
	elseif type(a) == "number" then
		return new(a + b.x, a + b.y)
	else
		return new(a.x + b.x, a.y + b.y)
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
		return new(a.x - b, a.y - b)
	elseif type(a) == "number" then
		return new(a - b.x, a - b.y)
	else
		return new(a.x - b.x, a.y - b.y)
	end
end
vec2.__sub = vec2.subnew

function vec2:__unm()
	return new(-self.x, -self.y)
end
	
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
		return new(a.x * b, a.y * b)
	elseif type(a) == "number" then
		return new(a * b.x, a * b.y)
	else
		return new(a.x * b.x, a.y * b.y)
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
		return new(a.x / b, a.y / b)
	elseif type(a) == "number" then
		return new(a / b.x, a / b.y)
	else
		return new(a.x / b.x, a.y / b.y)
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
		return new(a.x ^ b, a.y ^ b)
	elseif type(a) == "number" then
		return new(a ^ b.x, a ^ b.y)
	else
		return new(a.x ^ b.x, a.y ^ b.y)
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
		return new(a.x % b, a.y % b)
	elseif type(a) == "number" then
		return new(a % b.x, a % b.y)
	else
		return new(a.x % b.x, a.y % b.y)
	end
end
vec2.__mod = vec2.modnew

--- Determine shortest relative vector in a toroidal space
-- @param dimx width of space (optional, default 1)
-- @param dimy height of space (optional, default dimx)
-- @return self
function vec2:relativewrap(dimx, dimy)
	local dimx = dimx or 1
	local dimy = dimy or dimx
	local halfx = dimx * 0.5
	local halfy = dimy * 0.5
	self.x = ((self.x + halfx) % dimx) - halfx
	self.y = ((self.y + halfy) % dimy) - halfy
	return self
end

--- Create new vector as shortest relative vector in a toroidal space
-- @param dimx width of space (optional, default 1)
-- @param dimy height of space (optional, default dimx)
-- @return new vector
function vec2:relativewrapnew(dimx, dimy)
	return self:copy():relativewrap(dimx, dimy)
end

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

--- set the length of the vector to 1 (unit vector)
-- (randomized direction if self length was zero)
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

--- return a normalized copy of the vector 
-- (randomized direction if self length was zero)
-- @return vector of length 1 (unit vector)
function vec2:normalizenew()
	local r = self:length()
	if r > 0 then
		local div = 1 / r
		return new(self.x * div, self.y * div)
	else
		-- no particular direction; pick one at random!
		local a = random() * twopi
		return new(cos(a), sin(a))
	end
	return self
end

--- Impose a maximum magnitude
-- Rescales vector if greater than maximum
-- @param maximum maximum magnitude of vector
-- @return self
function vec2:limit(maximum)
	local m2 = self:dot(self)
	if m2 > maximum*maximum then
		self:mul(maximum / sqrt(m2))
	end
	return self
end

--- Create a copy of a vector, limited to a maximum magnitude
-- Rescales vector if greater than maximum
-- @param maximum maximum magnitude of vector
-- @return new vector
function vec2:limitnew(maximum)
	local m2 = self:dot(self)
	if m2 > maximum*maximum then
		return self * (maximum / sqrt(m2))
	end
	return self:copy()
end

--- Rotate a vector to a specific angle:
-- @param a new angle
-- @return self
function vec2:setangle(a)
	local scalar = self:length()
	self.x = scalar * cos(a)
	self.y = scalar * sin(a)
	return self
end

--- Return a copy rotated to a specific angle:
-- @param a new angle
-- @return new vector
function vec2:setanglenew(a)
	local scalar = self:length()
	return new(
		scalar * cos(a),
		scalar * sin(a)
	)
end

--- Rescale a vector to a specific magnitude:
-- @param m new magnitude
-- @return self
function vec2:setmag(m)
	local scalar = m / self:length()
	self.x = self.x * scalar
	self.y = self.y * scalar
	return self
end

--- Return a vector copy rescaled to a specific magnitude:
-- @param m new magnitude
-- @return new vector
function vec2:setmagnew(m)
	local scalar = m / self:length()
	return new(
		self.x * scalar,
		self.y * scalar
	)
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
	return new(
		self.x * c + self.y * s,
		self.y * c - self.x * s
	)
end

--- Create a new vector in a uniformly random direction:
-- @param mag magnitude (optional, default 1)
-- @return new vector
function vec2.random(mag)
	local a = random() * pi * 2
	return new(cos(a), sin(a)) * (mag or 1)
end

--- Set to a vector of magnitude 1 in a uniformly random direction:
-- @param mag magnitude (optional, default 1)
-- @return self
function vec2:randomize(mag)
	local a = random() * pi * 2
	self.x = cos(a) * (mag or 1)
	self.y = sin(a) * (mag or 1)
	return self
end

--- return the length of a vector
-- (Can also use #vector)
-- @return length
function vec2:length()
	return sqrt(self:dot(self))
end
vec2.__len = vec2.length

--- Return the angle to the vector (direction)
-- @return angle (in radians)
function vec2:angle()
	return atan2(self.y, self.x)
end

--- Return the magnitude and angle (polar form):
-- @return length, angle (in radians)
function vec2:polar()
	return self:length(), self:angle()
end

--- return the dot product of two vectors:
-- @param a vector
-- @param b vector
-- @return dot product
function vec2.dot(a, b)
	return a.x * b.x + a.y * b.y
end

--- The distance between two vectors (two points)
-- (The relative distance from self to p)
-- @param p target to measure distance to
-- @return distance
function vec2:distance(p)
	return (p - self):length()
end

--- The angle between two vectors (two points)
-- (The relative angle from self to v)
-- @param a vector to measure angle between
-- @param b vector to measure angle between
-- @return distance
function vec2.anglebetween(a, b)
	local am = a:length()
	local bm = b:length()
	return acos(a:dot(b) / (am * bm))
end

function vec2:__tostring()
	return format("vec2(%f, %f)", self.x, self.y)
end

function vec2.__eq(a, b) 
	return a.x==b.x and a.y==b.y
end

function vec2:unpack()
	return self.x, self.y
end

setmetatable(vec2, {
	__call = function(t, x, y)
		if type(x) == "number" then
			return new(x, y or 0)
		elseif x then
			-- copy an existing vector:
			return new(x.x, x.y)
		else
			-- create a default vector
			return new(0, 0)
		end
	end
})

return vec2