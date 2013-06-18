--- mat4: A 4x4 matrix

local sqrt = math.sqrt
local sin, cos tan = math.sin, math.cos, math.tan
local atan = math.atan
local atan2 = math.atan2
local acos = math.acos
local random = math.random
local pi = math.pi
local twopi = pi * 2
local format = string.format

local ffi = require "ffi"
local vec3 = require "vec3"
local vec4 = require "vec4"

local mat4 = {}
mat4.__index = mat4

local function new(...)
	return setmetatable({ ... }, mat4)
end

--- Get the array index in a matrix:
-- @param column (zero-based)
-- @param row (zero-based)
-- @return index
function mat4:index(column, row)
	return 1 + col*4 + row
end

--- Get the value of a matrix cell
-- @param column (zero-based)
-- @param row (zero-based)
-- @return value
function mat4:getcell(column, row)
	return self[self:index(column, row)]
end

--- Set the value of a matrix cell
-- @param column (zero-based)
-- @param row (zero-based)
-- @param value (optional, default 0)
-- @return self
function mat4:setcell(column, row, value)
	self[ self:index(column, row) ] = value or 0
	return self
end

--- Get a row of the matrix as a vec4
-- @param i (zero-based)
-- @return vec4
function mat4:row(i)
	return vec4(self[i+1], self[i+5], self[i+9], self[i+13])
end

--- Get a column of the matrix as a vec4
-- @param i (zero-based)
-- @return vec4
function mat4:col(i)
	local n = i*4
	return vec4(self[n+1], self[n+2], self[n+3], self[n+4])
end

--- Get a row of the matrix as a vec3
-- @param i (zero-based)
-- @return vec3
function mat4:row3(i)
	return vec3(self[i+1], self[i+5], self[i+9])
end

--- Get a column of the matrix as a vec3
-- @param i (zero-based)
-- @return vec3
function mat4:col3(i)
	local n = i*4
	return vec3(self[n+1], self[n+2], self[n+3])
end

--- Create a copy of the matrix
-- @return new matrix
function mat4:copy()
	return new(unpack(self))
end

--- Get transposed copy of the matrix
-- @return new matrix
function mat4:transposenew()
	local m = mat4.identity()
	for c = 0, 3 do
		for r = 0, 3 do
			m:setcell(c, r, self:getcell(r, c))
		end
	end
	return m
end

-- untested
function mat4.mulnew(a, b)
	-- unroll this?
	local r = mat4.identity()
	for j = 0, 3 do
		local bcol = b:col(j)
		for i = 0, 3 do
			r:setcell(i, j, a:row(i):dot(bcol))
		end
	end
	return r
end
mat4.__mul = mat4.mulnew

--- Set the values of a matrix from a list of arguments
-- @param ... arguments to set
-- @return self
function mat4:set(...)
	for i = 1, select("#", ...) do
		self[i] = select(i, ...)
	end
	return self
end

--- Set or create identity matrix
-- If called without object (mat4.identity()), returns a new matrix
-- If called with object (mat4:identity()), resets the matrix to identity
-- @return matrix
function mat4:identity()
	if self then
		return self:set(
			1, 0, 0, 0,
			0, 1, 0, 0,
			0, 0, 1, 0,
			0, 0, 0, 1
		)
	else
		return new(			
			1, 0, 0, 0,
			0, 1, 0, 0,
			0, 0, 1, 0,
			0, 0, 0, 1
		)
	end
end

--- Computes product of matrix multiplied by column vector, r = m * vCol
-- This is typically what is required to project a vertex through a transform
-- For a better explanation, @see http:--xkcd.com/184/ 
-- @param v vec4 column vector to multiply
-- @return vec4 result
function mat4:transform(v)
	-- returns a vec4
	-- (unroll this for speed?)
	return vec4(
		self:row(0):dot(v),
		self:row(1):dot(v),
		self:row(2):dot(v),
		self:row(3):dot(v)
	)
end

--- Computes product of a vec4 with the transpose of the matrix
-- @param v vec4 vector to multiply
-- @return vec4
function mat4:transform_transposed(v)
	-- returns a vec4
	-- (unroll this for speed?)
	return vec4(
		self:col(0):dot(v),
		self:col(1):dot(v),
		self:col(2):dot(v),
		self:col(3):dot(v)
	)
end

--- Generate a matrix from a position and three unit axes
-- @param pos vec3 position
-- @param ux vec3 right-vector (unit length)
-- @param uy vec3 up-vector (unit length)
-- @param uz vec3 rear-vector (unit length)
-- @return matrix
function mat4.fromPositionAxis(pos, ux, uy, uz)
	return new(
		ux.x, uy.x, uz.x, 0,
		ux.y, uy.y, uz.y, 0,
		ux.z, uy.z, uz.z, 0,
		pos.x,pos.y,pos.z,1
	)
end


function mat4.translate(x, y, z)
	return new(
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		x, y, z, 1
	)
