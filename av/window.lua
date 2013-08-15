local ffi = require "ffi"
local lib = core

local debug_traceback = debug.traceback

local gl = require "gl"
local glu = require "glu"
local glut = require "glut"

local win = {
	width = 800,
	height = 600,
	fps = 60,
}

local firstdraw = true

--[[

void av_window_settitle(av_Window * self, const char * name) {
	glutSetWindowTitle(name);
}

void av_window_setfullscreen(av_Window * self, int b) {
	win.reload = true;
	win.is_fullscreen = b;
	if (b) {
		glutFullScreen();
		glutSetCursor(GLUT_CURSOR_NONE);
	} else {
		glutReshapeWindow(win.non_fullscreen_width, win.non_fullscreen_height);
		glutSetCursor(GLUT_CURSOR_INHERIT);
	}
}


void av_window_setdim(av_Window * self, int x, int y) {
	glutReshapeWindow(x, y);
	glutPostRedisplay();
}

av_Window * av_window_create() {
	return &win;
}

void av_state_reset(void * self) {
	win.reset();
}

void getmodifiers() {
	int mod = glutGetModifiers();
	win.shift = mod & GLUT_ACTIVE_SHIFT;
	win.alt = mod & GLUT_ACTIVE_ALT;
	win.ctrl = mod & GLUT_ACTIVE_CTRL;
}

void onkeydown(unsigned char k, int x, int y) {
	getmodifiers();
	
	switch(k) {
		case 3: 	// ctrl-C
		case 17:	// ctrl-Q
			exit(0);
			return;
		//case 18:	// ctrl-R
		//	av_reload();
		//	return;
		default: {
			//printf("k %d s %d a %d c %d\n", k, win.shift, win.alt, win.ctrl);
			if (win.onkey) {
				(win.onkey)(&win, 1, k);
			}
		}
	}
}

void onkeyup(unsigned char k, int x, int y) {
	getmodifiers();
	if (win.onkey) {
		(win.onkey)(&win, 2, k);
	}
}

void onspecialkeydown(int key, int x, int y) {
	getmodifiers();
	
	// GLUT_KEY_LEFT
	#define CS(k) case GLUT_KEY_##k: key = AV_KEY_##k; break;
	switch(key){
		CS(LEFT) CS(UP) CS(RIGHT) CS(DOWN)
		CS(PAGE_UP) CS(PAGE_DOWN)
		CS(HOME) CS(END) CS(INSERT)

		CS(F1) CS(F2) CS(F3) CS(F4)
		CS(F5) CS(F6) CS(F7) CS(F8)
		CS(F9) CS(F10)	CS(F11) CS(F12)
	}
	#undef CS
	
	if (win.onkey) {
		(win.onkey)(&win, 1, key);
	}
}

void onspecialkeyup(int key, int x, int y) {
	getmodifiers();
	
	#define CS(k) case GLUT_KEY_##k: key = AV_KEY_##k; break;
	switch(key){
		CS(F1) CS(F2) CS(F3) CS(F4)
		CS(F5) CS(F6) CS(F7) CS(F8)
		CS(F9) CS(F10)	CS(F11) CS(F12)
		
		CS(LEFT) CS(UP) CS(RIGHT) CS(DOWN)
		CS(PAGE_UP) CS(PAGE_DOWN)
		CS(HOME) CS(END) CS(INSERT)
	}
	#undef CS
	
	if (win.onkey) {
		(win.onkey)(&win, 2, key);
	}
}

void onmouse(int button, int state, int x, int y) {
	getmodifiers();
	win.button = button;
	if (win.onmouse) {
		(win.onmouse)(&win, state, win.button, x, y);
	}
}

void onmotion(int x, int y) {
	if (win.onmouse) {
		(win.onmouse)(&win, 2, win.button, x, y);
	}
}

void onpassivemotion(int x, int y) {
	if (win.onmouse) {
		(win.onmouse)(&win, 3, win.button, x, y);
	}
}

void onvisibility(int state) {
	if (win.onvisible) (win.onvisible)(&win, state);
}
--]]

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

local function registerCallbacks()
	--[[
	glut.glutKeyboardFunc(onkeydown);
	glut.glutKeyboardUpFunc(onkeyup);
	glut.glutMouseFunc(onmouse);
	glut.glutMotionFunc(onmotion);
	glut.glutPassiveMotionFunc(onpassivemotion);
	glut.glutSpecialFunc(onspecialkeydown);
	glut.glutSpecialUpFunc(onspecialkeyup);
	glut.glutVisibilityFunc(onvisibility)
	
	--]]
	
	glut.glutReshapeFunc(onreshape)
	glut.glutDisplayFunc(ondisplay)
