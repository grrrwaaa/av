--- quat: A simple 2-component vector

local sqrt = math.sqrt
local sin, cos = math.sin, math.cos
local atan2 = math.atan2
local acos = math.acos
local min, max = math.min, math.max
local abs = math.abs
local random = math.random
local pi = math.pi
local twopi = pi * 2
local EPSILON = 0.0000001
local format = string.format

local vec3 = require "vec3"
local mat4 = require "mat4"

local ffi = require "ffi"
ffi.cdef [[ 

typedef struct quatf {
	float x, y, z, w;
} quatf;

typedef struct quatd {
	double x, y, z, w;
} quatd;
typedef quatd quat;

]]

--- Create a new quat with components x, y, z, w:
-- (Can also be used to duplicate: quat(v))
-- @param x number or vector (optional, default 0)
-- @param y number (optional, default 0)
-- @param z number (optional, default 0)
-- @param w number (optional, default 1)
function quat(x, y, z, w) end

local quat = {}
quat.__index = quat

local function new(x, y, z, w)
	return ffi.new("quat", x, y, z, w)
end

--- Create a copy:
-- @param v quaternion
function quat.copy(v)
	return new(v.x, v.y, v.z, v.w)
end

--- Set the components of a vector:
-- @param x component
-- @param y component
-- @param z component
-- @param w component
-- @return self
function quat:set(x, y, z, w)
	if type(x) == "number" or type(x) == "nil" then
		self.x = x or 0
		self.y = y or 0
		self.z = z or 0
		self.w = w or 1
	else
		self.x = x.x or 0
		self.y = x.y or 0
		self.z = x.z or 0
		self.w = x.w or 1
	end
	return self
end

-- construct or in-place:
function quat:identity()
	if self then
		self.x = 0
		self.y = 0
		self.z = 0
		self.w = 1
	else
		return new()
	end
end

function quat.fromAxisAngle(angle, axis)
	local t2 = angle * 0.5
	local sinft2 = sin(t2)
	return new(
		axis.x * sinft2,
		axis.y * sinft2,
		axis.z * sinft2,
		cos(t2)
	)
end

function quat.fromAxisX(angle)
	local t2 = angle * 0.5
	local sinft2 = sin(t2)
	return new(
		sinft2,
		0, 
		0,
		cos(t2)
	)
end

function quat.fromAxisY(angle)
	local t2 = angle * 0.5
	local sinft2 = sin(t2)
	return new(
		0, 
		sinft2,
		0,
		cos(t2)
	)
end

function quat.fromAxisZ(angle)
	local t2 = angle * 0.5
	local sinft2 = sin(t2)
	return new(
		0, 
		0,
		sinft2,
		cos(t2)
	)
end

function quat.fromUnitVectors(ux, uy, uz)
	local uxy, uxz = ux.y, ux.z
	local uyx, uyz = uy.x, uy.z
	local uzx, uzy = uz.x, uz.y
	local trace = ux.x + uy.y + uz.z
	
	if trace > 0 then
		local w = sqrt(1. + trace)*0.5
		local div = 1/(4*w)
		return new(
			(uyz - uzy) * div,
			(uzx - uxz) * div,
			(uxy - uyx) * div,
			w)
	elseif (ux.x > uy.y and ux.x > uz.z) then
		-- ux.x is greatest
		local x = sqrt(1. + ux.x-uy.y-uz.z)*0.5
		local div = 1/(4*x)
		return new(
			x,
			(uxy + uyx) * div,
			(uxz + uzx) * div,
			(uyz - uzy) * div)
	elseif (uy.y > ux.x and uy.y > uz.z) then
		-- uyx is greatest
		local y = sqrt(1. + uy.y-ux.x-uz.z)*0.5
		local div = 1/(4*y)
		return new(
			(uxy + uyx) * div,
			y,
			(uyz + uzy) * div,
			(uzx - uxz) * div)
	else 
		-- uzx is greatest
		local z = sqrt(1. + uz.z-ux.x-uy.y)*0.5
		local div = 1/(4*z)
		return new(
			(uxz + uzx) * div,
			(uyz + uzy) * div,
			z,
			(uxy - uyx) * div)
	end
end


--- derive quaternion as absolute difference between two unit vectors
-- v1 and v2 must be normalized. the order of v1,v2 is not important;
-- v1 and v2 define a plane orthogonal to a rotational axis
-- the rotation around this axis increases as v1 and v2 diverge
-- alternatively expressed as Q = (1+gp(v1, v2))/sqrt(2*(1+dot(b, a)))
function quat.fromRotor(v1, v2) 
	--  get the normal to the plane (i.e. the unit bivector containing the v1 and v2)
	-- normalize because the cross product can get slightly denormalized
	local axis = v1:cross(v2)
	axis:normalize()
	
	-- the angle between v1 and v2:
	local dotmag = v1:dot(v2)
	-- theta is 0 when colinear, pi/2 when orthogonal, pi when opposing
	local theta = acos(dotmag)
	
	-- now generate as normal from angle-axis representation
	return quat.fromAxisAngle(theta, axis)
