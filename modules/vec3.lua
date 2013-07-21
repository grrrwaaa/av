--- vec3: A simple 3-component vector

local sqrt = math.sqrt
local sin, cos = math.sin, math.cos
local atan2 = math.atan2
local acos = math.acos
local floor = math.floor
local random = math.random
local min, max = math.min, math.max
local pi = math.pi
local twopi = pi * 2
local format = string.format

local ffi = require "ffi"
ffi.cdef [[ 

typedef struct vec3f {
	float x, y, z;
} vec3f;
typedef struct vec3d {
	double x, y, z;
} vec3d;
typedef vec3d vec3;

]]

--- Create a new vector with components x, y, z:
-- (Can also be used to duplicate a vector: vec3(v))
-- @param x number or vector (optional, default 0)
-- @param y number (optional, default 0)
-- @param z number (optional, default 0)
function vec3(x, y, z) end

local vec3 = {}
vec3.__index = vec3

local function new(x, y, z)
	--return setmetatable({ x = x, y = y, z = z }, vec3)
	return ffi.new("vec3", x, y, z)
end

--- Create a copy of a vector:
-- @param v vector
function vec3.copy(v)
	return new(v.x, v.y, v.z)
end

--- Create a copy of a vec2 vector:
-- @param v vec3
-- @param z number
function vec3.fromvec2(v, z)
	return new(v.x, v.y, z or 0)
end

--- Set the components of a vector:
-- @param x component
-- @param y component
-- @param z component
-- @return self
function vec3:set(x, y, z)
	if type(x) == "number" or type(x) == "nil" then
		self.x = x or 0
		self.y = y or 0
		self.z = z or 0
	else
		self.x = x.x or 0
		self.y = x.y or 0
		self.z = x.z or 0
	end
	return self
end

-- TODO: from axis angle
-- TODO: from quat

--- Add a vector (or number) to self (in-place)
-- @param v number or vector to add
-- @return self
function vec3:add(v)
	if type(v) == "number" then
		self.x = self.x + v
		self.y = self.y + v
		self.z = self.z + v
		return self
	else
		self.x = self.x + v.x
		self.y = self.y + v.y
		self.z = self.z + v.z
		return self
	end
end

--- Add two vectors (or numbers) to create a new vector
-- @param a vector or number
-- @param b vector or number
-- @return new vector
function vec3.addnew(a, b)
	if type(b) == "number" then
		return new(a.x + b, a.y + b, a.z + b)
	elseif type(a) == "number" then
		return new(a + b.x, a + b.y, a + b.z)
	else
		return new(a.x + b.x, a.y + b.y, a.z + b.z)
	end
end
vec3.__add = vec3.addnew
	
--- Subtract a vector (or number) to self (in-place)
-- @param v number or vector to sub
-- @return self
function vec3:sub(v)
	if type(v) == "number" then
		self.x = self.x - v
		self.y = self.y - v
		self.z = self.z - v
		return self
	else
		self.x = self.x - v.x
		self.y = self.y - v.y
		self.z = self.z - v.z
		return self
	end
end

--- Subtract two vectors (or numbers) to create a new vector
-- @param a vector or number
-- @param b vector or number
-- @return new vector
function vec3.subnew(a, b)
	if type(b) == "number" then
		return new(a.x - b, a.y - b, a.z - b)
	elseif type(a) == "number" then
		return new(a - b.x, a - b.y, a - b.z)
	else
		return new(a.x - b.x, a.y - b.y, a.z - b.z)
	end
end
vec3.__sub = vec3.subnew
	
function vec3:__unm()
	return new(-self.x, -self.y, -self.z)
end	

--- Multiply a vector (or number) to self (in-place)
-- @param v number or vector to mul
-- @return self
function vec3:mul(v)
	if type(v) == "number" then
		self.x = self.x * v
		self.y = self.y * v
		self.z = self.z * v
		return self
	else
		self.x = self.x * v.x
		self.y = self.y * v.y
		self.z = self.z * v.z
		return self
	end
end

--- Multiply two vectors (or numbers) to create a new vector
-- @param a vector or number
-- @param b vector or number
-- @return new vector
function vec3.mulnew(a, b)
	if type(b) == "number" then
		return new(a.x * b, a.y * b, a.z * b)
	elseif type(a) == "number" then
		return new(a * b.x, a * b.y, a * b.z)
	else
		return new(a.x * b.x, a.y * b.y, a.z * b.z)
	end
