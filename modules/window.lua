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
local firstdraw = true

-- set default callbacks:
win.ondraw = function(self) 
	collectgarbage()
	
	if firstdraw then
		gl.Enable(gl.MULTISAMPLE)	
		gl.Enable(gl.POLYGON_SMOOTH)
		gl.Hint(gl.POLYGON_SMOOTH_HINT, gl.NICEST)
		gl.Enable(gl.LINE_SMOOTH)
		gl.Hint(gl.LINE_SMOOTH_HINT, gl.NICEST)
		gl.Enable(gl.POINT_SMOOTH)
		gl.Hint(gl.POINT_SMOOTH_HINT, gl.NICEST)
		firstdraw = false
	end
			
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
	gl.Ortho(0, 1, 0, 1, -100, 100)
	gl.MatrixMode(lib.GL_MODELVIEW)
	gl.LoadIdentity()
	
	
	gl.Enable(gl.BLEND)
	gl.BlendEquationSeparate(gl.FUNC_ADD, gl.FUNC_ADD)
	gl.BlendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ZERO)
	
	gl.Disable(lib.GL_DEPTH_TEST)
	gl.Color(1, 1, 1)

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