end

function quat.fromEuler(az, el, ba) 
	--[[
	--http:--vered.rose.utoronto.ca/people/david_dir/GEMS/GEMS.html
	--Converting from Euler angles to a quaternion is slightly more tricky, as the order of operations
	--must be correct. Since you can convert the Euler angles to three independent quaternions by
	--setting the arbitrary axis to the coordinate axes, you can then multiply the three quaternions
	--together to obtain the final quaternion.
	--So if you have three Euler angles (a, b, c), then you can form three independent quaternions
	--Qx = [ cos(a/2), (sin(a/2), 0, 0)]
	--Qy = [ cos(b/2), (0, sin(b/2), 0)]
	--Qz = [ cos(c/2), (0, 0, sin(c/2))]
	--And the final quaternion is obtained by Qx * Qy * Qz.
	--]]
	if type(az) ~= "number" then
		az, el, ba = az.y, az.x, az.z
	end
	
	local c1 = cos(az * 0.5)
	local c2 = cos(el * 0.5)
	local c3 = cos(ba * 0.5)
	local s1 = sin(az * 0.5)
	local s2 = sin(el * 0.5)
	local s3 = sin(ba * 0.5)
	-- equiv Q1 = Qy * Qx; -- since many terms are zero
	local tw = c1*c2
	local tx = c1*s2
	local ty = s1*c2
	local tz =-s1*s2
	-- equiv Q2 = Q1 * Qz; -- since many terms are zero
	return new(
		tx*c3 + ty*s3,
		ty*c3 - tx*s3,
		tw*s3 + tz*c3,
		tw*c3 - tz*s3
	)
end


--- Multiply a quaternion
-- If q is a scalar, it scales all components. If q is a quaternion, it applies quaternion rotation.
-- @param q number or quaternion to mul
-- @return self
function quat:mul(q)
	if type(q) == "number" then
		self.x = self.x * q
		self.y = self.y * q
		self.z = self.z * q
		self.w = self.w * q
	else
		local x = self.w*q.x + self.x*q.w + self.y*q.z - self.z*q.y
		local y = self.w*q.y + self.y*q.w + self.z*q.x - self.x*q.z
		local z = self.w*q.z + self.z*q.w + self.x*q.y - self.y*q.x
		local w = self.w*q.w - self.x*q.x - self.y*q.y - self.z*q.z
		self.x = x
		self.y = y
		self.z = z
		self.w = w
	end
	return self
end


--- Multiply two quaternions
-- If q is a scalar, it scales all components. If q is a quaternion, it applies quaternion rotation.
-- @param q number or quaternion to mul
-- @return new quaternion
function quat:mulnew(q)
	if type(q) == "number" then
		return new(
			self.x * q,
			self.y * q,
			self.z * q,
			self.w * q
		)
	elseif type(self) == "number" then
		return q * self
	else
		return new(
			self.w*q.x + self.x*q.w + self.y*q.z - self.z*q.y,
			self.w*q.y + self.y*q.w + self.z*q.x - self.x*q.z,
			self.w*q.z + self.z*q.w + self.x*q.y - self.y*q.x,
			self.w*q.w - self.x*q.x - self.y*q.y - self.z*q.z
		)
	end
end
quat.__mul = quat.mulnew
	
--- Multiply two quaternions
-- If q is a scalar, it scales all components. If q is a quaternion, it applies conjugate quaternion rotation.
-- @param a number or quaternion to divide
-- @param b number or quaternion to divide by
-- @return new quaternion
function quat.divnew(a, b)
	if type(b) == "number" then
		-- scalar division
		return new(a.x / b, a.y / b, a.z / b, a.w / b)
	elseif type(s) == "number" then
		-- scalar division
		return new(a / b.x, a / b.y, a / b.z, a / b.w)
	else
		-- TODO: inline this
		return b:conjugatenew():mul(a/b:magSqr())
	end
end
quat.__div = quat.divnew

function quat:add(q)
	if type(q) == "number" then
		self.x = self.x + q
		self.y = self.y + q
		self.z = self.z + q
		self.w = self.w + q
	else
		self.x = self.x + q.x
		self.y = self.y + q.y
		self.z = self.z + q.z
		self.w = self.w + q.w
	end
	return self
end

