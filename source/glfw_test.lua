local ffi = require "ffi"

local lib = ffi.C
if ffi.os == "Linux" then
	lib = ffi.load("glfw")
end

local src = [[
	
#define GLFW_VERSION_MAJOR    2
#define GLFW_VERSION_MINOR    7
#define GLFW_VERSION_REVISION 2


/*************************************************************************
 * Input handling definitions
 *************************************************************************/

/* Key and button state/action definitions */
#define GLFW_RELEASE            0
#define GLFW_PRESS              1

/* Keyboard key definitions: 8-bit ISO-8859-1 (Latin 1) encoding is used
 * for printable keys (such as A-Z, 0-9 etc), and values above 256
 * represent special (non-printable) keys (e.g. F1, Page Up etc).
 */
#define GLFW_KEY_UNKNOWN      -1
#define GLFW_KEY_SPACE        32
#define GLFW_KEY_SPECIAL      256
#define GLFW_KEY_ESC          (GLFW_KEY_SPECIAL+1)
#define GLFW_KEY_F1           (GLFW_KEY_SPECIAL+2)
#define GLFW_KEY_F2           (GLFW_KEY_SPECIAL+3)
#define GLFW_KEY_F3           (GLFW_KEY_SPECIAL+4)
#define GLFW_KEY_F4           (GLFW_KEY_SPECIAL+5)
#define GLFW_KEY_F5           (GLFW_KEY_SPECIAL+6)
#define GLFW_KEY_F6           (GLFW_KEY_SPECIAL+7)
#define GLFW_KEY_F7           (GLFW_KEY_SPECIAL+8)
#define GLFW_KEY_F8           (GLFW_KEY_SPECIAL+9)
#define GLFW_KEY_F9           (GLFW_KEY_SPECIAL+10)
#define GLFW_KEY_F10          (GLFW_KEY_SPECIAL+11)
#define GLFW_KEY_F11          (GLFW_KEY_SPECIAL+12)
#define GLFW_KEY_F12          (GLFW_KEY_SPECIAL+13)
#define GLFW_KEY_F13          (GLFW_KEY_SPECIAL+14)
#define GLFW_KEY_F14          (GLFW_KEY_SPECIAL+15)
#define GLFW_KEY_F15          (GLFW_KEY_SPECIAL+16)
#define GLFW_KEY_F16          (GLFW_KEY_SPECIAL+17)
#define GLFW_KEY_F17          (GLFW_KEY_SPECIAL+18)
#define GLFW_KEY_F18          (GLFW_KEY_SPECIAL+19)
#define GLFW_KEY_F19          (GLFW_KEY_SPECIAL+20)
#define GLFW_KEY_F20          (GLFW_KEY_SPECIAL+21)
#define GLFW_KEY_F21          (GLFW_KEY_SPECIAL+22)
#define GLFW_KEY_F22          (GLFW_KEY_SPECIAL+23)
#define GLFW_KEY_F23          (GLFW_KEY_SPECIAL+24)
#define GLFW_KEY_F24          (GLFW_KEY_SPECIAL+25)
#define GLFW_KEY_F25          (GLFW_KEY_SPECIAL+26)
#define GLFW_KEY_UP           (GLFW_KEY_SPECIAL+27)
#define GLFW_KEY_DOWN         (GLFW_KEY_SPECIAL+28)
#define GLFW_KEY_LEFT         (GLFW_KEY_SPECIAL+29)
#define GLFW_KEY_RIGHT        (GLFW_KEY_SPECIAL+30)
#define GLFW_KEY_LSHIFT       (GLFW_KEY_SPECIAL+31)
#define GLFW_KEY_RSHIFT       (GLFW_KEY_SPECIAL+32)
#define GLFW_KEY_LCTRL        (GLFW_KEY_SPECIAL+33)
#define GLFW_KEY_RCTRL        (GLFW_KEY_SPECIAL+34)
#define GLFW_KEY_LALT         (GLFW_KEY_SPECIAL+35)
#define GLFW_KEY_RALT         (GLFW_KEY_SPECIAL+36)
#define GLFW_KEY_TAB          (GLFW_KEY_SPECIAL+37)
#define GLFW_KEY_ENTER        (GLFW_KEY_SPECIAL+38)
#define GLFW_KEY_BACKSPACE    (GLFW_KEY_SPECIAL+39)
#define GLFW_KEY_INSERT       (GLFW_KEY_SPECIAL+40)
#define GLFW_KEY_DEL          (GLFW_KEY_SPECIAL+41)
#define GLFW_KEY_PAGEUP       (GLFW_KEY_SPECIAL+42)
#define GLFW_KEY_PAGEDOWN     (GLFW_KEY_SPECIAL+43)
#define GLFW_KEY_HOME         (GLFW_KEY_SPECIAL+44)
#define GLFW_KEY_END          (GLFW_KEY_SPECIAL+45)
#define GLFW_KEY_KP_0         (GLFW_KEY_SPECIAL+46)
#define GLFW_KEY_KP_1         (GLFW_KEY_SPECIAL+47)
#define GLFW_KEY_KP_2         (GLFW_KEY_SPECIAL+48)
#define GLFW_KEY_KP_3         (GLFW_KEY_SPECIAL+49)
#define GLFW_KEY_KP_4         (GLFW_KEY_SPECIAL+50)
#define GLFW_KEY_KP_5         (GLFW_KEY_SPECIAL+51)
#define GLFW_KEY_KP_6         (GLFW_KEY_SPECIAL+52)
#define GLFW_KEY_KP_7         (GLFW_KEY_SPECIAL+53)
#define GLFW_KEY_KP_8         (GLFW_KEY_SPECIAL+54)
#define GLFW_KEY_KP_9         (GLFW_KEY_SPECIAL+55)
#define GLFW_KEY_KP_DIVIDE    (GLFW_KEY_SPECIAL+56)
#define GLFW_KEY_KP_MULTIPLY  (GLFW_KEY_SPECIAL+57)
#define GLFW_KEY_KP_SUBTRACT  (GLFW_KEY_SPECIAL+58)
#define GLFW_KEY_KP_ADD       (GLFW_KEY_SPECIAL+59)
#define GLFW_KEY_KP_DECIMAL   (GLFW_KEY_SPECIAL+60)
#define GLFW_KEY_KP_EQUAL     (GLFW_KEY_SPECIAL+61)
#define GLFW_KEY_KP_ENTER     (GLFW_KEY_SPECIAL+62)
#define GLFW_KEY_KP_NUM_LOCK  (GLFW_KEY_SPECIAL+63)
#define GLFW_KEY_CAPS_LOCK    (GLFW_KEY_SPECIAL+64)
#define GLFW_KEY_SCROLL_LOCK  (GLFW_KEY_SPECIAL+65)
#define GLFW_KEY_PAUSE        (GLFW_KEY_SPECIAL+66)
#define GLFW_KEY_LSUPER       (GLFW_KEY_SPECIAL+67)
#define GLFW_KEY_RSUPER       (GLFW_KEY_SPECIAL+68)
#define GLFW_KEY_MENU         (GLFW_KEY_SPECIAL+69)
#define GLFW_KEY_LAST         GLFW_KEY_MENU

/* Mouse button definitions */
#define GLFW_MOUSE_BUTTON_1      0
#define GLFW_MOUSE_BUTTON_2      1
#define GLFW_MOUSE_BUTTON_3      2
#define GLFW_MOUSE_BUTTON_4      3
#define GLFW_MOUSE_BUTTON_5      4
#define GLFW_MOUSE_BUTTON_6      5
#define GLFW_MOUSE_BUTTON_7      6
#define GLFW_MOUSE_BUTTON_8      7
#define GLFW_MOUSE_BUTTON_LAST   GLFW_MOUSE_BUTTON_8

/* Mouse button aliases */
#define GLFW_MOUSE_BUTTON_LEFT   GLFW_MOUSE_BUTTON_1
#define GLFW_MOUSE_BUTTON_RIGHT  GLFW_MOUSE_BUTTON_2
#define GLFW_MOUSE_BUTTON_MIDDLE GLFW_MOUSE_BUTTON_3


/* Joystick identifiers */
#define GLFW_JOYSTICK_1          0
#define GLFW_JOYSTICK_2          1
#define GLFW_JOYSTICK_3          2
#define GLFW_JOYSTICK_4          3
#define GLFW_JOYSTICK_5          4
#define GLFW_JOYSTICK_6          5
#define GLFW_JOYSTICK_7          6
#define GLFW_JOYSTICK_8          7
#define GLFW_JOYSTICK_9          8
#define GLFW_JOYSTICK_10         9
#define GLFW_JOYSTICK_11         10
#define GLFW_JOYSTICK_12         11
#define GLFW_JOYSTICK_13         12
#define GLFW_JOYSTICK_14         13
#define GLFW_JOYSTICK_15         14
#define GLFW_JOYSTICK_16         15
#define GLFW_JOYSTICK_LAST       GLFW_JOYSTICK_16


/*************************************************************************
 * Other definitions
 *************************************************************************/

/* glfwOpenWindow modes */
#define GLFW_WINDOW               0x00010001
#define GLFW_FULLSCREEN           0x00010002

/* glfwGetWindowParam tokens */
#define GLFW_OPENED               0x00020001
#define GLFW_ACTIVE               0x00020002
#define GLFW_ICONIFIED            0x00020003
#define GLFW_ACCELERATED          0x00020004
#define GLFW_RED_BITS             0x00020005
#define GLFW_GREEN_BITS           0x00020006
#define GLFW_BLUE_BITS            0x00020007
#define GLFW_ALPHA_BITS           0x00020008
#define GLFW_DEPTH_BITS           0x00020009
#define GLFW_STENCIL_BITS         0x0002000A

/* The following constants are used for both glfwGetWindowParam
 * and glfwOpenWindowHint
 */
#define GLFW_REFRESH_RATE         0x0002000B
#define GLFW_ACCUM_RED_BITS       0x0002000C
#define GLFW_ACCUM_GREEN_BITS     0x0002000D
#define GLFW_ACCUM_BLUE_BITS      0x0002000E
#define GLFW_ACCUM_ALPHA_BITS     0x0002000F
#define GLFW_AUX_BUFFERS          0x00020010
#define GLFW_STEREO               0x00020011
#define GLFW_WINDOW_NO_RESIZE     0x00020012
#define GLFW_FSAA_SAMPLES         0x00020013
#define GLFW_OPENGL_VERSION_MAJOR 0x00020014
#define GLFW_OPENGL_VERSION_MINOR 0x00020015
#define GLFW_OPENGL_FORWARD_COMPAT 0x00020016
#define GLFW_OPENGL_DEBUG_CONTEXT 0x00020017
#define GLFW_OPENGL_PROFILE       0x00020018

/* GLFW_OPENGL_PROFILE tokens */
#define GLFW_OPENGL_CORE_PROFILE  0x00050001
#define GLFW_OPENGL_COMPAT_PROFILE 0x00050002

/* glfwEnable/glfwDisable tokens */
#define GLFW_MOUSE_CURSOR         0x00030001
#define GLFW_STICKY_KEYS          0x00030002
#define GLFW_STICKY_MOUSE_BUTTONS 0x00030003
#define GLFW_SYSTEM_KEYS          0x00030004
#define GLFW_KEY_REPEAT           0x00030005
#define GLFW_AUTO_POLL_EVENTS     0x00030006

/* glfwWaitThread wait modes */
#define GLFW_WAIT                 0x00040001
#define GLFW_NOWAIT               0x00040002

/* glfwGetJoystickParam tokens */
#define GLFW_PRESENT              0x00050001
#define GLFW_AXES                 0x00050002
#define GLFW_BUTTONS              0x00050003

/* glfwReadImage/glfwLoadTexture2D flags */
#define GLFW_NO_RESCALE_BIT       0x00000001 /* Only for glfwReadImage */
#define GLFW_ORIGIN_UL_BIT        0x00000002
#define GLFW_BUILD_MIPMAPS_BIT    0x00000004 /* Only for glfwLoadTexture2D */
#define GLFW_ALPHA_MAP_BIT        0x00000008

/* Time spans longer than this (seconds) are considered to be infinity */
#define GLFW_INFINITY 100000.0

]]

