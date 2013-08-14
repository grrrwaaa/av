local ffi = require "ffi"

ffi.cdef[[

/* The video mode structure used by glfwGetVideoModes() */
typedef struct {
    int Width, Height;
    int RedBits, BlueBits, GreenBits;
} GLFWvidmode;

/* Image/texture information */
typedef struct {
    int Width, Height;
    int Format;
    int BytesPerPixel;
    unsigned char *Data;
} GLFWimage;

/* Thread ID */
typedef int GLFWthread;

/* Mutex object */
typedef void * GLFWmutex;

/* Condition variable object */
typedef void * GLFWcond;

/* Function pointer types */
typedef void (* GLFWwindowsizefun)(int,int);
typedef int  (* GLFWwindowclosefun)(void);
typedef void (* GLFWwindowrefreshfun)(void);
typedef void (* GLFWmousebuttonfun)(int,int);
typedef void (* GLFWmouseposfun)(int,int);
typedef void (* GLFWmousewheelfun)(int);
typedef void (* GLFWkeyfun)(int,int);
typedef void (* GLFWcharfun)(int,int);
typedef void (* GLFWthreadfun)(void *);


typedef struct glfw_functions_t {
	int (*Init)( void );
	void (*Terminate)( void );
	void (*GetVersion)( int *major, int *minor, int *rev );
	int (*OpenWindow)( int width, int height, int redbits, int greenbits, int bluebits, int alphabits, int depthbits, int stencilbits, int mode );
	void (*OpenWindowHint)( int target, int hint );
	void (*CloseWindow)( void );
	void (*SetWindowTitle)( const char *title );
	void (*GetWindowSize)( int *width, int *height );
	void (*SetWindowSize)( int width, int height );
	void (*SetWindowPos)( int x, int y );
	void (*IconifyWindow)( void );
	void (*RestoreWindow)( void );
	void (*SwapBuffers)( void );
	void (*SwapInterval)( int interval );
	int (*GetWindowParam)( int param );
	void (*SetWindowSizeCallback)( GLFWwindowsizefun cbfun );
	void (*SetWindowCloseCallback)( GLFWwindowclosefun cbfun );
	void (*SetWindowRefreshCallback)( GLFWwindowrefreshfun cbfun );
	int (*GetVideoModes)( GLFWvidmode *list, int maxcount );
	void (*GetDesktopMode)( GLFWvidmode *mode );
	void (*PollEvents)( void );
	void (*WaitEvents)( void );
	int (*GetKey)( int key );
	int (*GetMouseButton)( int button );
	void (*GetMousePos)( int *xpos, int *ypos );
	void (*SetMousePos)( int xpos, int ypos );
	int (*GetMouseWheel)( void );
	void (*SetMouseWheel)( int pos );
	void (*SetKeyCallback)( GLFWkeyfun cbfun );
	void (*SetCharCallback)( GLFWcharfun cbfun );
	void (*SetMouseButtonCallback)( GLFWmousebuttonfun cbfun );
	void (*SetMousePosCallback)( GLFWmouseposfun cbfun );
	void (*SetMouseWheelCallback)( GLFWmousewheelfun cbfun );
	int (*GetJoystickParam)( int joy, int param );
	int (*GetJoystickPos)( int joy, float *pos, int numaxes );
	int (*GetJoystickButtons)( int joy, unsigned char *buttons, int numbuttons );
	double (*GetTime)( void );
	void (*SetTime)( double time );
	void (*Sleep)( double time );
	int (*ExtensionSupported)( const char *extension );
	void (*GetGLVersion)( int *major, int *minor, int *rev );
	GLFWthread (*CreateThread)( GLFWthreadfun fun, void *arg );
	void (*DestroyThread)( GLFWthread ID );
	int (*WaitThread)( GLFWthread ID, int waitmode );
	GLFWthread (*GetThreadID)( void );
	GLFWmutex (*CreateMutex)( void );
	void (*DestroyMutex)( GLFWmutex mutex );
	void (*LockMutex)( GLFWmutex mutex );
	void (*UnlockMutex)( GLFWmutex mutex );
	GLFWcond (*CreateCond)( void );
	void (*DestroyCond)( GLFWcond cond );
	void (*WaitCond)( GLFWcond cond, GLFWmutex mutex, double timeout );
	void (*SignalCond)( GLFWcond cond );
	void (*BroadcastCond)( GLFWcond cond );
	int (*GetNumberOfProcessors)( void );
	void (*Enable)( int token );
	void (*Disable)( int token );
	int (*ReadImage)( const char *name, GLFWimage *img, int flags );
	int (*ReadMemoryImage)( const void *data, long size, GLFWimage *img, int flags );
	void (*FreeImage)( GLFWimage *img );
	int (*LoadTexture2D)( const char *name, int flags );
	int (*LoadMemoryTexture2D)( const void *data, long size, int flags );
	int (*LoadTextureImage2D)( GLFWimage *img, int flags );
	 int VERSION_MAJOR;
	 int VERSION_MINOR;
	 int VERSION_REVISION;
	 int RELEASE;
	 int PRESS;
	 int KEY_SPACE;
	 int KEY_SPECIAL;
	 int KEY_ESC;
	 int KEY_F1;
	 int KEY_F2;
	 int KEY_F3;
	 int KEY_F4;
	 int KEY_F5;
	 int KEY_F6;
	 int KEY_F7;
	 int KEY_F8;
	 int KEY_F9;
	 int KEY_F10;
	 int KEY_F11;
	 int KEY_F12;
	 int KEY_F13;
	 int KEY_F14;
	 int KEY_F15;
	 int KEY_F16;
	 int KEY_F17;
	 int KEY_F18;
	 int KEY_F19;
	 int KEY_F20;
	 int KEY_F21;
	 int KEY_F22;
	 int KEY_F23;
	 int KEY_F24;
	 int KEY_F25;
	 int KEY_UP;
	 int KEY_DOWN;
	 int KEY_LEFT;
	 int KEY_RIGHT;
	 int KEY_LSHIFT;
	 int KEY_RSHIFT;
	 int KEY_LCTRL;
	 int KEY_RCTRL;
	 int KEY_LALT;
	 int KEY_RALT;
	 int KEY_TAB;
	 int KEY_ENTER;
	 int KEY_BACKSPACE;
	 int KEY_INSERT;
	 int KEY_DEL;
	 int KEY_PAGEUP;
	 int KEY_PAGEDOWN;
	 int KEY_HOME;
	 int KEY_END;
	 int KEY_KP_0;
	 int KEY_KP_1;
	 int KEY_KP_2;
	 int KEY_KP_3;
	 int KEY_KP_4;
	 int KEY_KP_5;
	 int KEY_KP_6;
	 int KEY_KP_7;
	 int KEY_KP_8;
	 int KEY_KP_9;
	 int KEY_KP_DIVIDE;
	 int KEY_KP_MULTIPLY;
	 int KEY_KP_SUBTRACT;
	 int KEY_KP_ADD;
	 int KEY_KP_DECIMAL;
	 int KEY_KP_EQUAL;
	 int KEY_KP_ENTER;
	 int KEY_KP_NUM_LOCK;
	 int KEY_CAPS_LOCK;
	 int KEY_SCROLL_LOCK;
	 int KEY_PAUSE;
	 int KEY_LSUPER;
	 int KEY_RSUPER;
	 int KEY_MENU;
	 int KEY_LAST;
	 int MOUSE_BUTTON_1;
	 int MOUSE_BUTTON_2;
	 int MOUSE_BUTTON_3;
	 int MOUSE_BUTTON_4;
	 int MOUSE_BUTTON_5;
	 int MOUSE_BUTTON_6;
	 int MOUSE_BUTTON_7;
	 int MOUSE_BUTTON_8;
	 int MOUSE_BUTTON_LAST;
	 int MOUSE_BUTTON_LEFT;
	 int MOUSE_BUTTON_RIGHT;
	 int MOUSE_BUTTON_MIDDLE;
	 int JOYSTICK_1;
	 int JOYSTICK_2;
	 int JOYSTICK_3;
	 int JOYSTICK_4;
	 int JOYSTICK_5;
	 int JOYSTICK_6;
	 int JOYSTICK_7;
	 int JOYSTICK_8;
	 int JOYSTICK_9;
	 int JOYSTICK_10;
	 int JOYSTICK_11;
	 int JOYSTICK_12;
	 int JOYSTICK_13;
	 int JOYSTICK_14;
	 int JOYSTICK_15;
	 int JOYSTICK_16;
	 int JOYSTICK_LAST;
	 int WINDOW;
	 int FULLSCREEN;
	 int OPENED;
	 int ACTIVE;
	 int ICONIFIED;
	 int ACCELERATED;
	 int RED_BITS;
	 int GREEN_BITS;
	 int BLUE_BITS;
	 int ALPHA_BITS;
	 int DEPTH_BITS;
	 int STENCIL_BITS;
	 int REFRESH_RATE;
	 int ACCUM_RED_BITS;
	 int ACCUM_GREEN_BITS;
	 int ACCUM_BLUE_BITS;
	 int ACCUM_ALPHA_BITS;
	 int AUX_BUFFERS;
	 int STEREO;
	 int WINDOW_NO_RESIZE;
	 int FSAA_SAMPLES;
	 int OPENGL_VERSION_MAJOR;
	 int OPENGL_VERSION_MINOR;
	 int OPENGL_FORWARD_COMPAT;
	 int OPENGL_DEBUG_CONTEXT;
	 int OPENGL_PROFILE;
	 int OPENGL_CORE_PROFILE;
	 int OPENGL_COMPAT_PROFILE;
	 int MOUSE_CURSOR;
	 int STICKY_KEYS;
	 int STICKY_MOUSE_BUTTONS;
	 int SYSTEM_KEYS;
	 int KEY_REPEAT;
	 int AUTO_POLL_EVENTS;
	 int WAIT;
	 int NOWAIT;
	 int PRESENT;
	 int AXES;
	 int BUTTONS;
	 int NO_RESCALE_BIT;
	 int ORIGIN_UL_BIT;
	 int BUILD_MIPMAPS_BIT;
	 int ALPHA_MAP_BIT;
	 int INFINITY;
} glfw_functions_t;
glfw_functions_t * av_load_glfw();

]]

