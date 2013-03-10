local gl = require "gl"
local field2D = require "field2D"

function coin() return math.random() < 0.5 and 1 or 0 end

local dimx = 64
local dimy = dimx * 3/4	-- assumes the window has a 4:3 aspect ratio...

-- allocate the current & next fields:
local field = field2D(dimx, dimy)
local field_old = field2D(dimx, dimy)

-- randomize initially:
field:apply(coin)

-- how to render the scene (toggle fullscreen with the Esc key):
function draw(w, h)	
	-- draw the field:
	field:draw()
end

function game_of_life(x, y)

	-- check out the neighbors:
	local N  = field_old:get(x  , y+1)
	local NE = field_old:get(x+1, y+1)
	local E  = field_old:get(x+1, y  )
	local SE = field_old:get(x+1, y-1)
	local S  = field_old:get(x  , y-1)
	local SW = field_old:get(x-1, y-1)
	local W  = field_old:get(x-1, y  )
	local NW = field_old:get(x-1, y+1)
	local near = N + E + S + W + NE + NW + SE + SW
	
	-- current state:
	local C = field_old:get(x, y)
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
	return C
end

-- update the state of the scene (toggle this on and off with spacebar):
function update(dt)
	-- swap front/back:
	field, field_old = field_old, field
	-- apply the rule:
	field:apply(game_of_life)
end

-- handle keypress events:
function keydown(k)
	if k == string.byte("c") then
		field:clear()
	elseif k == string.byte("r") then
		field:apply(coin)
	end
end


-- handle mouse events:
function mouse(e, btn, mx, my)
	-- scale window coords to texture cords:
	local tx = mx * field.width
	local ty = my * field_old.height
	if e == "down" or e == "drag" then
		local span = 3
		for x = tx-span, tx+span do
			for y = ty-span, ty+span do
				field:set(coin(), x, y)
			end
		end
	end
end
