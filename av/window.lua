local ffi = require "ffi"
local lib = core

local gl = require "gl"
local glut = require "glut"

local win = {
	width = 800,
	height = 600,
	fps = 60,
}

local function ondisplay() end

local function onreshape(w, h)
	win.width = w
	win.height = h
	--[[
	if (!win.is_fullscreen) {
		win.non_fullscreen_width = win.width;
		win.non_fullscreen_height = win.height;
	}
	if (win.onresize) {
		(win.onresize)(&win, w, h);
	}
	--]]
	glut.glutPostRedisplay()
end

local function timerfunc(id) 
	
	-- update window:
	if win.reload and win.oncreate then
		win.oncreate(win)
		win.reload = false
	end
	
	gl.Clear()
	if win.ondraw then win.ondraw(win) end
	
	glut.glutSwapBuffers()
	glut.glutPostRedisplay()
	
	glut.glutTimerFunc(1000/win.fps, timerfunc, 0)
end


function win:startloop()
	if (win.stereo) then
		glut.glutInitDisplayString("rgb double depth>=16 alpha samples<=4 stereo")
	else
		glut.glutInitDisplayString("rgb double depth>=16 alpha samples<=4")
	end
	
	--glut.glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH); // | GLUT_MULTISAMPLE);
	glut.glutInitWindowSize(win.width, win.height);
	glut.glutInitWindowPosition(0, 0);
	
	win.id = glut.glutCreateWindow("")
	glut.glutSetWindow(win.id)
	--[[
	// Force VSYNC on.
	#if defined AV_OSX
		GLint VBL = 1;
		CGLContextObj ctx = CGLGetCurrentContext();
		CGLSetParameter(ctx, kCGLCPSwapInterval, &VBL);
	#elif defined AV_LINUX
	#elif defined AV_WINDOWS
	#endif
	
	//	glut.glutIgnoreKeyRepeat(1);
//	glut.glutSetCursor(GLUT_CURSOR_NONE);

	glut.glutKeyboardFunc(onkeydown);
	glut.glutKeyboardUpFunc(onkeyup);
	glut.glutMouseFunc(onmouse);
	glut.glutMotionFunc(onmotion);
	glut.glutPassiveMotionFunc(onpassivemotion);
	glut.glutSpecialFunc(onspecialkeydown);
	glut.glutSpecialUpFunc(onspecialkeyup);
	glut.glutVisibilityFunc(onvisibility);
	glut.glutDisplayFunc(ondisplay);
	
	--]]
	
	glut.glutReshapeFunc(onreshape)
	glut.glutDisplayFunc(ondisplay)
	
	glut.glutTimerFunc(1000/win.fps, timerfunc, 0)
	
	glut.glutMainLoop()
end

return win