--- nav3: utilities for 3D navigation

local vec3 = require "vec3"
local quat = require "quat"
local win = require "window"
print(quat)

local nav3 = {
	pos = vec3(0, 0, 1),
	vel = vec3(),
	acc = vec3(),
	
	q = quat(),
	
	-- relative velocity:
	rvel = vec3(),
	tvel = vec3(),
	turn = vec3(),
	
	-- the coordinate frame components:
	ux = vec3(1, 0, 0),
	uy = vec3(0, 1, 0),
	uz = vec3(0, 0, 1),
}

function nav3:update(dt)
	
	-- convert dt into decay scalar... TODO	
	self.ux = self.q:ux()
	self.uy = self.q:uy()
	self.uz = self.q:uz()
	
	self.acc:set(
		self.ux * self.rvel.x +
		self.uy * self.rvel.y +
		self.uz * self.rvel.z
	)
	
	self.vel:add(self.acc * 0.1)
	self.pos:add(self.vel)
	
	self.vel:mul(0.6)
	
	self.turn:add(self.tvel * 0.1)
	self.q:mul( quat.fromEuler(self.turn * 0.1) ):normalize()
	--self.q:slerp( self.q * quat.fromEuler(self.turn * 0.1), 0.1):normalize()
	
	self.turn:mul(0.6)
end

function nav3:mouse(e, b, x, y)
	
end

function nav3:keydown(k)	
	local v = 1
	if win.shift ~= 0 then
		v = 4
	elseif win.ctrl ~= 0 or win.alt ~= 0 then
		v = 0.25
	end
	if k == "w" then 
		self.rvel.z = -v
		return true
	elseif k == "s" then
		self.rvel.z = v
		return true
	elseif k == "a" then
		self.rvel.x = -v
		return true
	elseif k == "d" then
		self.rvel.x = v
		return true
	elseif k == "'" then
		self.rvel.y= v
		return true
	elseif k == "/" then
		self.rvel.y = -v
		return true
	elseif k == 270 then
		self.tvel.x = v
		return true
	elseif k == 272 then
		self.tvel.x = -v
		return true
	elseif k == 269 then
		self.tvel.y = v
		return true
	elseif k == 271 then
		self.tvel.y = -v
		return true
	elseif k == "z" then
		self.tvel.z = -v
		return true
	elseif k == "c" then
		self.tvel.z = v
		return true
	elseif k == 127 then
		self.vel:set(0)
		self.pos:set(0, 0, 1)
		self.turn:set(0)
		self.q:identity()
		return true
	end
	return false
end

function nav3:keyup(k)
	if k == "w" then 
		self.rvel.z = 0
		return true
	elseif k == "s" then
		self.rvel.z = 0
		return true
	elseif k == "a" then
		self.rvel.x = 0
		return true
	elseif k == "d" then
		self.rvel.x = 0
		return true
	elseif k == "'" then
		self.rvel.y = 0
		return true
	elseif k == "/" then
		self.rvel.y = 0
		return true
	elseif k == 270 then
		self.tvel.x = 0
		return true
	elseif k == 272 then
		self.tvel.x = -0
		return true
	elseif k == 269 then
		self.tvel.y = 0
		return true
	elseif k == 271 then
		self.tvel.y = -0
		return true
	elseif k == "z" then
		self.tvel.z = 0
		return true
	elseif k == "c" then
		self.tvel.z = 0
		return true
	end
	return false
end

function nav3:key(e, k)
	if e == "down" then return self:keydown(k)
	elseif e == "up" then return self:keyup(k)
	else return false end
end

return nav3