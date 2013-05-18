--- vec4: A simple 3-component vector

local sqrt = math.sqrt
local sin, cos = math.sin, math.cos
local atan2 = math.atan2
local acos = math.acos
local random = math.random
local min, max = math.min, math.max
local pi = math.pi
local twopi = pi * 2
local format = string.format

local ffi = require "ffi"
ffi.cdef [[ 

typedef struct vec4f {
	float x, y, z, w;
} vec4f;
typedef struct vec4d {
	double x, y, z, w;
} vec4d;
typedef vec4d vec4;

]]

--- Create a new vector with components x, y, z:
-- (Can also be used to duplicate a vector: vec4(v))
-- @param x number or vector (optional, default 0)
-- @param y number (optional, default 0)
-- @param z number (optional, default 0)
-- @param w number (optional, default 0)
function vec4(x, y, z, w) end

local vec4 = {}
vec4.__index = vec4

local function new(x, y, z, w)
	return ffi.new("vec4", x, y, z, w)
end

--- Create a copy of a vector:
-- @param v vector to copy
function vec4.copy(v)
	return new(v.x, v.y, v.z, v.w)
end

--- Create a copy of a vec2 vector:
-- @param v vec3
-- @param w number (optional, default 1)
function vec4.fromvec3(v, w)
	return new(v.x, v.y, v.z, w or 1)
end

--- Create a copy of a vec3 vector:
-- @param v vec3
-- @param z number (optional, default 0)
-- @param w number (optional, default 1)
function vec4.fromvec2(v, z, w)
	return new(v.x, v.y, z or 0, w or 1)
end


--- Set the components of a vector:
-- @param x component (optional, default 0)
-- @param y component (optional, default 0)
-- @param z component (optional, default 0)
-- @param w component (optional, default 0)
-- @return self
function vec4:set(x, y, z, w)
	if type(x) == "number" or type(x) == "nil" then
		self.x = x or 0
		self.y = y or 0
		self.z = z or 0
		self.w = w or 0
	else
		self.x = x.x or 0
		self.y = x.y or 0
		self.z = x.z or 0
		self.w = x.w or 0
	end
	return self
end

--- Add a vector (or number) to self (in-place)
-- @param v number or vector to add
-- @return self
function vec4:add(v)
	if type(v) == "number" then
		self.x = self.x + v
		self.y = self.y + v
		self.z = self.z + v
		self.w = self.w + v
		return self
	else
		self.x = self.x + v.x
		self.y = self.y + v.y
		self.z = self.z + v.z
		self.w = self.w + v.w
		return self
	end
end

--- Add two vectors (or numbers) to create a new vector
-- @param a vector or number
-- @param b vector or number
-- @return new vector
function vec4.addnew(a, b)
	if type(b) == "number" then
		return new(a.x + b, a.y + b, a.z + b, a.w + b)
	elseif type(a) == "number" then
		return new(a + b.x, a + b.y, a + b.z, a + b.w)
	else
		return new(a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w)
	end
end
vec4.__add = vec4.addnew
	
--- Subtract a vector (or number) to self (in-place)
-- @param v number or vector to sub
-- @return self
function vec4:sub(v)
	if type(v) == "number" then
		self.x = self.x - v
		self.y = self.y - v
		self.z = self.z - v
		self.w = self.w - v
		return self
	else
		self.x = self.x - v.x
		self.y = self.y - v.y
		self.z = self.z - v.z
		self.w = self.w - v.w
		return self
	end
end

--- Subtract two vectors (or numbers) to create a new vector
-- @param a vector or number
-- @param b vector or number
-- @return new vector
function vec4.subnew(a, b)
	if type(b) == "number" then
		return new(a.x - b, a.y - b, a.z - b, a.w - b)
	elseif type(a) == "number" then
		return new(a - b.x, a - b.y, a - b.z, a - b.w)
	else
		return new(a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w)
	end
end
vec4.__sub = vec4.subnew
	
function vec4:__unm()
	return new(-self.x, -self.y, -self.z, -self.w)
end	

