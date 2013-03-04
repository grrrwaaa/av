#!av

local gl = require "gl"
local sketch = gl.sketch
local win = require "window"
local ffi = require "ffi"
local field2D = require "field2D"


function win:draw(w, h, dt)
	--print("fps", 1/dt)
	draw(w, h, dt)
end

function win:key(e, k)
	
end

local min, max = math.min, math.max
local floor, ceil = math.floor, math.ceil
local random = math.random
function srandom() return random()*2-1 end
function round(x) return floor(x+0.5) end

local dimx = win.width
local dimy = win.height

local field0 = field2D(dimx, dimy)
local field1 = field2D(dimx, dimy)

local function randomize(x, y)
	return random() < 0.5 and 1 or 0
end

field0:apply(randomize)
field1:apply(randomize)

function win:mouse(e, b, mx, my)
	-- scale window coords to texture cords:
	local tx = field0.dim[1] * mx/self.width
	local ty = field1.dim[2] * my/self.height
	
	if e == "down" or e == "drag" then
		local span = 5
		for x = tx-span, tx+span do
			for y = ty-span, ty+span do
				field0:set(random() < 0.5 and 1 or 0, x, y)
			end
		end
	end
end

function rule(x, y, old, new)
	
	local C = old:get(x, y)
	local N = old:get(x, y+1)
	local NE = old:get(x+1, y+1)
	local E = old:get(x+1, y)
	local SE = old:get(x+1, y-1)
	local S = old:get(x, y-1)
	local SW = old:get(x-1, y-1)
	local W = old:get(x-1, y)
	local NW = old:get(x-1, y+1)
	
	local near = N + E + S + W + NE + NW + SE + SW
	
	if C == 1 then
		-- live cell
		if near < 2 then
			-- loneliness
			C = 0
		elseif near > 3 then
			-- overcrowding
			C = 0
		end
	else
		-- dead cell
		if near == 3 then
			-- reproduction
			C = 1
		end
	end
	new:set(C, x, y)
end

function draw(w, h)
	
	field0:send()
	sketch.quad(0, 0, w, h)
	
	-- iterate
	for x = 0, dimx-1 do
		for y = 0, dimy-1 do
			rule(x, y, field0, field1)
		end
	end

	-- swap:
	field0, field1 = field1, field0
end