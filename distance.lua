-- http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm

local vec3 = require "vec3"
local vec2 = require "vec2"

local min, max = math.min, math.max
local abs = math.abs

-- an alternative length function which can make objects more square for high n:
local function lengthn(v, n)
	return pow(pow(v.x, n) + pow(v.y, n) + pow(v.z, n), 1/n)
end

local distance = {}

-- signed
function distance.sphere(p, radius)
	return p:length() - radius
end

function distance.torus(p, rad1, rad2)
	local q = vec2(vec2(p.x, p.z):length() - rad1, p.y)
	return q:length() - rad2
end

function distance.torus_squared(p, rad1, rad2, n)
	local q = vec2(vec2(p.x, p.z):length() - rad1, p.y)
	return lengthn(q, n) - rad2
end

function distance.box(p, dim3)
	local pabs = vec3(abs(p.x), abs(p.y), abs(p.z))
	local d = pabs - dim3
	return min(max(d.x,max(d.y,d.z)),0.0) + d:maxnew(0):length()
end

function distance.plane(p, normal, len)
	return p:dot(normal) + len
end	


-- unsigned
function distance.box_unsigned(p, dim3)
	local pabs = vec3(abs(p.x), abs(p.y), abs(p.z))
	return pabs:sub(dim3):max(0):length()
end

function distance.box_unsigned_rounded(p, dim3, radius)
	local pabs = vec3(abs(p.x), abs(p.y), abs(p.z))
	return pabs:sub(dim3):max(0):length() - radius
end



-- operations
function distance.union(d1, d2) return min(d1, d2) end
function distance.intersect(d1, d2) return max(d1, d2) end
function distance.subtract(d1, d2) return max(-d1, d2) end

-- returns a new point (rather than a new distance)
function distance.rep(p, dim3)
	return (p % c) - 0.5*c
end
function distance.translate(p, t)
	return p - t
end
function distance.scale(p, s)
	return p/s
end

-- displacement (not mathematically correct; use small d2!)
function distance.displace(d1, d2)
	return d1 + d2
end
function distance.blend(d1,d2,d3)
	return d1 + d3*(d2-d1)	-- or apply some curve to d3?
end

return distance