end

function mat4.scale(x, y, z)
	return new(
		x, 0, 0, 0,
		0, y, 0, 0,
		0, 0, z, 0,
		0, 0, 0, 1
	)
end

function mat4.rotateYZ(angle)
	local C = cos(angle); 
	local S = sin(angle);
	return new(
		1, 0, 0, 0,
		0, C, S, 0,
		0, -S,C, 0,
		0, 0, 0, 1
	)
end

function mat4.rotateZX(angle)
	local C = cos(angle); 
	local S = sin(angle);
	return new(
		C, 0, -S,0,
		0, 1, 0, 0,
		S, 0, C, 0,
		0, 0, 0, 1
	)
end

function mat4.rotateXY(angle)
	local C = cos(angle); 
	local S = sin(angle);
	return new(
		C, S, 0, 0,
		-S,C, 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1
	)
end

-- @param axis normalized vector to rotate around
function mat4.rotate(angle, axis)
	local x, y, z = axis.x, axis.y, axis.z
	local C = cos(angle)
	local I = 1 - C
	local S = sin(angle)
	return new(
		x*x*I + C,		x*y*I - z*S,	x*z*I + y*S,	0,
		y*x*I + z*S,	y*y*I + C,		y*z*I + x*S,	0,
		z*x*I - y*S,	z*y*I + x*S,	z*z*I + C,		0,
		0,				0,				0,				1
	)	
end

-- @param axis1 axis index (zero-based, e.g. X == 0)
-- @param axis2 axis index (zero-based, e.g. Y == 1)
function mat4.rotation(angle, axis1, axis2)
	local m = mat4.identity()
	local C = cos(angle)
	local S = sin(angle)
	m:setcell(axis1, axis1, C)
	m:setcell(axis1, axis2, -S)
	m:setcell(axis2, axis1, S)
	m:setcell(axis2, axis2, C)
	return m
end

function mat4.shearYZ(y, z)
	return new(
		1, y, z, 0,
		0, 1, 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1
	)
end

function mat4.shearZX(z, x)
	return new(
		1, 0, 0, 0,
		x, 1, z, 0,
		0, 0, 1, 0,
		0, 0, 0, 1
	)
end

function mat4.shearXY(x, y)
	return new(
		1, 0, 0, 0,
		0, 1, 0, 0,
		x, y, 1, 0,
		0, 0, 0, 1
	)
end

--- Calculate perspective projection for near plane and eye coordinates
-- (nearBL, nearBR, nearTL, eye) all share the same coordinate system
-- (nearBR,nearBL) and (nearTL,nearBL) should form a right angle
-- (eye) can be set freely, allowing diverse off-axis projections
-- See Generalized Perspective Projection, Robert Kooima, 2009, EVL
-- @param nearBL	bottom-left near-plane coordinate (world-space)
-- @param nearBR	bottom-right near-plane coordinate (world-space)
-- @param nearTL	top-left near-plane coordinate (world-space)
-- @param eye		eye coordinate (world-space)
-- @param near		near plane distance from eye
-- @param far		far plane distance from eye
function mat4.perspectivePlane(nearBL, nearBR, nearTL, eye, near, far)
	-- compute orthonormal basis for the screen
	local vr = (nearBR-nearBL):normalize()	-- right vector
	local vu = (nearTL-nearBL):normalize()	-- upvector
	local vn = vr:cross(vu):normalize()		-- normal(forward) vector (out from screen)
	-- compute vectors from eye to screen corners:
	local va = nearBL-eye	
	local vb = nearBR-eye	
	local vc = nearTL-eye
	-- distance from eye to screen-plane
	-- = component of va along vector vn (normal to screen)
	local d = -va:dot(vn)
	-- find extent of perpendicular projection
	local nbyd = near/d;
	local l = vr:dot(va) * nbyd
	local r = vr:dot(vb) * nbyd
	local b = vu:dot(va) * nbyd	-- not vd?
	local t = vu:dot(vc) * nbyd
	return mat4.frustum(l, r, b, t, near, far);
end

-- off-axis in X only (e.g. planar stereo offset)
function mat4.perspectiveOffAxisX(fovy, aspect, near, far, xShift, focal)
	local focal = focal or 1
	local h = near * tan(fovy*0.008726646259972)	-- height of view at distance = near
	local w = aspect * h
	local x = -xshift*near/focal
	local b = -h
	local t = h
	local l = x - w
	local r = x + w	
	return mat4.frustum(l, r, b, t, near, far)
end

-- off-axis in Y only (e.g. planar stereo offset)
function mat4.perspectiveOffAxisY(fovy, aspect, near, far, yShift, focal)	
	local focal = focal or 1
	local h = near * tan(fovy*0.008726646259972)	-- height of view at distance = near
	local w = aspect * h
	local y = -yshift*near/focal
	local b = y - h
	local t = y + h
	local l = w
	local r = w	
	return perspective(l, r, b, t, near, far);
