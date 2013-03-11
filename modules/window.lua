--[[-- 
The Window module provides utilities for the OpenGL rendering window.

The window module will automatically *call back* into user code for certain events, if the following global functions are defined:

	function draw() 
		-- code to render to the window, called at frame rate
		-- the window can toggle full-screen mode using the Esc key
	end
	
	function update(dt)
		-- code to update simulation state, called at frame rate or faster
		-- the dt argument is the time between updates in seconds
		-- update can be toggled on and off using the spacebar
	end
	
	function mouse(event, button, x, y)
		-- event is either "down", "drag", "up" or "move"
		-- button identifies the button pressed
		-- x and y are the mouse coordinates (normalized to 0..1 in each axis)
	end
	
	function keydown(key)
		-- occurs when a key is pressed. 
		-- if the key is a printable character, key will be a string
		-- otherwise, key will be a numeric key code
	end
	
	function keyup(key)
		-- occurs when a key is released. 
		-- if the key is a printable character, key will be a string
		-- otherwise, key will be a numeric key code
	end
	
--]]
local ffi = require "ffi"
local lib = ffi.C

local gl = require "gl"

local Window = {}

function Window:__tostring()
	return string.format("Window(%p)", self)
end

local key_events = {
	"down",
	"up"
}

local mouse_events = {
	[0] = "down",
	"up",
	"drag",
	"move",
}

local t = lib.av_time()

function Window:__newindex(k, v)
	if k == "key" then
		--[[
		self.onkey:set(function(self, e, k)
			e = key_events[e]
			
			-- built-in keys:
			if e == "down" and k == 27 then
				-- fullscreen flip:
				self.fullscreen = not self.fullscreen
			end
		
			local ok, err = pcall(v, self, e, k)
			if not ok then print(debug.traceback(err)) end
		end)
		--]]
	elseif k == "draw" then
		--[[
		self.ondraw:set(function(self)
			
			collectgarbage()
			
			local t1 = lib.av_time()
			dt = t1 - t
			t = t1
			
			local w, h = self.width, self.height
			
			-- set up 2D mode by default:
			gl.Viewport(0, 0, w, h)
			gl.MatrixMode(lib.GL_PROJECTION)
			gl.LoadIdentity()
			gl.Ortho(0, w, h, 0, -100, 100)
			gl.MatrixMode(lib.GL_MODELVIEW)
			gl.LoadIdentity()

			local ok, err = pcall(v, self, w, h, dt)
			if not ok then print(debug.traceback(err)) end	
		end)
		--]]
	elseif k == "create" then
		self.oncreate:set(function(self)
			local ok, err = pcall(v, self)
			if not ok then print(debug.traceback(err)) end
		end)
		
	elseif k == "resize" then
		self.onresize:set(function(self, w, h)
			print("resize", w, h)
			local ok, err = pcall(v, self, w, h)
			if not ok then print(debug.traceback(err)) end
		end)
		
	elseif k == "visible" then
		self.onvisible:set(function(self, s)
			local ok, err = pcall(v, self, s)
			if not ok then print(debug.traceback(err)) end
		end)
		
	elseif k == "mouse" then
		--[[
		self.onmouse:set(function(self, e, b, x, y)
			local ok, err = pcall(v, self, mouse_events[e], b, x, self.height-y-1)
			if not ok then print(debug.traceback(err)) end
		end)
		--]]
	elseif k == "fullscreen" then
		self:setfullscreen(v)
		
	--[[
	elseif k == "title" then
		self:settitle(v)
		
	elseif k == "dim" then
		self:setdim(unpack(v))
	--]]	
	else
		error("cannot assign to Window: "..k)
	end
end

function Window:__index(k)
	if k == "fullscreen" then
		return self.is_fullscreen ~= 0
	elseif k == "dim" then
		return { self.width, self.height }
	else
		return Window[k]
	end
end

setmetatable(Window, {
	__index = function(self, k)
		Window[k] = lib["av_window_" .. k]
		return Window[k]
	end,
})

ffi.metatype("av_Window", Window)

local win = lib.av_window_create()
local updating = true

-- set default callbacks:
win.ondraw = function(self) 
	collectgarbage()
			
	local t1 = lib.av_time()
	dt = t1 - t
	t = t1
	
	if updating and update and type(update) == "function" then
		local ok, err = pcall(update, dt)
		if not ok then 
			print(debug.traceback(err)) 
			-- prevent error spew:
			update = nil
		end	
	end

	local w, h = self.width, self.height
	
	-- set up 2D mode by default
	-- (should we use 0..1 instead?)
	gl.Viewport(0, 0, w, h)
	gl.MatrixMode(lib.GL_PROJECTION)
	gl.LoadIdentity()
	gl.Ortho(0, 1, 1, 0, -100, 100)
	gl.MatrixMode(lib.GL_MODELVIEW)
	gl.LoadIdentity()

	if draw and type(draw) == "function" then
		local ok, err = pcall(draw, w, h)
		if not ok then 
			print(debug.traceback(err)) 
			-- prevent error spew:
			draw = nil
		end	
	end
end
win.oncreate = function(self) end
win.onkey = function(self, e, k) 
	e = key_events[e]
	if k > 31 and k < 127 then
		-- convert printable characters:
		k = string.char(k)
	end
	if e == "down" then
		-- built-in keys:
		if k == 27 then
			-- fullscreen flip:
			self.fullscreen = not self.fullscreen
		elseif k == " " then
			-- pause/play:
			updating = not updating
		end
		if keydown and type(keydown) == "function" then
			local ok, err = pcall(keydown, k)
			if not ok then print(debug.traceback(err)) end
		end
	elseif e == "up" then
		if keyup and type(keyup) == "function" then
			local ok, err = pcall(keyup, k)
			if not ok then print(debug.traceback(err)) end
		end
	end
	
	if key and type(key) == "function" then
		local ok, err = pcall(key, e, k)
		if not ok then print(debug.traceback(err)) end
	end
end
win.onmouse = function(self, e, b, x, y) 
	if mouse and type(mouse) == "function" then
		local ok, err = pcall(mouse, mouse_events[e], b, x / win.width, (self.height-y-1) / win.height)
		if not ok then print(debug.traceback(err)) end
	end
end
win.onvisible = function(self, s) end
win.onresize = function(self, w, h) end

return win