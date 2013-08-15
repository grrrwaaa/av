local ffi = require "ffi"
local lib = core

local glfw = require "glfw"

local debug_traceback = debug.traceback

-- Get the desktop resolution.
local desktopMode = ffi.new("GLFWvidmode[1]")
glfw.GetDesktopMode(desktopMode)

local fullscreen_width = desktopMode[0].Width
local fullscreen_height = desktopMode[0].Height
local windowed_width = 800
local windowed_height = 600

local window = {
	fps = 60,
	running = true,
	stereo = 0,
	fsaa = 2,
	width = windowed_width,
	height = windowed_height,
	depthbits = 24,
	isfullscreen = false,
	isopen = false,
	title = "av",
}

function window:__tostring()
	return string.format("Window(%p)", self)
end

local
function window_init()

	if window.isopen then
		glfw.CloseWindow()
	end

	glfw.OpenWindowHint(glfw.STEREO, window.stereo)
	glfw.OpenWindowHint(glfw.WINDOW_NO_RESIZE, 0)
	glfw.OpenWindowHint(glfw.FSAA_SAMPLES, window.fsaa)
	--glfw.OpenWindowHint(glfw.OPENGL_VERSION_MAJOR, 3)
	--glfw.OpenWindowHint(glfw.OPENGL_VERSION_MINOR, 1)
	--glfw.OpenWindowHint(glfw.OPENGL_FORWARD_COMPAT, 1)
	--glfw.OpenWindowHint(glfw.OPENGL_DEBUG_CONTEXT, 1)
	
	local mode = window.isfullscreen and glfw.FULLSCREEN or glfw.WINDOW
	
	-- open stereo if possible:
	--glfw.OpenWindowHint(glfw.STEREO, 1)
	if glfw.OpenWindow(window.width, window.height, 0,0,0,0, window.depthbits,0, mode) == 0 then
		error("failed to open GLFW window")
	end
	window.isopen = true

	print("opened window", glfw.GetWindowParam(glfw.OPENED)) -- ACTIVE, ICONIFIED, ACCELERATED
	print("depth bits", glfw.GetWindowParam(glfw.DEPTH_BITS))
	print("refresh rate", glfw.GetWindowParam(glfw.REFRESH_RATE))
	print("stereo", glfw.GetWindowParam(glfw.STEREO))
	print("fsaa samples", glfw.GetWindowParam(glfw.FSAA_SAMPLES))
	print("OpenGL version", glfw.GetWindowParam(glfw.OPENGL_VERSION_MAJOR), glfw.GetWindowParam(glfw.OPENGL_VERSION_MINOR))

	local dim = ffi.new("int[2]")
	glfw.GetWindowSize(dim, dim+1)
	print("window dim", dim[0], dim[1])

	glfw.SetWindowTitle(window.title)
	--glfw.SetWindowSize(w, h)
	--glfw.SetWindowPos(0, 0)
	--glfw.Disable(glfw.MOUSE_CURSOR)

	-- enable vsync:
	glfw.SwapInterval(1)
	
	-- stop SwapBuffers from calling PollEvents():
	--glfw.Disable(glfw.AUTO_POLL_EVENTS)
end

window_init()

-- load gl after initializing window:
local gl = require "gl"


frame = 0
local firstdraw = false
local tprev = 0

window.swap = function()
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


setmetatable(window, {
	__index = function(self, k, v)
		if k == "fullscreen" then
			return window.isfullscreen
		else
			return self[k]
		end
	end,
	__newindex = function(self, k, v)
		if k == "fullscreen" then
			print("set fullscreen", v, window.isfullscreen)
			if window.isfullscreen and (not v) then
				-- leave fullscreen
				
				window.width = windowed_width
				window.height = windowed_height
				
				window.isfullscreen = false
				window_init()
			elseif (not window.isfullscreen) and v then
				-- enter fullscreen
				
				glfw.GetDesktopMode(desktopMode)
				
				window.width = desktopMode[0].Width
				window.height = desktopMode[0].Height
				
				print(window.width, window.height)
				
				window.isfullscreen = true
				window_init()
			end
		else
			self[k] = v
		end
	end
})


print("swap", window.swap)

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
--glfw.PollEvents()	

return window