--- Multiply a vector (or number) to self (in-place)
-- @param v number or vector to mul
-- @return self
function vec4:mul(v)
	if type(v) == "number" then
		self.x = self.x * v
		self.y = self.y * v
		self.z = self.z * v
		self.w = self.w * v
		return self
	else
		self.x = self.x * v.x
		self.y = self.y * v.y
		self.z = self.z * v.z
		self.w = self.w * v.w
		return self
	end
end

--- Multiply two vectors (or numbers) to create a new vector
-- @param a vector or number
-- @param b vector or number
-- @return new vector
function vec4.mulnew(a, b)
	if type(b) == "number" then
		return new(a.x * b, a.y * b, a.z * b, a.w * b)
	elseif type(a) == "number" then
		return new(a * b.x, a * b.y, a * b.z, a * b.w)
	else
		return new(a.x * b.x, a.y * b.y, a.z * b.z, a.w * b.w)
	end
end
vec4.__mul = vec4.mulnew
	
--- Divide a vector (or number) to self (in-place)
-- @param v number or vector to div
-- @return self
function vec4:div(v)
	if type(v) == "number" then
		return self:mul(1/v)
	else
		self.x = self.x / v.x
		self.y = self.y / v.y
		self.z = self.z / v.z
		self.w = self.w / v.w
		return self
	end
end

--- Divide two vectors (or numbers) to create a new vector
-- @param a vector or number
-- @param b vector or number
-- @return new vector
function vec4.divnew(a, b)
	if type(b) == "number" then
		return vec4.mulnew(a, 1/b)
	elseif type(a) == "number" then
		return new(a / b.x, a / b.y, a / b.z, a / b.w)
	else
		return new(a.x / b.x, a.y / b.y, a.z / b.z, a.w / b.w)
	end
end
vec4.__div = vec4.divnew
	
--- Raise to power a vector (or number) to self (in-place)
-- @param v number or vector to pow
-- @return self
function vec4:pow(v)
	if type(v) == "number" then
		self.x = self.x ^ v
		self.y = self.y ^ v
		self.z = self.z ^ v
		self.w = self.w ^ v
		return self
	else
		self.x = self.x ^ v.x
		self.y = self.y ^ v.y
		self.z = self.z ^ v.z
		self.w = self.w ^ v.w
		return self
	end
end

--- Raise to power two vectors (or numbers) to create a new vector
-- @param a vector or number
-- @param b vector or number
-- @return new vector
function vec4.pownew(a, b)
	if type(b) == "number" then
		return new(a.x ^ b, a.y ^ b, a.z ^ b, a.w ^ b)
	elseif type(a) == "number" then
		return new(a ^ b.x, a ^ b.y, a ^ b.z, a ^ b.w)
	else
		return new(a.x ^ b.x, a.y ^ b.y, a.z ^ b.z, a.w ^ b.w)
	end
end
vec4.__pow = vec4.pownew
	
--- Calculate modulo a vector (or number) to self (in-place)
-- @param v number or vector to mod
-- @return self
function vec4:mod(v)
	if type(v) == "number" then
		self.x = self.x % v
		self.y = self.y % v
		self.z = self.z % v
		self.w = self.w % v
		return self
	else
		self.x = self.x % v.x
		self.y = self.y % v.y
		self.z = self.z % v.z
		self.w = self.w % v.w
		return self
	end
end

--- Calculate modulo two vectors (or numbers) to create a new vector
-- @param a vector or number
-- @param b vector or number
-- @return new vector
function vec4.modnew(a, b)
	if type(b) == "number" then
		return new(a.x % b, a.y % b, a.z % b, a.w % b)
	elseif type(a) == "number" then
		return new(a % b.x, a % b.y, a % b.z, a % b.w)
	else
		return new(a.x % b.x, a.y % b.y, a.z % b.z, a.w % b.w)
	end
end
vec4.__mod = vec4.modnew

