local gl = require "gl"
local sketch = gl.sketch
local win = require "window"
local ffi = require "ffi"
local field2D = require "field2D"

local min, max = math.min, math.max
local floor, ceil = math.floor, math.ceil
local random = math.random
function srandom() return random()*2-1 end
function round(x) return floor(x+0.5) end
function coin()
	return random() < 0.5 and 1 or 0
end

local updating = true

local dimx = 512
local dimy = dimx * 3/4	-- assume the window has a 4:3 aspect ratio...

-- allocate the current & next fields:
local field0 = field2D(dimx, dimy)
local field1 = field2D(dimx, dimy)

-- initialize randomly:
field0:apply(coin)
field1:apply(coin)

function game_of_life(x, y)

	local old = field0
	
	-- check out the neighbors:
	local N = old:get(x, y+1)
	local NE = old:get(x+1, y+1)
	local E = old:get(x+1, y)
	local SE = old:get(x+1, y-1)
	local S = old:get(x, y-1)
	local SW = old:get(x-1, y-1)
	local W = old:get(x-1, y)
	local NW = old:get(x-1, y+1)
	local near = N + E + S + W + NE + NW + SE + SW
	
	-- current state:
	local C = old:get(x, y)
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
	--new:set(C, x, y)
	return C
end

function win:draw(w, h, dt)
	
	field0:send()
	sketch.quad(0, 0, w, h)
	
	if updating then
		-- apply the rule:
		field1:apply(game_of_life)

		-- swap:
		field0, field1 = field1, field0
	end
end


function win:key(e, k)
	if e == "down" and k == 32 then
		updating = not updating
	end
end

function win:mouse(e, b, mx, my)
	-- scale window coords to texture cords:
	local tx = mx * field0.width/self.width
	local ty = my * field1.height/self.height
	
	if e == "down" or e == "drag" then
		local span = 5
		for x = tx-span, tx+span do
			for y = ty-span, ty+span do
				field0:set(random() < 0.5 and 1 or 0, x, y)
			end
		end
	end
end