end
vec3.__mul = vec3.mulnew
	
--- Divide a vector (or number) to self (in-place)
-- @param v number or vector to div
-- @return self
function vec3:div(v)
	if type(v) == "number" then
		self.x = self.x / v
		self.y = self.y / v
		self.z = self.z / v
		return self
	else
		self.x = self.x / v.x
		self.y = self.y / v.y
		self.z = self.z / v.z
		return self
	end
end

--- Divide two vectors (or numbers) to create a new vector
-- @param a vector or number
-- @param b vector or number
-- @return new vector
function vec3.divnew(a, b)
	if type(b) == "number" then
		return new(a.x / b, a.y / b, a.z / b)
	elseif type(a) == "number" then
		return new(a / b.x, a / b.y, a / b.z)
	else
		return new(a.x / b.x, a.y / b.y, a.z / b.z)
	end
end
vec3.__div = vec3.divnew
	
--- Raise to power a vector (or number) to self (in-place)
-- @param v number or vector to pow
-- @return self
function vec3:pow(v)
	if type(v) == "number" then
		self.x = self.x ^ v
		self.y = self.y ^ v
		self.z = self.z ^ v
		return self
	else
		self.x = self.x ^ v.x
		self.y = self.y ^ v.y
		self.z = self.z ^ v.z
		return self
	end
end

--- Raise to power two vectors (or numbers) to create a new vector
-- @param a vector or number
-- @param b vector or number
-- @return new vector
function vec3.pownew(a, b)
	if type(b) == "number" then
		return new(a.x ^ b, a.y ^ b, a.z ^ b)
	elseif type(a) == "number" then
		return new(a ^ b.x, a ^ b.y, a ^ b.z)
	else
		return new(a.x ^ b.x, a.y ^ b.y, a.z ^ b.z)
	end
end
vec3.__pow = vec3.pownew
	
--- Calculate modulo a vector (or number) to self (in-place)
-- @param v number or vector to mod
-- @return self
function vec3:mod(v)
	if type(v) == "number" then
		self.x = self.x % v
		self.y = self.y % v
		self.z = self.z % v
		return self
	else
		self.x = self.x % v.x
		self.y = self.y % v.y
		self.z = self.z % v.z
		return self
	end
end

--- Calculate modulo two vectors (or numbers) to create a new vector
-- @param a vector or number
-- @param b vector or number
-- @return new vector
function vec3.modnew(a, b)
	if type(b) == "number" then
		return new(a.x % b, a.y % b, a.z % b)
	elseif type(a) == "number" then
		return new(a % b.x, a % b.y, a % b.z)
	else
		return new(a.x % b.x, a.y % b.y, a.z % b.z)
	end
end
vec3.__mod = vec3.modnew

--- Apply math.floor to all elements:
-- @return self
function vec3:floor()
	self.x = floor(self.x)
	self.y = floor(self.y)
	self.z = floor(self.z)
	return self
end

--- Calculate minimum of elements (in-place)
-- @param v number or vector limit
-- @return self
function vec3:min(v)
	if type(v) == "number" then
		self.x = min(self.x, v)
		self.y = min(self.y, v)
		self.z = min(self.z, v)
		return self
	else
		self.x = min(self.x, v.x)
		self.y = min(self.y, v.y)
		self.z = min(self.z, v.z)
		return self
	end
end

--- Calculate minimum of elements to create a new vector
-- @param a vector or number
-- @param b vector or number
-- @return new vector
function vec3.minnew(a, b)
	if type(b) == "number" then
		return new(min(a.x, b), min(a.y, b), min(a.z, b))
	elseif type(a) == "number" then
		return new(min(a, b.x), min(a, b.y), min(a, b.z))
	else
		return new(min(a.x, b.x), min(a.y, b.y), min(a.z, b.z)) 
	end
end

--- Calculate maximum of elements (in-place)
-- @param v number or vector limit
-- @return self
function vec3:max(v)
	if type(v) == "number" then
		self.x = max(self.x, v)
		self.y = max(self.y, v)
		self.z = max(self.z, v)
		return self
	else
		self.x = max(self.x, v.x)
		self.y = max(self.y, v.y)
		self.z = max(self.z, v.z)
		return self
	end
end