--- Calculate minimum of elements (in-place)
-- @param v number or vector limit
-- @return self
function vec4:min(v)
	if type(v) == "number" then
		self.x = min(self.x, v)
		self.y = min(self.y, v)
		self.z = min(self.z, v)
		self.w = min(self.w, v)
		return self
	else
		self.x = min(self.x, v.x)
		self.y = min(self.y, v.y)
		self.z = min(self.z, v.z)
		self.w = min(self.w, v.w)
		return self
	end
end

--- Calculate minimum of elements to create a new vector
-- @param a vector or number
-- @param b vector or number
-- @return new vector
function vec4.minnew(a, b)
	if type(b) == "number" then
		return new(min(a.x, b), min(a.y, b), min(a.z, b), min(a.w, b))
	elseif type(a) == "number" then
		return new(min(a, b.x), min(a, b.y), min(a, b.z), min(a, b.w))
	else
		return new(min(a.x, b.x), min(a.y, b.y), min(a.z, b.z), min(a.w, b.w)) 
	end
end

--- Calculate maximum of elements (in-place)
-- @param v number or vector limit
-- @return self
function vec4:max(v)
	if type(v) == "number" then
		self.x = max(self.x, v)
		self.y = max(self.y, v)
		self.z = max(self.z, v)
		self.w = max(self.w, v)
		return self
	else
		self.x = max(self.x, v.x)
		self.y = max(self.y, v.y)
		self.z = max(self.z, v.z)
		self.w = max(self.w, v.w)
		return self
	end
end

--- Calculate maximum of elements to create a new vector
-- @param a vector or number
-- @param b vector or number
-- @return new vector
function vec4.maxnew(a, b)
	if type(b) == "number" then
		return new(max(a.x, b), max(a.y, b), max(a.z, b), max(a.w, b))
	elseif type(a) == "number" then
		return new(max(a, b.x), max(a, b.y), max(a, b.z), max(a, b.w))
	else
		return new(max(a.x, b.x), max(a.y, b.y), max(a.z, b.z), max(a.w, b.w)) 
	end
end

--- Constrain vector to range (in-place)
-- @param lo vector or number minimum value 
-- @param hi vector or number minimum value 
-- @return self
function vec4:clip(lo, hi)
	return self:max(lo):min(hi)
end

--- Constrain vector to range to create a new vector
-- @param lo vector or number minimum value 
-- @param hi vector or number minimum value 
-- @return new vector
function vec4:clip(lo, hi)
	return self:maxnew(lo):min(hi)
end

--- Determine shortest relative vector in a toroidal space
-- @param dimx width of space (optional, default 1)
-- @param dimy height of space (optional, default dimx)
-- @param dimz depth of space (optional, default dimx)
-- @param dimw fourth dimension of space (optional, default dimx)
-- @return self
function vec4:relativewrap(dimx, dimy, dimz, dimw)
	local dimx = dimx or 1
	local dimy = dimy or dimx
	local dimz = dimz or dimx
	local dimw = dimw or dimx
	local halfx = dimx * 0.5
	local halfy = dimy * 0.5
	local halfz = dimz * 0.5
	local halfw = dimw * 0.5
	self.x = ((self.x + halfx) % dimx) - halfx
	self.y = ((self.y + halfy) % dimy) - halfy
	self.z = ((self.z + halfz) % dimz) - halfz
	self.w = ((self.w + halfw) % dimw) - halfw
	return self
end

--- Create new vector as shortest relative vector in a toroidal space
-- @param dimx width of space (optional, default 1)
-- @param dimy height of space (optional, default dimx)
-- @param dimz depth of space (optional, default dimx)
-- @param dimw fourth dimension of space (optional, default dimx)
-- @return new vector
function vec4:relativewrapnew(dimx, dimy, dimz, dimw)
	return self:copy():relativewrap(dimx, dimy, dimz, dimw)
end

--- interpolate from self to v by factor of f
-- @param v vector
-- @param f interpolation factor from self to v (0 = none, 1 = full)
-- @return self
function vec4:lerp(v, f)
	return self:add(v:sub(self):mul(f))
end

--- create a vector from the linear interpolation of two vectors:
-- @param a vector
-- @param b vector
-- @param f interpolation factor from a to b (0 = none, 1 = full)
-- @return new vector
function vec4.lerpnew(a, b, f)
	return a + (b - a) * f
