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

local mat4 = {}

function new(...)
	return { ... }
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

return mat4