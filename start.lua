-- load in the "field2D" library module (from /modules/field2D.lua):
local field2D = require "field2D"

-- choose the size of the field
local dimx = 128
local dimy = dimx * 3/4 -- (with a 4:3 aspect ratio)

-- allocate the field
local field = field2D.new(dimx, dimy)

-- create a second field, to store the previous states of the cells:
local field_old = field2D.new(dimx, dimy)

-- create a function to return either 0 or 1
-- with a 50% chance of either (like flipping a coin)
function coin() 
	if math.random() < 0.5 then 
		return 0
	else
		return 1
	end
end

-- use this to initialize the field with random values:
-- (applies 'coin' to each cell of the field)
field:apply(coin)

-- how to render the scene (toggle fullscreen with the Esc key):
function draw()	
	-- draw the field:
	field:draw()
end

-- the rule for an individual cell (at position x, y) in the field:
function game_of_life(x, y)

	-- check out the neighbors' previous states:
	local N  = field_old:get(x  , y+1)
	local NE = field_old:get(x+1, y+1)
	local E  = field_old:get(x+1, y  )
	local SE = field_old:get(x+1, y-1)
	local S  = field_old:get(x  , y-1)
	local SW = field_old:get(x-1, y-1)
	local W  = field_old:get(x-1, y  )
	local NW = field_old:get(x-1, y+1)
	local near = N + E + S + W + NE + NW + SE + SW
	
	-- check my own previous state:
	local C = field_old:get(x, y)
	
	-- apply the rule:
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
	
	-- return the new state:
	return C
end

-- update the state of the scene (toggle this on and off with spacebar):
function update(dt)
	-- swap field and field_old:
	-- (field now becomes old, and the new field is ready to be written)
	field, field_old = field_old, field
	
	-- apply the game_of_life function to each cell of the field: 
	field:apply(game_of_life)
end

-- handle keypress events:
function keydown(k)
	if k == "c" then
		-- set all cells to zero:
		field:clear()
	elseif k == "r" then
		-- apply the coin rule to all cells of the field (randomizes)
		field:apply(coin)
	end
end


-- handle mouse events:
function mouse(event, btn, x, y)
	-- clicking & dragging should draw values into the field:
	if event == "down" or event == "drag" then
		
		-- scale window coords (0..1) up to the size of the field:
		local x = x * field.width
		local y = y * field.height
	
		-- spread the updates over a wide area:
		for i = 1, 10 do
			-- pick a random cell near to the mouse position:
			local span = 3
			local fx = x + math.random(span) - math.random(span)
			local fy = y + math.random(span) - math.random(span)
			
			-- set this cell to either 0 or 1:
			field:set(coin(), fx, fy)
		end
	end
end