end

--- set the length of the vector to 1 (unit vector)
-- (randomized direction if self length was zero)
-- @return self
function vec4:normalize()
	local r = self:length()
	if r > 0 then
		local div = 1 / r
		self.x = self.x * div
		self.y = self.y * div
		self.z = self.z * div
		self.w = self.w * div
	else
		-- any direction is ok... 
		self.x = 0
		self.y = 0
		self.z = 0
		self.w = 1
	end
	return self
end

--- return a normalized copy of the vector 
-- (randomized direction if self length was zero)
-- @return vector of length 1 (unit vector)
function vec4:normalizenew()
	local r = self:length()
	if r > 0 then
		local div = 1 / r
		return new(self.x * div, self.y * div, self.z * div, self.w * div)
	else
		-- any direction is ok... 
		return new(0, 0, 0, 1)
	end
	return self
end

--- Impose a maximum magnitude
-- Rescales vector if greater than maximum
-- @param maximum maximum magnitude of vector
-- @return self
function vec4:limit(maximum)
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
function vec4:limitnew(maximum)
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
function vec4:setmag(m)
	return self:mul(m / self:length())
end

--- Return a vector copy rescaled to a specific magnitude:
-- @param m new magnitude
-- @return new vector
function vec4:setmagnew(m)
	return self * (m / self:length())
end

--- return the length of a vector
-- (Can also use #vector)
-- @return length
function vec4:length()
	return sqrt(self:dot(self))
end
vec4.__len = vec4.length

--- return the squared length of a vector
-- @return length
function vec4:magSqr()
	return self:dot(self)
end

--- return the dot product of two vectors:
-- @param a vector
-- @param b vector
-- @return dot product
function vec4.dot(a, b)
	return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
end

--- The distance between two vectors (two points)
-- (The relative distance from self to p)
-- @param p target to measure distance to
-- @return distance
function vec4:distance(p)
	return (p - self):length()
end

--- The angle between two vectors (two points)
-- (The relative angle from self to v)
-- @param a vector to measure angle between
-- @param b vector to measure angle between
-- @return distance
function vec4.anglebetween(a, b)
	local am = a:length()
	local bm = b:length()
	return acos(a:dot(b) / (am * bm))
end

function vec4:__tostring()
	return format("vec4(%f, %f, %f, %f)", self.x, self.y, self.z, self.w)
end

function vec4.__eq(a, b) 
	return a.x==b.x and a.y==b.y and a.z==b.z and a.w==b.w
end

function vec4:unpack()
	return self.x, self.y, self.z, self.w
end

setmetatable(vec4, {
	__call = function(t, x, y, z, w)
		if type(x) == "number" then
			return new(x, y or 0, z or 0, w or 0)
		elseif x then
			-- copy an existing vector:
			return new(x.x, x.y, x.z, x.w)
		else
			-- create a default vector
			return new(0, 0, 0, 0)
		end
	end
})

ffi.metatype("vec4f", vec4)
ffi.metatype("vec4d", vec4)

-- some built-in vectors:
vec4.unitx = new(1, 0, 0, 0)
vec4.unity = new(0, 1, 0, 0)
vec4.unitz = new(0, 0, 1, 0)
vec4.unitw = new(0, 0, 0, 1)
vec4.unitxy = new(1, 1, 0, 0):normalize()
vec4.unitxz = new(1, 0, 1, 0):normalize()
vec4.unityz = new(0, 1, 1, 0):normalize()
vec4.unitxw = new(1, 0, 0, 1):normalize()
vec4.unityw = new(0, 1, 0, 1):normalize()
vec4.unitzw = new(0, 0, 1, 1):normalize()
vec4.unitxyz = new(1, 1, 1, 0):normalize()
vec4.unitxyw = new(1, 1, 0, 1):normalize()
vec4.unitxzw = new(1, 0, 1, 1):normalize()
vec4.unityzw = new(0, 1, 1, 1):normalize()
vec4.unitxyzw = new(1, 1, 1, 1):normalize()

return vec4