--- Calculate maximum of elements to create a new vector
-- @param a vector or number
-- @param b vector or number
-- @return new vector
function vec3.maxnew(a, b)
	if type(b) == "number" then
		return new(max(a.x, b), max(a.y, b), max(a.z, b))
	elseif type(a) == "number" then
		return new(max(a, b.x), max(a, b.y), max(a, b.z))
	else
		return new(max(a.x, b.x), max(a.y, b.y), max(a.z, b.z)) 
	end
end

--- Constrain vector to range (in-place)
-- @param lo vector or number minimum value 
-- @param hi vector or number minimum value 
-- @return self
function vec3:clip(lo, hi)
	return self:max(lo):min(hi)
end

--- Constrain vector to range to create a new vector
-- @param lo vector or number minimum value 
-- @param hi vector or number minimum value 
-- @return new vector
function vec3:clip(lo, hi)
	return self:maxnew(lo):min(hi)
end

--- Determine shortest relative vector in a toroidal space
-- @param dimx width of space (optional, default 1)
-- @param dimy height of space (optional, default dimx)
-- @param dimz depth of space (optional, default dimx)
-- @return self
function vec3:relativewrap(dimx, dimy, dimz)
	local dimx = dimx or 1
	local dimy = dimy or dimx
	local dimz = dimz or dimx
	local halfx = dimx * 0.5
	local halfy = dimy * 0.5
	local halfz = dimz * 0.5
	self.x = ((self.x + halfx) % dimx) - halfx
	self.y = ((self.y + halfy) % dimy) - halfy
	self.z = ((self.z + halfz) % dimz) - halfz
	return self
end

--- Create new vector as shortest relative vector in a toroidal space
-- @param dimx width of space (optional, default 1)
-- @param dimy height of space (optional, default dimx)
-- @return new vector
function vec3:relativewrapnew(dimx, dimy)
	return self:copy():relativewrap(dimx, dimy)
end

--- interpolate from self to v by factor of f
-- @param v vector
-- @param f interpolation factor from self to v (0 = none, 1 = full)
-- @return self
function vec3:lerp(v, f)
	return self:add(v:sub(self):mul(f))
end

--- create a vector from the linear interpolation of two vectors:
-- @param a vector
-- @param b vector
-- @param f interpolation factor from a to b (0 = none, 1 = full)
-- @return new vector
function vec3.lerpnew(a, b, f)
	return a + (b - a) * f
end

--- set the length of the vector to 1 (unit vector)
-- (randomized direction if self length was zero)
-- @return self
function vec3:normalize()
	local r = self:length()
	if r > 0 then
		local div = 1 / r
		self.x = self.x * div
		self.y = self.y * div
		self.z = self.z * div
	else
		-- no particular direction; pick one at random!
		local a = random() * twopi
		local z = random() * 2 - 1
		local d = sqrt(1 - z*z)
		self.x = d * cos(a)
		self.y = d * sin(a)
		self.z = z
	end
	return self
end

--- return a normalized copy of the vector 
-- (randomized direction if self length was zero)
-- @return vector of length 1 (unit vector)
function vec3:normalizenew()
	local r = self:length()
	if r > 0 then
		local div = 1 / r
		return new(self.x * div, self.y * div, self.z * div)
	else
		-- no particular direction; pick one at random!
		local a = random() * twopi
		local z = random() * 2 - 1
		local d = sqrt(1 - z*z)
		return new(d * cos(a), d * sin(a), z)
	end
	return self
end

--- Impose a maximum magnitude
-- Rescales vector if greater than maximum
-- @param maximum maximum magnitude of vector
-- @return self
function vec3:limit(maximum)
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
function vec3:limitnew(maximum)
	local m2 = self:dot(self)
	if m2 > maximum*maximum then
		return self * (maximum / sqrt(m2))
	end
	return self:copy()
end

-- TODO: rotations (by quat, matrix etc.)

--- Rescale a vector to a specific magnitude:
-- @param m new magnitude
-- @return self
function vec3:setmag(m)
	local scalar = m / self:length()
	self.x = self.x * scalar
	self.y = self.y * scalar
	self.z = self.z * scalar
	return self
end

--- Return a vector copy rescaled to a specific magnitude:
-- @param m new magnitude
-- @return new vector
function vec3:setmagnew(m)
	local scalar = m / self:length()
	return new(
		self.x * scalar,
		self.y * scalar,
		self.z * scalar
	)
end

function vec3:rotateX(angle)
	local c = cos(angle)
	local s = sin(angle)
	local y, z = self.y, self.z
	self.y = y * c - z * s
	self.z = z * c + y * s
	return self
end

