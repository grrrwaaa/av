#!av

local gl = require "gl"
local sketch = gl.sketch
local win = require "window"
local ffi = require "ffi"
local field2D = require "field2D"


function win:draw(w, h, dt)
	--print("fps", 1/dt)
	draw(w, h)
end

function win:key(e, k)
	
end

local min, max = math.min, math.max
local floor, ceil = math.floor, math.ceil
local random = math.random
function srandom() return random()*2-1 end
function round(x) return floor(x+0.5) end

local dim = 16*16

local field = field2D(dim)
print(field)

field0 = ffi.new(string.format("float[?][%d]", dim), dim)
field1 = ffi.new(string.format("float[?][%d]", dim), dim)
function reset()
	for x = 1, dim-2 do
		for y = 1, dim-2 do
			field0[x][y] = random() < 0.5 and 1 or 0
			field1[x][y] = field0[x][y]
		end
	end	
end
reset()

local goltex = 0

function init_gl()
	print("init gl")

	gl.ShadeModel(gl.FLAT)
	gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1)      -- 1-byte pixel alignment
	gl.PixelStorei(gl.PACK_ALIGNMENT, 1)        -- 1-byte pixel alignment
	gl.Enable(gl.TEXTURE_2D)
	gl.Disable(gl.LIGHTING)
	gl.ColorMaterial(gl.FRONT_AND_BACK, gl.AMBIENT_AND_DIFFUSE)
	gl.Enable(gl.COLOR_MATERIAL)
	
	goltex = gl.GenTextures(1)
	gl.BindTexture(gl.TEXTURE_2D, goltex)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.LUMINANCE, dim, dim, 0, gl.LUMINANCE, gl.FLOAT, field0)
	gl.BindTexture(gl.TEXTURE_2D, 0)
	
	print("goltex", goltex)
end

function win:create()
	init_gl()
end

function win:mouse(e, b, mx, my)
	--print(e, b, x, y)
	if e == "down" or e == "drag" then
		for x = mx-5, mx+5 do
			for y = my-5, my+5 do
				field0[((self.height-y)*dim/self.height)%dim][(x*dim/self.width)%dim] = random() < 0.5 and 1 or 0
			end
		end
	end
end

function rule(x, y, old, new)
	
	--print("x", x, (x+1)%dim, (x-1)%dim, "y", y, (y+1)%dim, (y-1)%dim)
	
	local C = old[x][y]
	local N = round(old[x][(y+1)%dim])
	local E = round(old[(x+1)%dim][y])
	local S = round(old[x][(y-1)%dim])
	local W = round(old[(x-1)%dim][y])
	local NE = round(old[(x+1)%dim][(y+1)%dim])
	local SE = round(old[(x+1)%dim][(y-1)%dim])
	local SW = round(old[(x-1)%dim][(y-1)%dim])
	local NW = round(old[(x-1)%dim][(y+1)%dim])
	
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
	new[x][y] = C
end

function draw(w, h)
	collectgarbage()
	
	sketch.enter_ortho(w, h)
	
	assert(gl.GetError() == gl.NO_ERROR)
	
	gl.BindTexture(gl.TEXTURE_2D, goltex)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.LUMINANCE, dim, dim, 0, gl.LUMINANCE, gl.FLOAT, field0)
	sketch.quad(0, 0, w, h)
	gl.BindTexture(gl.TEXTURE_2D, 0)
	assert(gl.GetError() == gl.NO_ERROR)
	
	-- iterate
	for x = 0, dim-1 do
		for y = 0, dim-1 do
			rule(x, y, field0, field1)
		end
	end
	
	-- swap:
	field0, field1 = field1, field0
	
	assert(gl.GetError() == gl.NO_ERROR)
	
	sketch.leave_ortho(w, h)
	
end