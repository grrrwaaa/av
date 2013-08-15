local ffi = require "ffi"
local lib = core

local gl = require "gl"
local glut = require "glut"

local win = {
	width = 800,
	height = 600,
	fps = 60,
	
	ontimer = function() end,
}

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

local function timerfunc(id) 

	win.ontimer()
	
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


function win:startloop(ontimer)
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
	
	if win.fullscreen then
		glut.glutFullScreen()
		glut.glutSetCursor(glut.GLUT_CURSOR_NONE)
	end
	
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
	glut.glutVisibilityFunc(onvisibility)
	
	--]]
	
	glut.glutReshapeFunc(onreshape)
	glut.glutDisplayFunc(ondisplay)
	
	glut.glutTimerFunc(1000/win.fps, timerfunc, 0)
	
	glut.glutMainLoop()
end

return win