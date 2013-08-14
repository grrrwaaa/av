local ffi = require "ffi"
local lib = core

local glfw = require "glfw"
local gl = require "gl"

local debug_traceback = debug.traceback

print("define window")

local window = {
	fps = 60,
	running = true,
	width = 800,
	height = 600,
}
setmetatable(window, window)

function window:__tostring()
	return string.format("Window(%p)", self)
end

frame = 0
local firstdraw = false
local tprev = 0

function window.swap()
	dt = t - tprev
	tprev = t
	glfw.SwapBuffers()	-- implicly calls glfw.PollEvents()
	
	if glfw.GetWindowParam(glfw.OPENED) == 0 then
		-- call close handler?
		if close and type(close) == "function" then
			local ok, err = xpcall(function() close() end, debug_traceback)
			if not ok then 
				print("error in close()")
				print(debug_traceback(err)) 
			end	
		end
		window.running = false
		return
	end
	
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
	
	-- set up 2D mode by default
	--gl.Viewport(0, 0, w, h)
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
	
	if updating and update and type(update) == "function" then
		local ok, err = xpcall(function() update(dt) end, debug_traceback)
		if not ok then 
			print(debug_traceback(err)) 
			-- prevent error spew:
			update = nil
		end	
	end
	
	if draw and type(draw) == "function" then
		local ok, err = xpcall(function() draw(w, h) end, debug_traceback)
		if not ok then 
			print("error in draw")
			print(debug_traceback(err)) 
			-- prevent error spew:
			draw = nil
		end	
	end
	
	if glfw.GetWindowParam(glfw.OPENED) == 0 then
		window.running = false
	end	
	
	collectgarbage()
	
	frame = frame + 1
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

-- was getting segfaults until I made sure to pollevents (or swapbuffers) before anything else:
glfw.PollEvents()	

return window