local glfw = core.av_load_glfw()

ffi.gc(glfw, function()
	glfw.CloseWindow()
	glfw.Terminate()
end)

print(string.format("using GLFW %s.%s (rev %s)", glfw.VERSION_MAJOR, glfw.VERSION_MINOR, glfw.VERSION_REVISION))
assert(glfw.Init() == 1, "failed to initialize GLFW")



local gl = require "gl"


--[[
glfw.SetKeyCallback(function(k, e)
	print(k, e)
	if k == glfw.KEY_ESC then
		-- toggle fullscreen
		fullscreen = not fullscreen
		print("fullscreen", fullscreen)
		
		if fullscreen then
			w, h = desktopWidth, desktopHeight
			
			glfw.CloseWindow()
			-- have to send the hints again, for some reason:
			glfw.OpenWindowHint(glfw.WINDOW_NO_RESIZE, 1)
			glfw.OpenWindowHint(glfw.FSAA_SAMPLES, 4)
			assert(glfw.OpenWindow(w, h, 0,0,0,0, depthbits,0, fullscreen and glfw.FULLSCREEN or glfw.WINDOW) == 1, "failed to open GLFW window")	
			
		else
			w, h = windowedWidth, windowedHeight
			
			glfw.CloseWindow()
			-- have to send the hints again, for some reason:
			glfw.OpenWindowHint(glfw.WINDOW_NO_RESIZE, 1)
			glfw.OpenWindowHint(glfw.FSAA_SAMPLES, 4)
			assert(glfw.OpenWindow(w, h, 0,0,0,0, depthbits,0, fullscreen and glfw.FULLSCREEN or glfw.WINDOW) == 1, "failed to open GLFW window")	
			
			
			glfw.SetWindowSize(w, h)
			glfw.SetWindowPos(0, 0)
			
		end
	end
end)
glfw.SetMousePosCallback(function(x, y)
	--print("mouse", x, y)
end)
glfw.SetMouseButtonCallback(function(btn, state)
	--print("mousebutton", btn, state)
end)
glfw.SetMouseWheelCallback(function(pos)
	--print("wheel", pos)
end)
glfw.SetWindowSizeCallback(function (width, height)
	w = width
	h = height
	--print("resized")	
end)
--]]

return glfw