end

local windowed_width, windowed_height, windowed_id
function enter_fullscreen()
	print("enter fullscreen")
	windowed_width = win.width
	windowed_height = win.height
	if ffi.os == "OSX1" then
		glut.glutFullScreen()
	else
		-- destroy current context:
		if win.id and ondestroy then ondestroy() end
		-- go game mode
		local sw, sh = glut.glutGet(glut.GLUT_SCREEN_WIDTH), glut.glutGet(glut.GLUT_SCREEN_HEIGHT)
		print("full res", sw, sh)
		if sw == 0 or sh == 0 then sw, sh = 1024, 768 end
		glut.glutGameModeString(string.format("%dx%d:24", sw, sh))
		--print("refresh", glut.glutGameModeGet(glut.GLUT_GAME_MODE_REFRESH_RATE))
		
		win.id = glut.glutEnterGameMode()
		print("new id", win.id, "old id", windowed_id)
		glut.glutSetWindow(win.id)
		registerCallbacks()
		print("registered callbacks")
		firstdraw = true
		
		if win.oncreate then win:oncreate() end
		--onreshape(w, h)?
		-- hide/show to get focus for key callbacks:
		glut.glutHideWindow()
		glut.glutShowWindow()
	end
	glut.glutSetCursor(glut.GLUT_CURSOR_NONE)
	print("entered fullscreen")
end

function exit_fullscreen()
	print("exit fullscreen")
	if ffi.os == "OSX1" then
		glut.glutReshapeWindow(windowed_width, windowed_height)
	else
		-- destroy current context:
		if win.id and ondestroy then ondestroy() end
		
		glut.glutLeaveGameMode()
		win.id = glut.glutCreateWindow("")
		glut.glutSetWindow(win.id)
		registerCallbacks()
		firstdraw = true
		
		-- refresh:
		if win.oncreate then win:oncreate() end
		-- get new dimensions & call reshape?
		--onreshape(w, h)?
		
	end
	glut.glutSetCursor(glut.GLUT_CURSOR_NONE)
end

function win:redisplay()
	
	if firstdraw then
		print("firstdraw", glut.glutGetWindow())
		gl.Enable(gl.MULTISAMPLE)	
		gl.Enable(gl.POLYGON_SMOOTH)
		gl.Hint(gl.POLYGON_SMOOTH_HINT, gl.NICEST)
		gl.Enable(gl.LINE_SMOOTH)
		gl.Hint(gl.LINE_SMOOTH_HINT, gl.NICEST)
		gl.Enable(gl.POINT_SMOOTH)
		gl.Hint(gl.POINT_SMOOTH_HINT, gl.NICEST)
		glu.assert("hints")
		firstdraw = false
	end
	
	-- set up 2D mode by default
	-- (should we use 0..1 instead?)
	gl.Viewport(0, 0, win.width, win.height)
		glu.assert("viewport")
	
	if win.stereo then
		win.eye = "right"
		gl.DrawBuffer(gl.BACK_RIGHT)
		gl.Clear()
		if draw then 
			local ok, err = xpcall(draw, debug_traceback)
			if not ok then
				print(err)
				draw = nil
			end
		end
		win.eye = "left"
		gl.DrawBuffer(gl.BACK_LEFT)
		gl.Clear()
		if draw then 
			local ok, err = xpcall(draw, debug_traceback)
			if not ok then
				print(err)
				draw = nil
			end
		end
		win.eye = nil
		gl.DrawBuffer(gl.BACK)
	else
		
		glu.assert("preclear")
		gl.Clear()
		glu.assert("postclear")
		if draw then 
			local ok, err = xpcall(draw, debug_traceback)
			if not ok then
				print(err)
				draw = nil
			end
		end
	end
	
	glut.glutSwapBuffers()
	glut.glutPostRedisplay()
	
	return 1
end



function win:startloop(ontimer)
	if (win.stereo) then
		glut.glutInitDisplayString("rgb double depth>=16 alpha samples<=4 stereo")
	else
		glut.glutInitDisplayString("rgb double depth>=16 alpha samples<=4")
	end
	
	--glut.glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH); // | GLUT_MULTISAMPLE);
	glut.glutInitWindowSize(win.width, win.height);
	glut.glutInitWindowPosition(0, 0);
	
	if win.fullscreen then
		enter_fullscreen()
	else
		win.id = glut.glutCreateWindow("")
		windowed_id = win.id
	end
	glut.glutSetWindow(win.id)
	registerCallbacks()
	
	
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

	--]]
	
	core.av_glut_timerfunc(0)
	glut.glutMainLoop()
end

return win