function quat:sub(q)
	if type(q) == "number" then
		self.x = self.x - q
		self.y = self.y - q
		self.z = self.z - q
		self.w = self.w - q
	else
		self.x = self.x - q.x
		self.y = self.y - q.y
		self.z = self.z - q.z
		self.w = self.w - q.w
	end
	return self
end

--- set the length of the vector to 1 (unit vector)
-- (randomized direction if self length was zero)
-- @return self
function quat:normalize()
	local r = self:length()
	if r > 0 then
		local div = 1 / r
		self.x = self.x * div
		self.y = self.y * div
		self.z = self.z * div
		self.w = self.w * div
	else
		-- no particular direction
		self:identity()
	end
	return self
end

--- return a normalized copy of the vector 
-- (randomized direction if self length was zero)
-- @return vector of length 1 (unit vector)
function quat:normalizenew()
	local r = self:length()
	if r > 0 then
		local div = 1 / r
		return new(self.x * div, self.y * div, self.z * div, self.w * div)
	else
		-- no particular direction
		return new()
	end
end

function quat:conjugate()
	self.x = -self.x
	self.y = -self.y
	self.z = -self.z
	return self
end

function quat:conjugatenew()
	return new(-self.x, -self.y, -self.z, self.w)
end
quat.__unm = quat.conjugatenew

-- Returns multiplicative inverse
function quat:reciprocal() 
	return self:conjugate():mul(1/self:magSqr())
end

function quat:reciprocalnew() 
	return self:conjugatenew():mul(1/self:magSqr())
end

-- should it normalize internally? 
function quat:lerp(target, amt)
	local a = 1-amt
	return self:sub(target):mul(a):add(target):normalize()
end

function quat:lerpnew(b, t)
	return (b-self):mul(t):add(self)
end
quat.mix = quat.lerpnew

function quat:slerp(target, amt)
	if amt == 0 then
		return s
	elseif amt == 1 then
		return target
	end
	
	local sign = 1
	local dot_prod = self:dot(target)
	-- clamp:
	local dot_prod = min(max(dot_prod, -1), 1)
	-- if B is on opposite hemisphere from A, use -B instead
	if dot_prod < 0.0 then
		dot_prod = -dot_prod
		sign = -1
	end
	
	local a, b
	local cos_angle = acos(dot_prod)
	if abs(cos_angle) > EPSILON then
		local sine = sin(cos_angle)
		local inv_sine = 1/sine
		a = sin(cos_angle*(1-amt)) * inv_sine
		b = sign * sin(cos_angle*amt) * inv_sine
	else
		-- nearly the same;
		-- approximate without trigonometry
		a = amt
		b = 1-amt
	end
	
	return self:lerp(target, b)
end