end

--- Generalized off-axis perspective:
function mat4.perspectiveOffAxis(fovy, aspect, near, far, xshift, yshift, focal)
	local xshift = xshift or 0
	local yshift = yshift or 0
	local focal = focal or 1
	local h = near * tan(fovy*0.008726646259972)	-- height of view at distance = near
	local w = aspect * h
	local x = -xshift*near/focal
	local y = -yshift*near/focal
	local b = y - h
	local t = y + h
	local l = x - w
	local r = x + w	
	return mat4.frustum(l, r, b, t, near, far)
end

function mat4.perspective(fovy, aspect, near, far)
	-- height of view at distance 1:
	local h = tan(fovy * 0.008726646259972)
	local f = 1/h
	local D = far - near
	local D2 = far + near
	local D3 = far * near * 2
	return new(
		f/(aspect), 0, 0,		0,
		0,			f, 0,		0,
		0,			0, -D2/D,	-1,
		0,			0, -D3/D,	0
	)
end

-- @param l	distance from center of near plane to left edge
-- @param r	distance from center of near plane to right edge
-- @param b	distance from center of near plane to bottom edge
-- @param t	distance from center of near plane to top edge
-- @param n	distance from eye to near plane
-- @param f	distance from eye to far plane
function mat4.frustum(l, r, b, t, near, far)
	local W, W2 = r-l, r+l
	local H, H2 = t-b, t+b
	local D, D2 = far-near, far+near
	local n2 = near*2
	local D3 = far*n2
	return new(
		n2/W,	0,		0,		0,
		0,		n2/H,	0,		0,
		W2/W,	H2/H,	-D2/D,	-1,
		0,		0,		-D3/D,	0
	)
end


function mat4.unfrustum(l, r, b, t, near, far)
	local W, W2 = r-l, r+l
	local H, H2 = t-b, t+b
	local D, D2 = far-near, far+near
	local n2 = near*2
	local fn2 = far*n2
	return new(
		W/n2, 0, 0, 0,
		0, H/n2, 0, 0, 
		0, 0, 0, -D/fn2,
		W2/n2, H2/n2, -1, D2/fn2
	)
end

function mat4.ortho(l, r, b, t, near, far)
	local W, W2 = r-l, r+l
	local H, H2 = t-b, t+b
	local D, D2 = far-near, far+near
	return new(
		2/W, 	0, 		0, 		0,
		0, 		2/H, 	0, 		0, 
		0, 		0, 		-2/D,	0,
		-W2/W,	-H2/H,	-D2/D,	1
	)
end

function mat4.unortho(l, r, b, t, near, far)
	local W, W2 = r-l, r+l
	local H, H2 = t-b, t+b
	local D, D2 = far-near, far+near
	return new(
		W/2, 0, 0, 0,
		0, H/2, 0, 0,
		0, 0, D/-2, 0,
		W2/W, H2/H, D2/D, 1
	)
end

-- get distance to far plane from a projection matrix:
-- untested
function mat4:frustumfar()
	return self[15] / (self[11] + 1)
end

-- get distance to near plane from a projection matrix:
-- untested
function mat4:frustumfar()
	return self[15] / (self[11] - 1)
end

-- get distance from near to far plane from a projection matrix:
-- untested
function mat4:frustumdepth()
	return (-2*self[15]) / (self[11]*self[11] - 1)
end

-- get aspect ratio from a projection matrix:
-- untested
function mat4:frustumaspect()
	return self[6] / self[1]
end

-- ux, uy, uz must be unit vectors
-- remember that uz points in the opposite direction to the view...
function mat4.lookatu(eye, ux, uy, uz)
	return new(
		ux.x, uy.x, uz.x, 0,
		ux.y, uy.y, uz.y, 0,
		ux.z, uy.z, uz.z, 0,
		-ux:dot(eye), -uy:dot(eye), -uz:dot(eye), 1
	)
end

function mat4.lookat(eye, at, up)
	local uz = (eye - at):normalize()
	local uy = up:copy():normalize()
	local ux = up:cross(uz):normalize()
	return mat4.lookatu(eye, ux, uy, uz)
end

function mat4:__tostring()
	-- simple version:
	return string.format("mat4(%s)", table.concat(self, ", "))
	-- fancy version:
	--[[
	local rows = {
		string.format("%f, %f, %f, %f", self[1], self[2], self[3], self[4]),
		string.format("%f, %f, %f, %f", self[5], self[6], self[7], self[8]),
		string.format("%f, %f, %f, %f", self[9], self[10], self[11], self[12]),
		string.format("%f, %f, %f, %f", self[13], self[14], self[15], self[15]),
	}
	return string.format("mat4(\t%s)", table.concat(rows, ",\n\t"))
	--]]
end

mat4.identity_matrix = new(
	1, 0, 0, 0,
	0, 1, 0, 0,
	0, 0, 1, 0,
	0, 0, 0, 1)

return mat4