--[[
local enums = {}
local keys = {}
for k, v in src:gmatch("#define%s+([%w_]+)%s+([%w_%+%(%)]+)") do
	if enums[v] then
		-- alias:
		enums[k] = enums[v]
	elseif tonumber(v) then
		enums[k] = v
	else
		local name, op, num = v:match("([%w_]+)%s*(%p)%s*(%d+)")
		local v0 = enums[name]
		local v1 = tonumber(enums[name]) + tonumber(num)
		enums[k] = v1
	end
	keys[#keys+1] = k
end

table.sort(keys)

for i, k in ipairs(keys) do print(string.format("static const int %s = %s;", k, enums[k])) end
--]]

ffi.cdef[[

static const int GLFW_ACCELERATED = 0x00020004;
static const int GLFW_ACCUM_ALPHA_BITS = 0x0002000F;
static const int GLFW_ACCUM_BLUE_BITS = 0x0002000E;
static const int GLFW_ACCUM_GREEN_BITS = 0x0002000D;
static const int GLFW_ACCUM_RED_BITS = 0x0002000C;
static const int GLFW_ACTIVE = 0x00020002;
static const int GLFW_ALPHA_BITS = 0x00020008;
static const int GLFW_ALPHA_MAP_BIT = 0x00000008;
static const int GLFW_AUTO_POLL_EVENTS = 0x00030006;
static const int GLFW_AUX_BUFFERS = 0x00020010;
static const int GLFW_AXES = 0x00050002;
static const int GLFW_BLUE_BITS = 0x00020007;
static const int GLFW_BUILD_MIPMAPS_BIT = 0x00000004;
static const int GLFW_BUTTONS = 0x00050003;
static const int GLFW_DEPTH_BITS = 0x00020009;
static const int GLFW_FSAA_SAMPLES = 0x00020013;
static const int GLFW_FULLSCREEN = 0x00010002;
static const int GLFW_GREEN_BITS = 0x00020006;
static const int GLFW_ICONIFIED = 0x00020003;
static const int GLFW_INFINITY = 100000;
static const int GLFW_JOYSTICK_1 = 0;
static const int GLFW_JOYSTICK_10 = 9;
static const int GLFW_JOYSTICK_11 = 10;
static const int GLFW_JOYSTICK_12 = 11;
static const int GLFW_JOYSTICK_13 = 12;
static const int GLFW_JOYSTICK_14 = 13;
static const int GLFW_JOYSTICK_15 = 14;
static const int GLFW_JOYSTICK_16 = 15;
static const int GLFW_JOYSTICK_2 = 1;
static const int GLFW_JOYSTICK_3 = 2;
static const int GLFW_JOYSTICK_4 = 3;
static const int GLFW_JOYSTICK_5 = 4;
static const int GLFW_JOYSTICK_6 = 5;
static const int GLFW_JOYSTICK_7 = 6;
static const int GLFW_JOYSTICK_8 = 7;
static const int GLFW_JOYSTICK_9 = 8;
static const int GLFW_JOYSTICK_LAST = 15;
static const int GLFW_KEY_BACKSPACE = 295;
static const int GLFW_KEY_CAPS_LOCK = 320;
static const int GLFW_KEY_DEL = 297;
static const int GLFW_KEY_DOWN = 284;
static const int GLFW_KEY_END = 301;
static const int GLFW_KEY_ENTER = 294;
static const int GLFW_KEY_ESC = 257;
static const int GLFW_KEY_F1 = 258;
static const int GLFW_KEY_F10 = 267;
static const int GLFW_KEY_F11 = 268;
static const int GLFW_KEY_F12 = 269;
static const int GLFW_KEY_F13 = 270;
static const int GLFW_KEY_F14 = 271;
static const int GLFW_KEY_F15 = 272;
static const int GLFW_KEY_F16 = 273;
static const int GLFW_KEY_F17 = 274;
static const int GLFW_KEY_F18 = 275;
static const int GLFW_KEY_F19 = 276;
static const int GLFW_KEY_F2 = 259;
static const int GLFW_KEY_F20 = 277;
static const int GLFW_KEY_F21 = 278;
static const int GLFW_KEY_F22 = 279;
static const int GLFW_KEY_F23 = 280;
static const int GLFW_KEY_F24 = 281;
static const int GLFW_KEY_F25 = 282;
static const int GLFW_KEY_F3 = 260;
static const int GLFW_KEY_F4 = 261;
static const int GLFW_KEY_F5 = 262;
static const int GLFW_KEY_F6 = 263;
static const int GLFW_KEY_F7 = 264;
static const int GLFW_KEY_F8 = 265;
static const int GLFW_KEY_F9 = 266;
static const int GLFW_KEY_HOME = 300;
static const int GLFW_KEY_INSERT = 296;
static const int GLFW_KEY_KP_0 = 302;
static const int GLFW_KEY_KP_1 = 303;
static const int GLFW_KEY_KP_2 = 304;
static const int GLFW_KEY_KP_3 = 305;
static const int GLFW_KEY_KP_4 = 306;
static const int GLFW_KEY_KP_5 = 307;
static const int GLFW_KEY_KP_6 = 308;
static const int GLFW_KEY_KP_7 = 309;
static const int GLFW_KEY_KP_8 = 310;
static const int GLFW_KEY_KP_9 = 311;
static const int GLFW_KEY_KP_ADD = 315;
static const int GLFW_KEY_KP_DECIMAL = 316;
static const int GLFW_KEY_KP_DIVIDE = 312;
static const int GLFW_KEY_KP_ENTER = 318;
static const int GLFW_KEY_KP_EQUAL = 317;
static const int GLFW_KEY_KP_MULTIPLY = 313;
static const int GLFW_KEY_KP_NUM_LOCK = 319;
static const int GLFW_KEY_KP_SUBTRACT = 314;
static const int GLFW_KEY_LALT = 291;
static const int GLFW_KEY_LAST = 325;
static const int GLFW_KEY_LCTRL = 289;
static const int GLFW_KEY_LEFT = 285;
static const int GLFW_KEY_LSHIFT = 287;
static const int GLFW_KEY_LSUPER = 323;
static const int GLFW_KEY_MENU = 325;
static const int GLFW_KEY_PAGEDOWN = 299;
static const int GLFW_KEY_PAGEUP = 298;
static const int GLFW_KEY_PAUSE = 322;
static const int GLFW_KEY_RALT = 292;
static const int GLFW_KEY_RCTRL = 290;
static const int GLFW_KEY_REPEAT = 0x00030005;
static const int GLFW_KEY_RIGHT = 286;
static const int GLFW_KEY_RSHIFT = 288;
static const int GLFW_KEY_RSUPER = 324;
static const int GLFW_KEY_SCROLL_LOCK = 321;
static const int GLFW_KEY_SPACE = 32;
static const int GLFW_KEY_SPECIAL = 256;
static const int GLFW_KEY_TAB = 293;
static const int GLFW_KEY_UP = 283;
static const int GLFW_MOUSE_BUTTON_1 = 0;
static const int GLFW_MOUSE_BUTTON_2 = 1;
static const int GLFW_MOUSE_BUTTON_3 = 2;
static const int GLFW_MOUSE_BUTTON_4 = 3;
static const int GLFW_MOUSE_BUTTON_5 = 4;
static const int GLFW_MOUSE_BUTTON_6 = 5;
static const int GLFW_MOUSE_BUTTON_7 = 6;
static const int GLFW_MOUSE_BUTTON_8 = 7;
static const int GLFW_MOUSE_BUTTON_LAST = 7;
static const int GLFW_MOUSE_BUTTON_LEFT = 0;
static const int GLFW_MOUSE_BUTTON_MIDDLE = 2;
static const int GLFW_MOUSE_BUTTON_RIGHT = 1;
static const int GLFW_MOUSE_CURSOR = 0x00030001;
static const int GLFW_NOWAIT = 0x00040002;
static const int GLFW_NO_RESCALE_BIT = 0x00000001;
static const int GLFW_OPENED = 0x00020001;
static const int GLFW_OPENGL_COMPAT_PROFILE = 0x00050002;
static const int GLFW_OPENGL_CORE_PROFILE = 0x00050001;
static const int GLFW_OPENGL_DEBUG_CONTEXT = 0x00020017;
static const int GLFW_OPENGL_FORWARD_COMPAT = 0x00020016;
static const int GLFW_OPENGL_PROFILE = 0x00020018;
static const int GLFW_OPENGL_VERSION_MAJOR = 0x00020014;
static const int GLFW_OPENGL_VERSION_MINOR = 0x00020015;
static const int GLFW_ORIGIN_UL_BIT = 0x00000002;
static const int GLFW_PRESENT = 0x00050001;
static const int GLFW_PRESS = 1;
static const int GLFW_RED_BITS = 0x00020005;
static const int GLFW_REFRESH_RATE = 0x0002000B;
static const int GLFW_RELEASE = 0;
static const int GLFW_STENCIL_BITS = 0x0002000A;
static const int GLFW_STEREO = 0x00020011;
static const int GLFW_STICKY_KEYS = 0x00030002;
static const int GLFW_STICKY_MOUSE_BUTTONS = 0x00030003;
static const int GLFW_SYSTEM_KEYS = 0x00030004;
static const int GLFW_VERSION_MAJOR = 2;
static const int GLFW_VERSION_MINOR = 7;
static const int GLFW_VERSION_REVISION = 2;
static const int GLFW_WAIT = 0x00040001;
static const int GLFW_WINDOW = 0x00010001;
static const int GLFW_WINDOW_NO_RESIZE = 0x00020012;

typedef struct {
    int Width, Height;
    int RedBits, BlueBits, GreenBits;
} GLFWvidmode;
typedef struct {
    int Width, Height;
    int Format;
    int BytesPerPixel;
    unsigned char *Data;
} GLFWimage;
typedef int GLFWthread;
typedef void * GLFWmutex;
typedef void * GLFWcond;
typedef void ( * GLFWwindowsizefun)(int,int);
typedef int ( * GLFWwindowclosefun)(void);
typedef void ( * GLFWwindowrefreshfun)(void);
typedef void ( * GLFWmousebuttonfun)(int,int);
typedef void ( * GLFWmouseposfun)(int,int);
typedef void ( * GLFWmousewheelfun)(int);
typedef void ( * GLFWkeyfun)(int,int);
typedef void ( * GLFWcharfun)(int,int);
typedef void ( * GLFWthreadfun)(void *);
 int glfwInit( void );
 void glfwTerminate( void );
 void glfwGetVersion( int *major, int *minor, int *rev );
 int glfwOpenWindow( int width, int height, int redbits, int greenbits, int bluebits, int alphabits, int depthbits, int stencilbits, int mode );
 void glfwOpenWindowHint( int target, int hint );
 void glfwCloseWindow( void );
 void glfwSetWindowTitle( const char *title );
 void glfwGetWindowSize( int *width, int *height );
 void glfwSetWindowSize( int width, int height );
 void glfwSetWindowPos( int x, int y );
 void glfwIconifyWindow( void );
 void glfwRestoreWindow( void );
 void glfwSwapBuffers( void );
 void glfwSwapInterval( int interval );
 int glfwGetWindowParam( int param );
 void glfwSetWindowSizeCallback( GLFWwindowsizefun cbfun );
 void glfwSetWindowCloseCallback( GLFWwindowclosefun cbfun );
 void glfwSetWindowRefreshCallback( GLFWwindowrefreshfun cbfun );
 int glfwGetVideoModes( GLFWvidmode *list, int maxcount );
 void glfwGetDesktopMode( GLFWvidmode *mode );
 void glfwPollEvents( void );
 void glfwWaitEvents( void );
 int glfwGetKey( int key );
 int glfwGetMouseButton( int button );
 void glfwGetMousePos( int *xpos, int *ypos );
 void glfwSetMousePos( int xpos, int ypos );
 int glfwGetMouseWheel( void );
 void glfwSetMouseWheel( int pos );
 void glfwSetKeyCallback( GLFWkeyfun cbfun );
 void glfwSetCharCallback( GLFWcharfun cbfun );
 void glfwSetMouseButtonCallback( GLFWmousebuttonfun cbfun );
 void glfwSetMousePosCallback( GLFWmouseposfun cbfun );
 void glfwSetMouseWheelCallback( GLFWmousewheelfun cbfun );
 int glfwGetJoystickParam( int joy, int param );
 int glfwGetJoystickPos( int joy, float *pos, int numaxes );
 int glfwGetJoystickButtons( int joy, unsigned char *buttons, int numbuttons );
 double glfwGetTime( void );
 void glfwSetTime( double time );
 void glfwSleep( double time );
 int glfwExtensionSupported( const char *extension );
 void* glfwGetProcAddress( const char *procname );
 void glfwGetGLVersion( int *major, int *minor, int *rev );
 GLFWthread glfwCreateThread( GLFWthreadfun fun, void *arg );
 void glfwDestroyThread( GLFWthread ID );
 int glfwWaitThread( GLFWthread ID, int waitmode );
 GLFWthread glfwGetThreadID( void );
 GLFWmutex glfwCreateMutex( void );
 void glfwDestroyMutex( GLFWmutex mutex );
 void glfwLockMutex( GLFWmutex mutex );
 void glfwUnlockMutex( GLFWmutex mutex );
 GLFWcond glfwCreateCond( void );
 void glfwDestroyCond( GLFWcond cond );
 void glfwWaitCond( GLFWcond cond, GLFWmutex mutex, double timeout );
 void glfwSignalCond( GLFWcond cond );
 void glfwBroadcastCond( GLFWcond cond );
 int glfwGetNumberOfProcessors( void );
 void glfwEnable( int token );
 void glfwDisable( int token );
 int glfwReadImage( const char *name, GLFWimage *img, int flags );
 int glfwReadMemoryImage( const void *data, long size, GLFWimage *img, int flags );
 void glfwFreeImage( GLFWimage *img );
 int glfwLoadTexture2D( const char *name, int flags );
 int glfwLoadMemoryTexture2D( const void *data, long size, int flags );
 int glfwLoadTextureImage2D( GLFWimage *img, int flags );

]]

local m = {}

local function resolve(pre, k)
	return lib[pre..k]
end

local glfw = setmetatable(m, {
	__index = function(self, k)
		local ok, r = pcall(resolve, "glfw", k)
		if not ok then 
			ok, r = pcall(resolve, "GLFW_", k)
			if not ok then 
				r = lib[k]
			end
		end
		self[k] = r
		return r
	end,
})

local ver = ffi.new("int[3]")
glfw.GetVersion(ver, ver+1, ver+2)
print(string.format("GLFW version %s.%s (rev %s)", ver[0], ver[1], ver[2]))
assert(glfw.Init() == 1, "failed to initialize GLFW")




-- Get the desktop resolution.
local desktopMode = ffi.new("GLFWvidmode[1]")
glfw.GetDesktopMode(desktopMode)
desktopHeight = desktopMode[0].Height
desktopWidth = desktopMode[0].Width
local windowedWidth = 800
local windowedHeight = 600

glfw.OpenWindowHint(glfw.STEREO, 1)
glfw.OpenWindowHint(glfw.WINDOW_NO_RESIZE, 1)
glfw.OpenWindowHint(glfw.FSAA_SAMPLES, 4)
--glfw.OpenWindowHint(glfw.OPENGL_VERSION_MAJOR, 3)
--glfw.OpenWindowHint(glfw.OPENGL_VERSION_MINOR, 1)
--glfw.OpenWindowHint(glfw.OPENGL_FORWARD_COMPAT, 1)
--glfw.OpenWindowHint(glfw.OPENGL_DEBUG_CONTEXT, 1)

local w, h = windowedWidth, windowedHeight
local depthbits = 24
local fullscreen = false

-- open stereo if possible:
--glfw.OpenWindowHint(glfw.STEREO, 1)
if glfw.OpenWindow(w, h, 0,0,0,0, depthbits,0, fullscreen and glfw.FULLSCREEN or glfw.WINDOW) == 0 then
	-- fall back to mono:
	print("active stereo not available")
	glfw.OpenWindowHint(glfw.STEREO, 0)
	-- have to send the hints again, for some reason:
	--glfw.OpenWindowHint(glfw.WINDOW_NO_RESIZE, 1)
	glfw.OpenWindowHint(glfw.FSAA_SAMPLES, 4)
	assert(glfw.OpenWindow(w, h, 0,0,0,0, depthbits,0, fullscreen and glfw.FULLSCREEN or glfw.WINDOW) == 1, "failed to open GLFW window")
end

glfw.SetKeyCallback(function(id, state)
	print(id, state)
end)
glfw.SetCharCallback(function(id, state)
	print("char", id, state)
end)
glfw.SetMousePosCallback(function(x, y)
	print("mouse", x, y)
end)
glfw.SetMouseButtonCallback(function(btn, state)
	print("mousebutton", btn, state)
end)
glfw.SetMouseWheelCallback(function(pos)
	print("wheel", pos)
end)
glfw.SetWindowSizeCallback(function (width, height)
	w = width
	h = height
	print("resized")	
end)

glfw.SetWindowTitle("av")
--glfw.SetWindowSize(w, h)
glfw.SetWindowPos(0, 0)
--glfw.Disable(glfw.MOUSE_CURSOR)

-- enable vsync:
glfw.SwapInterval(1)

print("opened", glfw.GetWindowParam(glfw.OPENED)) -- ACTIVE, ICONIFIED, ACCELERATED
print("depth bits", glfw.GetWindowParam(glfw.DEPTH_BITS))
print("refresh rate", glfw.GetWindowParam(glfw.REFRESH_RATE))
print("stereo", glfw.GetWindowParam(glfw.STEREO))
print("fsaa samples", glfw.GetWindowParam(glfw.FSAA_SAMPLES))
print("OpenGL version", glfw.GetWindowParam(glfw.OPENGL_VERSION_MAJOR), glfw.GetWindowParam(glfw.OPENGL_VERSION_MINOR))

local dim = ffi.new("int[2]")
glfw.GetWindowSize(dim, dim+1)
print("dim", dim[0], dim[1])




-- stop SwapBuffers from calling PollEvents():
--glfw.Disable(glfw.AUTO_POLL_EVENTS)

-------------------------------

local gl = require "modules.gl"

local running = true
while running do
	-- was getting segfaults until I made sure to pollevents (or swapbuffers) before anything else:
	--glfw.PollEvents()
	glfw.SwapBuffers()	-- implicly calls glfw.PollEvents()
	-- special event handling:0
	if glfw.GetKey(glfw.KEY_ESC) == 1 then
		-- toggle fullscreen
		fullscreen = not fullscreen
		
		
		if fullscreen then
			w, h = desktopWidth, desktopHeight
		else
			w, h = windowedWidth, windowedHeight
		end
			
		--glfw.CloseWindow()
		-- have to send the hints again, for some reason:
		--glfw.OpenWindowHint(glfw.WINDOW_NO_RESIZE, 1)
		--glfw.OpenWindowHint(glfw.FSAA_SAMPLES, 4)
		--assert(glfw.OpenWindow(w, h, 0,0,0,0, depthbits,0, fullscreen and glfw.FULLSCREEN or glfw.WINDOW) == 1, "failed to open GLFW window")			
		
		glfw.SetWindowSize(w, h)
		glfw.SetWindowPos(0, 0)
	end
	
	if glfw.GetWindowParam(glfw.OPENED) == 0 then
		running = false
	end	
	
	collectgarbage()
	
	--gl.Viewport(0, 0, w, h)
	
	gl.Begin(gl.LINES)
		gl.Vertex(0, 0, 0)
		gl.Vertex(1, 1, 0)
	gl.End()
	
	
	
end

glfw.Terminate()