--- return the length of a vector
-- (Can also use #vector)
-- @return length
function quat:length()
	return sqrt(self:dot(self))
end
quat.__len = quat.length
quat.mag = quat.length

function quat:magSqr()
	return self:dot(self)
end

--- return the dot product of two quaternions:
-- @param v quaternion argument
-- @return dot product
function quat:dot(v)
	return self.w*v.w + self.x*v.x + self.y*v.y + self.z*v.z
end

function quat:axisAngle()
	local unit = self.w*self.w
	if unit < 0.999999 then
		-- |cos x| must always be less than or equal to 1!
		local invsin = 1/sqrt(1 - unit) --approx = 1/sqrt(1 - cos^2(theta/2))
		return 2*acos(self.w), vec3(self.x*invsin, self.y*invsin, self.z*invsin)
	else
		if self.x == 0 and self.y == 0 and self.z == 0 then
			-- change to some default axis:
			return 0, vec3.random()
		else
			-- for small angles, axis is roughly equal to i,j,k components
			-- axes are close to zero, should be normalized:
			return 0, vec3(self.x, self.y, self.z):normalize()
		end
	end
end

function quat:euler()
	-- http:--www.mathworks.com/access/helpdesk/help/toolbox/aeroblks/quaternionstoeulerangles.html
	local sqw = self.w*self.w
	local sqx = self.x*self.x
	local sqy = self.y*self.y
	local sqz = self.z*self.z
	az = asin (-2.0 * (self.x*self.z - self.w*self.y))
	el = atan2( 2.0 * (self.y*self.z + self.w*self.x), (sqw - sqx - sqy + sqz))
	ba = atan2( 2.0 * (self.x*self.y + self.w*self.z), (sqw + sqx - sqy - sqz))
	return az, el, ba
end

function quat.ux(s) 
	return vec3( 
		1.0 - 2.0*s.y*s.y - 2.0*s.z*s.z,
		2.0*s.x*s.y + 2.0*s.z*s.w,
		2.0*s.x*s.z - 2.0*s.y*s.w)
end

function quat.uy(s) 
	return vec3( 
		2.0*s.x*s.y - 2.0*s.z*s.w,
		1.0 - 2.0*s.x*s.x - 2.0*s.z*s.z,
		2.0*s.y*s.z + 2.0*s.x*s.w)
end

function quat.uz(s) 
	return vec3( 
		2.0*s.x*s.z + 2.0*s.y*s.w,
		2.0*s.y*s.z - 2.0*s.x*s.w,
		1.0 - 2.0*s.x*s.x - 2.0*s.y*s.y)
end

-- 'forward' vector is negative z for OpenGL coordinate system
function quat.uf(s) 
	return vec3( 
		-( 2.0*s.x*s.z + 2.0*s.y*s.w ),
		-( 2.0*s.y*s.z - 2.0*s.x*s.w ),
		-( 1.0 - 2.0*s.x*s.x - 2.0*s.y*s.y) )
end

--[[
Quat to matrix:
RHCS
	[ 1 - 2y - 2z    2xy + 2wz      2xz - 2wy	] 
	[											] 
	[ 2xy - 2wz      1 - 2x - 2z    2yz + 2wx	] 
	[											] 
	[ 2xz + 2wy      2yz - 2wx      1 - 2x - 2y	]

LHCS              
	[ 1 - 2y - 2z    2xy - 2wz      2xz + 2wy	] 
	[											] 
	[ 2xy + 2wz      1 - 2x - 2z    2yz - 2wx	] 
	[											] 
	[ 2xz - 2wy      2yz + 2wx      1 - 2x - 2y	]

--]]
function quat:matrix(m)
	local ux, uy, uz = self:ux(), self:uy(), self:uz()
	local m = mat4()
	m[ 1] = ux.x;	m[ 2] = uy.x;	m[ 3] = uz.x;	m[ 4] = 0;
	m[ 5] = ux.y;	m[ 6] = uy.y;	m[ 7] = uz.y;	m[ 8] = 0;
	m[ 9] = ux.z;	m[10] = uy.z;	m[11] = uz.z;	m[12] = 0;
	m[ 13] = 0;		m[14] = 0;		m[15] = 0;		m[16] = 1;
	return m
end

--- Rotate a vector:
--	q must be a normalized quaternion
function quat.rotate(q, v)
	-- qv = vec4(v, 0) -- 'pure quaternion' derived from vector
	-- return ((q * qv) * q^-1).xyz
	-- reduced to 24 multiplies and 17 additions:
	local px =  q.w*v.x + q.y*v.z - q.z*v.y
	local py =  q.w*v.y + q.z*v.x - q.x*v.z
	local pz =  q.w*v.z + q.x*v.y - q.y*v.x
	local pw = -q.x*v.x - q.y*v.y - q.z*v.z
	return vec3(
		px*q.w - pw*q.x + pz*q.y - py*q.z,	-- x
		py*q.w - pw*q.y + px*q.z - pz*q.x,	-- y
		pz*q.w - pw*q.z + py*q.x - px*q.y	-- z
	)
end

--- Rotate a vector out of a quaternion:
-- equiv. quat_rotate(quat_conj(q), v):
-- q must be a normalized quaternion
function quat.unrotate(q, v)
	-- reduced:
	local px = q.w*v.x - q.y*v.z + q.z*v.y
	local py = q.w*v.y - q.z*v.x + q.x*v.z
	local pz = q.w*v.z - q.x*v.y + q.y*v.x
	local pw = q.x*v.x + q.y*v.y + q.z*v.z
	return vec3(
		pw*q.x + px*q.w + py*q.z - pz*q.y,  -- x
		pw*q.y + py*q.w + pz*q.x - px*q.z,  -- y
		pw*q.z + pz*q.w + px*q.y - py*q.x   -- z
	)
end

function quat:__tostring()
	return format("quat(%f, %f, %f, %f)", self.x, self.y, self.z, self.w)
end

function quat.__eq(a, b) 
	return a.w==b.w and a.x==b.x and a.y==b.y and a.z==b.z
end

function quat:unpack()
	return self.x, self.y, self.z, self.w
end

setmetatable(quat, {
	__call = function(t, x, y, z, w)
		if type(x) == "number" then
			return new(x, y or 0, z or 0, w or 1)
		elseif x then
			-- copy an existing vector:
			return new(x.x or 0, x.y or 0, x.z or 0, x.w or 1)
		else
			-- create a default
			return new(0, 0, 0, 1)
		end
	end
})

ffi.metatype("quatf", quat)
ffi.metatype("quatd", quat)

return quat
