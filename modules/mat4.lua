--- mat4: A 4x4 matrix

local sqrt = math.sqrt
local sin, cos = math.sin, math.cos
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

function mat4:row(i)
	return vec4(self[i+1], self[i+5], self[i+9], self[i+13])
end

function mat4:col(i)
	local n = i*4
	return vec4(self[n+1], self[n+2], self[n+3], self[n+4])
end

function mat4:row3(i)
	return vec3(self[i+1], self[i+5], self[i+9])
end

function mat4:col3(i)
	local n = i*4
	return vec3(self[n+1], self[n+2], self[n+3])
end

--- Computes product of matrix multiplied by column vector, r = m * vCol
-- This is typically what is required to project a vertex through a transform
-- For a better explanation, @see http://xkcd.com/184/ 
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

function mat4.perspective(fovy, aspect, near, far)
	-- height of view at distance 1:
	local h = math.tan(fovy * 0.008726646259972)
	local f = 1/h
	local D = far - near
	local D2 = far + near
	local D3 = far * near * 2
	return new(
		f/(aspect), 0, 0, 0,
		0, f, 0, 0,
		0, 0, -D2/D, -1,
		0, 0, -D3/D, 0
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
	return lookatu(eye, ux, uy, uz)
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

return mat4