--- Create a vector by rotating a vector by an angle
-- @param angle in radians
-- @return new vector
function vec3:rotateXnew(angle)
	local c = cos(angle)
	local s = sin(angle)
	return new(
		self.y * c - self.y * s,
		self.y * c + self.y * s
	)
end

function vec3:rotateY(angle)
	local c = cos(angle)
	local s = sin(angle)
	local x, z = self.x, self.z
	self.x = x * c - z * s
	self.z = z * c + x * s
	return self
end

--- Create a vector by rotating a vector by an angle
-- @param angle in radians
-- @return new vector
function vec3:rotateYnew(angle)
	local c = cos(angle)
	local s = sin(angle)
	return new(
		self.x * c - self.z * s,
		self.z * c + self.x * s
	)
end

function vec3:rotateZ(angle)
	local c = cos(angle)
	local s = sin(angle)
	local x, y = self.x, self.y
	self.x = x * c - y * s
	self.y = y * c + x * s
	return self
end

--- Create a vector by rotating a vector by an angle
-- @param angle in radians
-- @return new vector
function vec3:rotateZnew(angle)
	local c = cos(angle)
	local s = sin(angle)
	return new(
		self.x * c - self.y * s,
		self.y * c + self.x * s
	)
end

--- Create a new vector in a uniformly random direction:
-- @param mag magnitude (optional, default 1)
-- @return new vector
function vec3.random(mag)
	local a = random() * pi * 2
	local z = random() * 2 - 1
	local d = sqrt(1-z*z)
	return new(d * cos(a), d * sin(a), z) * (mag or 1)
end

--- Set to a vector of magnitude 1 in a uniformly random direction:
-- @param mag magnitude (optional, default 1)
-- @return self
function vec3:randomize(mag)
	local a = random() * pi * 2
	local z = random() * 2 - 1
	local d = sqrt(1-z*z)
	self.x = d * cos(a) * (mag or 1)
	self.y = d * sin(a) * (mag or 1)
	self.z = z * (mag or 1)
	return self
end

--- return the length of a vector
-- (Can also use #vector)
-- @return length
function vec3:length()
	return sqrt(self:dot(self))
end
vec3.__len = vec3.length

--- return the squared length of a vector
-- @return length
function vec3:magSqr()
	return self:dot(self)
end

--- return the dot product of two vectors:
-- @param a vector
-- @param b vector
-- @return dot product
function vec3.dot(a, b)
	return a.x * b.x + a.y * b.y + a.z * b.z
end

--- return the cross product of two vectors:
-- @param a vector
-- @param b vector
-- @return cross product
function vec3.cross(a, b)
	return new(
		a.y*b.z - a.z*b.y, 
		a.z*b.x - a.x*b.z, 
		a.x*b.y - a.y*b.x
	)
end

--- The distance between two vectors (two points)
-- (The relative distance from self to p)
-- @param p target to measure distance to
-- @return distance
function vec3:distance(p)
	return (p - self):length()
end
function vec3:distanceSquared(p)
	return (p - self):magSqr()
end

--- The angle between two vectors (two points)
-- (The relative angle from self to v)
-- @param a vector to measure angle between
-- @param b vector to measure angle between
-- @return distance
function vec3.anglebetween(a, b)
	local am = a:length()
	local bm = b:length()
	return acos(a:dot(b) / (am * bm))
end

function vec3:__tostring()
	return format("vec3(%f, %f, %f)", self.x, self.y, self.z)
end

function vec3.__eq(a, b) 
	return a.x==b.x and a.y==b.y and a.z==b.z
end

function vec3:unpack()
	return self.x, self.y, self.z
end

setmetatable(vec3, {
	__call = function(t, x, y, z)
		if type(x) == "number" then
			return new(x, y or 0, z or 0)
		elseif x then
			-- copy an existing vector:
			return new(x.x, x.y, x.z)
		else
			-- create a default vector
			return new(0, 0, 0)
		end
	end
})

ffi.metatype("vec3f", vec3)
ffi.metatype("vec3d", vec3)

-- some built-in vectors:
vec3.unitx = new(1, 0, 0)
vec3.unity = new(0, 1, 0)
vec3.unitz = new(0, 0, 1)
vec3.unitxy = new(1, 1, 0):normalize()
vec3.unitxz = new(1, 0, 1):normalize()
vec3.unityz = new(0, 1, 1):normalize()
vec3.unitxyz = new(1, 1, 1):normalize()

return vec3