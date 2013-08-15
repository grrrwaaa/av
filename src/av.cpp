
#include <sys/socket.h>       /*  socket definitions        */
#include <sys/time.h> 
#include <sys/types.h>        /*  socket types              */
#include <sys/mman.h>
#include <netdb.h>
#include <fcntl.h>
#include <unistd.h>           /*  misc. UNIX functions      */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <time.h>

extern "C" {
	#include "lua.h"
	#include "lualib.h"
	#include "lauxlib.h"
}

#include "av.h"

////////////////////////////////////////////////////////////////
// TIME
////////////////////////////////////////////////////////////////

#ifdef AV_WINDOWS
	#include < time.h >
	#if defined(_MSC_VER) || defined(_MSC_EXTENSIONS)
	  #define DELTA_EPOCH_IN_MICROSECS  11644473600000000Ui64
	#else
	  #define DELTA_EPOCH_IN_MICROSECS  11644473600000000ULL
	#endif
	 
	struct timezone 
	{
	  int  tz_minuteswest; /* minutes W of Greenwich */
	  int  tz_dsttime;     /* type of dst correction */
	};
	 
	int gettimeofday(struct timeval *tv, struct timezone *tz)
	{
	  FILETIME ft;
	  unsigned __int64 tmpres = 0;
	  static int tzflag;
	 
	  if (NULL != tv)
	  {
		GetSystemTimeAsFileTime(&ft);
	 
		tmpres |= ft.dwHighDateTime;
		tmpres <<= 32;
		tmpres |= ft.dwLowDateTime;
	 
		/*converting file time to unix epoch*/
		tmpres -= DELTA_EPOCH_IN_MICROSECS; 
		tmpres /= 10;  /*convert into microseconds*/
		tv->tv_sec = (long)(tmpres / 1000000UL);
		tv->tv_usec = (long)(tmpres % 1000000UL);
	  }
	 
	  if (NULL != tz)
	  {
		if (!tzflag)
		{
		  _tzset();
		  tzflag++;
		}
		tz->tz_minuteswest = _timezone / 60;
		tz->tz_dsttime = _daylight;
	  }
	 
	  return 0;
	}
#endif

double av_now() {

	/*
		timeval t;
		gettimeofday(&t, NULL);
		return (double)t.tv_sec + (((double)t.tv_usec) * 1.0e-6);
	*/
	#ifdef __APPLE__
		static double timeConvert = 0.0;
		if ( timeConvert == 0.0 )
		{
			mach_timebase_info_data_t timeBase;
			(void)mach_timebase_info( &timeBase );
			timeConvert = (double)timeBase.numer /
				(double)timeBase.denom /
				1000000000.0;
		}
		return (double)mach_absolute_time( ) * timeConvert;
	#else
		struct timespec clocktime;
		clock_gettime(CLOCK_MONOTONIC, &clocktime);
		return clocktime.tv_sec + clocktime.tv_nsec * 1.0e-9;
	#endif	
		
}	

void av_sleep(double seconds) {
	#ifdef AV_WINDOWS
		Sleep((DWORD)(seconds * 1.0e3));
	#else
		time_t sec = (time_t)seconds;
		long long int nsec = 1.0e9 * (seconds - (double)sec);
		timespec tspec = { sec, nsec };
		while (nanosleep(&tspec, &tspec) == -1) {
			continue;
		}
	#endif
}

#ifdef AV_WINDOWS
	time_t TimeFromSystemTime(const SYSTEMTIME * pTime) {
		struct tm tm;
		memset(&tm, 0, sizeof(tm));
		tm.tm_year = pTime->wYear - 1900;
		tm.tm_mon = pTime->wMonth - 1;
		tm.tm_mday = pTime->wDay;
		tm.tm_hour = pTime->wHour;
		tm.tm_min = pTime->wMinute;
		tm.tm_sec = pTime->wSecond;
		return mktime(&tm);
	}
#endif

double av_filetime(const char * filename) {
	#ifdef AV_WINDOWS
		FILETIME modtime;
		SYSTEMTIME st;
		HANDLE fh = CreateFile(filename, GENERIC_READ, 0, NULL, OPEN_EXISTING, 0, NULL);
		double result = 0;
		if (GetFileTime(fh, NULL, NULL, &modtime) == 0) {
			printf("failed to stat %s\n", filename);
		} else {
			FileTimeToSystemTime(&modtime, &st);
			result = TimeFromSystemTime(&st);
		}
		CloseHandle(fh);
		return result;
	#else
		struct stat foo;
		time_t mtime;
		if (stat(filename, &foo) < 0) {
			fprintf(stderr, "failed to stat %s\n", filename);
			return 0;
		} else {
			mtime = foo.st_mtime; /* seconds since the epoch */
			return mtime;
		}
	#endif
}


////////////////////////////////////////////////////////////////
// EVENT
////////////////////////////////////////////////////////////////

void setnonblocking(int fd) {
	int flags;
	if (-1 == (flags = fcntl(fd, F_GETFL, 0))) {
		flags = 0;
		if (fcntl(fd, F_SETFL, flags | O_NONBLOCK)) { 
			fprintf(stderr, "%s\n", strerror( errno ));
		}
	}	
}

av_loop_t * av_loop_new() {
	av_loop_t * loop;
	int q;
	
	q = AV_POLL_CREATE(100);
	setnonblocking(q);
	if (q == -1) {
		fprintf(stderr, "failed to create epoll/kqueue");
		fprintf(stderr, "%s\n", strerror( errno ));
	}
	
	loop = (av_loop_t *)calloc(1, sizeof(av_loop_t));
	loop->queue = q;
	loop->numevents = 0;
	loop->events = (av_event_t *)calloc(AV_MAXEVENTS, sizeof(av_event_t));
	return loop;
}

void av_loop_destroy(av_loop_t * loop) {
	//printf("freeing loop %p\n", loop);
	close(loop->queue);
	free(loop->events);
	free(loop);
}

AV_POLL_EVENT newevent;

int av_loop_add_fd_in(av_loop_t * loop, int fd) {
	int res = 0;
	
	#ifdef AV_POLL_USE_KQUEUE
	EV_SET(&newevent, fd, EVFILT_READ, EV_ADD, 0, 0, NULL);
	res = kevent(loop->queue, &newevent, 1, NULL, 0, NULL) == -1;
	#endif
	
	#ifdef AV_POLL_USE_EPOLL
	newevent.data.fd = fd;
	newevent.events = EPOLLIN;
	res = epoll_ctl(loop->queue, EPOLL_CTL_ADD, fd, &newevent);
	#endif
	
	if (res != 0) {
		fprintf(stderr, "%s\n", strerror( errno ));
	}
	return res;
}

int av_loop_add_fd_out(av_loop_t * loop, int fd) {
	int res = 0;
	
	#ifdef AV_POLL_USE_KQUEUE
	EV_SET(&newevent, fd, EVFILT_WRITE, EV_ADD, 0, 0, NULL);
	res = kevent(loop->queue, &newevent, 1, NULL, 0, NULL) == -1;
	#endif
	
	#ifdef AV_POLL_USE_EPOLL
	newevent.data.fd = fd;
	newevent.events = EPOLLOUT;
	res = epoll_ctl(loop->queue, EPOLL_CTL_ADD, fd, &newevent);
	#endif
	
	if (res != 0) {
		fprintf(stderr, "%s\n", strerror( errno ));
	}
	return res;
}

int av_loop_remove_fd_in(av_loop_t * loop, int fd) {
	int res = 0;
	
	#ifdef AV_POLL_USE_KQUEUE
	EV_SET(&newevent, fd, EVFILT_READ, EV_DELETE, 0, 0, NULL);
	res = kevent(loop->queue, &newevent, 1, NULL, 0, NULL) == -1;
	#endif
	
	#ifdef AV_POLL_USE_EPOLL
	newevent.data.fd = fd;
	newevent.events = EPOLLIN;
	res = epoll_ctl(loop->queue, EPOLL_CTL_DEL, fd, &newevent);
	#endif
	
	if (res != 0) {
		fprintf(stderr, "%s\n", strerror( errno ));
	}
	return res;
}

int av_loop_remove_fd_out(av_loop_t * loop, int fd) {
	int res = 0;
	
	#ifdef AV_POLL_USE_KQUEUE
	EV_SET(&newevent, fd, EVFILT_WRITE, EV_DELETE, 0, 0, NULL);
	res = kevent(loop->queue, &newevent, 1, NULL, 0, NULL) == -1;
	#endif
	
	#ifdef AV_POLL_USE_EPOLL
	newevent.data.fd = fd;
	newevent.events = EPOLLOUT;
	res = epoll_ctl(loop->queue, EPOLL_CTL_DEL, fd, &newevent);
	#endif
	
	if (res != 0) {
		fprintf(stderr, "%s\n", strerror( errno ));
	}
	return res;
}

AV_POLL_EVENT change[64];

int av_loop_run_once(av_loop_t * loop, double seconds) {
	int nev, fd;
	av_event_t * events = loop->events;
	
	#ifdef AV_POLL_USE_KQUEUE
	struct timespec timeout;
	timeout.tv_sec = seconds;
	timeout.tv_nsec = (seconds - (long)seconds) * 1.0e9;
	nev = kevent(loop->queue, NULL, 0, change, AV_MAXEVENTS, &timeout);
	#endif
	
	#ifdef AV_POLL_USE_EPOLL
	int timeout = seconds * 1000.;
	nev = epoll_wait(loop->queue, change, AV_MAXEVENTS, timeout);
	#endif
	
	for (int i=0; i<nev; i++) {
		#ifdef AV_POLL_USE_KQUEUE
		fd = change[i].ident;
		events[i].fd = fd;
		if ((change[i].flags & EV_ERROR) != 0) {
			fprintf(stderr, "%s\n", strerror( errno ));
		} else if ((change[i].flags & EV_EOF) != 0) {
			// file closed.
			printf("warning: closing %d\n", fd);
			events[i].type = AV_EVENT_TYPE_CLOSE;
			close(fd); // safe assumption?
		//} else if (change[i].filter == EVFILT_TIMER) {
		//	events[i].type = AV_EVENT_TYPE_TIMER;
		} else {
			events[i].type = AV_EVENT_TYPE_READ;
		}
		#endif
		
		#ifdef AV_POLL_USE_EPOLL
		fd = change[i].data.fd;
		events[i].fd = fd;
		if (change[i].events & EPOLLERR) {
			fprintf(stderr, "%s\n", strerror( errno ));
		} else if (change[i].events & EPOLLHUP) {
			// file closed.
			events[i].type = AV_EVENT_TYPE_CLOSE;
			close(fd); // safe assumption?
		} else if (change[i].events & EPOLLIN) {
			events[i].type = AV_EVENT_TYPE_READ;
		}
		#endif
	}
	return nev;
}


////////////////////////////////////////////////////////////////
// WINDOW
////////////////////////////////////////////////////////////////

// implement av_Window using GLUT:
struct av_Window_GLUT : public av_Window {
	
	// GLUT specific:
	int id;
	int non_fullscreen_width, non_fullscreen_height;
	bool reload;
	
	av_Window_GLUT() {
		width = 720;
		height = 480;
		is_fullscreen = 0;
		is_stereo = 0;
		reset();
	}
	
	void reset() {
		shift = alt = ctrl = 0;
		fps = 60;
		oncreate = 0;
		onresize = 0;
		onvisible = 0;
		ondraw = 0;
		onkey = 0;
		onmouse = 0;
		id = 0;
		non_fullscreen_width = width;
		non_fullscreen_height = height;
		reload = true;
	}
};


// the window
av_Window_GLUT win;

void timerfunc(int id) {
	
	// update window:
	if (win.reload && win.oncreate) {
		(win.oncreate)(&win);
		win.reload = false;
	}
	
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	if (win.ondraw) {
		(win.ondraw)(&win);
	}	
	glutSwapBuffers();
	glutPostRedisplay();
	
	// reschedule:
	glutTimerFunc((unsigned int)(1000.0/win.fps), timerfunc, 0);
}

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




void gluterr( const char *fmt, va_list ap) {

}

/*
	// configure GLUT:
	glutInit(&argc, argv);
	
	// parse any special arguments:
	int firstarg = 1;
	while (firstarg < argc) {
		if (strcmp(argv[firstarg], "stereo") == 0) {
			printf("enabling stereo\n");
			win.is_stereo = 1;
			firstarg++;
		} else {
			break;
		}
	}
	
	if (win.is_stereo) {
		glutInitDisplayString("rgb double depth>=16 alpha samples<=4 stereo");
	} else {	
		glutInitDisplayString("rgb double depth>=16 alpha samples<=4");
	}
	//glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH); // | GLUT_MULTISAMPLE);
	glutInitWindowSize(win.width, win.height);
	glutInitWindowPosition(0, 0);
	
	win.id = glutCreateWindow("");
	glutSetWindow(win.id);
	
	// Force VSYNC on.
	#if defined AV_OSX
		GLint VBL = 1;
		CGLContextObj ctx = CGLGetCurrentContext();
		CGLSetParameter(ctx, kCGLCPSwapInterval, &VBL);
	#elif defined AV_LINUX
	#elif defined AV_WINDOWS
	#endif
	
		
//	glutIgnoreKeyRepeat(1);
//	glutSetCursor(GLUT_CURSOR_NONE);

	glutKeyboardFunc(onkeydown);
	glutKeyboardUpFunc(onkeyup);
	glutMouseFunc(onmouse);
	glutMotionFunc(onmotion);
	glutPassiveMotionFunc(onpassivemotion);
	glutSpecialFunc(onspecialkeydown);
	glutSpecialUpFunc(onspecialkeyup);
	glutVisibilityFunc(onvisibility);
	glutReshapeFunc(onreshape);
	glutDisplayFunc(ondisplay);
	
	// start it up:
	glutTimerFunc((unsigned int)(1000.0/win.fps), timerfunc, 0);
	//atexit(terminate);
	glutMainLoop();
	
*/


/*

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
	 int WINDOW_AV_RESIZE;
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
	 int AV_RESCALE_BIT;
	 int ORIGIN_UL_BIT;
	 int BUILD_MIPMAPS_BIT;
	 int ALPHA_MAP_BIT;
	 int INFINITY;
} glfw_functions_t;
extern "C" glfw_functions_t * av_load_glfw();

glfw_functions_t glfw;
glfw_functions_t * av_load_glfw() {
	glfw.Init = glfwInit;
	glfw.Terminate = glfwTerminate;
	glfw.GetVersion = glfwGetVersion;
	glfw.OpenWindow = glfwOpenWindow;
	glfw.OpenWindowHint = glfwOpenWindowHint;
	glfw.CloseWindow = glfwCloseWindow;
	glfw.SetWindowTitle = glfwSetWindowTitle;
	glfw.GetWindowSize = glfwGetWindowSize;
	glfw.SetWindowSize = glfwSetWindowSize;
	glfw.SetWindowPos = glfwSetWindowPos;
	glfw.IconifyWindow = glfwIconifyWindow;
	glfw.RestoreWindow = glfwRestoreWindow;
	glfw.SwapBuffers = glfwSwapBuffers;
	glfw.SwapInterval = glfwSwapInterval;
	glfw.GetWindowParam = glfwGetWindowParam;
	glfw.SetWindowSizeCallback = glfwSetWindowSizeCallback;
	glfw.SetWindowCloseCallback = glfwSetWindowCloseCallback;
	glfw.SetWindowRefreshCallback = glfwSetWindowRefreshCallback;
	glfw.GetVideoModes = glfwGetVideoModes;
	glfw.GetDesktopMode = glfwGetDesktopMode;
	glfw.PollEvents = glfwPollEvents;
	glfw.WaitEvents = glfwWaitEvents;
	glfw.GetKey = glfwGetKey;
	glfw.GetMouseButton = glfwGetMouseButton;
	glfw.GetMousePos = glfwGetMousePos;
	glfw.SetMousePos = glfwSetMousePos;
	glfw.GetMouseWheel = glfwGetMouseWheel;
	glfw.SetMouseWheel = glfwSetMouseWheel;
	glfw.SetKeyCallback = glfwSetKeyCallback;
	glfw.SetCharCallback = glfwSetCharCallback;
	glfw.SetMouseButtonCallback = glfwSetMouseButtonCallback;
	glfw.SetMousePosCallback = glfwSetMousePosCallback;
	glfw.SetMouseWheelCallback = glfwSetMouseWheelCallback;
	glfw.GetJoystickParam = glfwGetJoystickParam;
	glfw.GetJoystickPos = glfwGetJoystickPos;
	glfw.GetJoystickButtons = glfwGetJoystickButtons;
	glfw.GetTime = glfwGetTime;
	glfw.SetTime = glfwSetTime;
	glfw.Sleep = glfwSleep;
	glfw.ExtensionSupported = glfwExtensionSupported;
	glfw.GetGLVersion = glfwGetGLVersion;
	glfw.CreateThread = glfwCreateThread;
	glfw.DestroyThread = glfwDestroyThread;
	glfw.WaitThread = glfwWaitThread;
	glfw.GetThreadID = glfwGetThreadID;
	glfw.CreateMutex = glfwCreateMutex;
	glfw.DestroyMutex = glfwDestroyMutex;
	glfw.LockMutex = glfwLockMutex;
	glfw.UnlockMutex = glfwUnlockMutex;
	glfw.CreateCond = glfwCreateCond;
	glfw.DestroyCond = glfwDestroyCond;
	glfw.WaitCond = glfwWaitCond;
	glfw.SignalCond = glfwSignalCond;
	glfw.BroadcastCond = glfwBroadcastCond;
	glfw.GetNumberOfProcessors = glfwGetNumberOfProcessors;
	glfw.Enable = glfwEnable;
	glfw.Disable = glfwDisable;
	glfw.ReadImage = glfwReadImage;
	glfw.ReadMemoryImage = glfwReadMemoryImage;
	glfw.FreeImage = glfwFreeImage;
	glfw.LoadTexture2D = glfwLoadTexture2D;
	glfw.LoadMemoryTexture2D = glfwLoadMemoryTexture2D;
	glfw.LoadTextureImage2D = glfwLoadTextureImage2D;
	glfw.VERSION_MAJOR = GLFW_VERSION_MAJOR;
	glfw.VERSION_MINOR = GLFW_VERSION_MINOR;
	glfw.VERSION_REVISION = GLFW_VERSION_REVISION;
	glfw.RELEASE = GLFW_RELEASE;
	glfw.PRESS = GLFW_PRESS;
	glfw.KEY_SPACE = GLFW_KEY_SPACE;
	glfw.KEY_SPECIAL = GLFW_KEY_SPECIAL;
	glfw.KEY_ESC = GLFW_KEY_ESC;
	glfw.KEY_F1 = GLFW_KEY_F1;
	glfw.KEY_F2 = GLFW_KEY_F2;
	glfw.KEY_F3 = GLFW_KEY_F3;
	glfw.KEY_F4 = GLFW_KEY_F4;
	glfw.KEY_F5 = GLFW_KEY_F5;
	glfw.KEY_F6 = GLFW_KEY_F6;
	glfw.KEY_F7 = GLFW_KEY_F7;
	glfw.KEY_F8 = GLFW_KEY_F8;
	glfw.KEY_F9 = GLFW_KEY_F9;
	glfw.KEY_F10 = GLFW_KEY_F10;
	glfw.KEY_F11 = GLFW_KEY_F11;
	glfw.KEY_F12 = GLFW_KEY_F12;
	glfw.KEY_F13 = GLFW_KEY_F13;
	glfw.KEY_F14 = GLFW_KEY_F14;
	glfw.KEY_F15 = GLFW_KEY_F15;
	glfw.KEY_F16 = GLFW_KEY_F16;
	glfw.KEY_F17 = GLFW_KEY_F17;
	glfw.KEY_F18 = GLFW_KEY_F18;
	glfw.KEY_F19 = GLFW_KEY_F19;
	glfw.KEY_F20 = GLFW_KEY_F20;
	glfw.KEY_F21 = GLFW_KEY_F21;
	glfw.KEY_F22 = GLFW_KEY_F22;
	glfw.KEY_F23 = GLFW_KEY_F23;
	glfw.KEY_F24 = GLFW_KEY_F24;
	glfw.KEY_F25 = GLFW_KEY_F25;
	glfw.KEY_UP = GLFW_KEY_UP;
	glfw.KEY_DOWN = GLFW_KEY_DOWN;
	glfw.KEY_LEFT = GLFW_KEY_LEFT;
	glfw.KEY_RIGHT = GLFW_KEY_RIGHT;
	glfw.KEY_LSHIFT = GLFW_KEY_LSHIFT;
	glfw.KEY_RSHIFT = GLFW_KEY_RSHIFT;
	glfw.KEY_LCTRL = GLFW_KEY_LCTRL;
	glfw.KEY_RCTRL = GLFW_KEY_RCTRL;
	glfw.KEY_LALT = GLFW_KEY_LALT;
	glfw.KEY_RALT = GLFW_KEY_RALT;
	glfw.KEY_TAB = GLFW_KEY_TAB;
	glfw.KEY_ENTER = GLFW_KEY_ENTER;
	glfw.KEY_BACKSPACE = GLFW_KEY_BACKSPACE;
	glfw.KEY_INSERT = GLFW_KEY_INSERT;
	glfw.KEY_DEL = GLFW_KEY_DEL;
	glfw.KEY_PAGEUP = GLFW_KEY_PAGEUP;
	glfw.KEY_PAGEDOWN = GLFW_KEY_PAGEDOWN;
	glfw.KEY_HOME = GLFW_KEY_HOME;
	glfw.KEY_END = GLFW_KEY_END;
	glfw.KEY_KP_0 = GLFW_KEY_KP_0;
	glfw.KEY_KP_1 = GLFW_KEY_KP_1;
	glfw.KEY_KP_2 = GLFW_KEY_KP_2;
	glfw.KEY_KP_3 = GLFW_KEY_KP_3;
	glfw.KEY_KP_4 = GLFW_KEY_KP_4;
	glfw.KEY_KP_5 = GLFW_KEY_KP_5;
	glfw.KEY_KP_6 = GLFW_KEY_KP_6;
	glfw.KEY_KP_7 = GLFW_KEY_KP_7;
	glfw.KEY_KP_8 = GLFW_KEY_KP_8;
	glfw.KEY_KP_9 = GLFW_KEY_KP_9;
	glfw.KEY_KP_DIVIDE = GLFW_KEY_KP_DIVIDE;
	glfw.KEY_KP_MULTIPLY = GLFW_KEY_KP_MULTIPLY;
	glfw.KEY_KP_SUBTRACT = GLFW_KEY_KP_SUBTRACT;
	glfw.KEY_KP_ADD = GLFW_KEY_KP_ADD;
	glfw.KEY_KP_DECIMAL = GLFW_KEY_KP_DECIMAL;
	glfw.KEY_KP_EQUAL = GLFW_KEY_KP_EQUAL;
	glfw.KEY_KP_ENTER = GLFW_KEY_KP_ENTER;
	glfw.KEY_KP_NUM_LOCK = GLFW_KEY_KP_NUM_LOCK;
	glfw.KEY_CAPS_LOCK = GLFW_KEY_CAPS_LOCK;
	glfw.KEY_SCROLL_LOCK = GLFW_KEY_SCROLL_LOCK;
	glfw.KEY_PAUSE = GLFW_KEY_PAUSE;
	glfw.KEY_LSUPER = GLFW_KEY_LSUPER;
	glfw.KEY_RSUPER = GLFW_KEY_RSUPER;
	glfw.KEY_MENU = GLFW_KEY_MENU;
	glfw.KEY_LAST = GLFW_KEY_LAST;
	glfw.MOUSE_BUTTON_1 = GLFW_MOUSE_BUTTON_1;
	glfw.MOUSE_BUTTON_2 = GLFW_MOUSE_BUTTON_2;
	glfw.MOUSE_BUTTON_3 = GLFW_MOUSE_BUTTON_3;
	glfw.MOUSE_BUTTON_4 = GLFW_MOUSE_BUTTON_4;
	glfw.MOUSE_BUTTON_5 = GLFW_MOUSE_BUTTON_5;
	glfw.MOUSE_BUTTON_6 = GLFW_MOUSE_BUTTON_6;
	glfw.MOUSE_BUTTON_7 = GLFW_MOUSE_BUTTON_7;
	glfw.MOUSE_BUTTON_8 = GLFW_MOUSE_BUTTON_8;
	glfw.MOUSE_BUTTON_LAST = GLFW_MOUSE_BUTTON_LAST;
	glfw.MOUSE_BUTTON_LEFT = GLFW_MOUSE_BUTTON_LEFT;
	glfw.MOUSE_BUTTON_RIGHT = GLFW_MOUSE_BUTTON_RIGHT;
	glfw.MOUSE_BUTTON_MIDDLE = GLFW_MOUSE_BUTTON_MIDDLE;
	glfw.JOYSTICK_1 = GLFW_JOYSTICK_1;
	glfw.JOYSTICK_2 = GLFW_JOYSTICK_2;
	glfw.JOYSTICK_3 = GLFW_JOYSTICK_3;
	glfw.JOYSTICK_4 = GLFW_JOYSTICK_4;
	glfw.JOYSTICK_5 = GLFW_JOYSTICK_5;
	glfw.JOYSTICK_6 = GLFW_JOYSTICK_6;
	glfw.JOYSTICK_7 = GLFW_JOYSTICK_7;
	glfw.JOYSTICK_8 = GLFW_JOYSTICK_8;
	glfw.JOYSTICK_9 = GLFW_JOYSTICK_9;
	glfw.JOYSTICK_10 = GLFW_JOYSTICK_10;
	glfw.JOYSTICK_11 = GLFW_JOYSTICK_11;
	glfw.JOYSTICK_12 = GLFW_JOYSTICK_12;
	glfw.JOYSTICK_13 = GLFW_JOYSTICK_13;
	glfw.JOYSTICK_14 = GLFW_JOYSTICK_14;
	glfw.JOYSTICK_15 = GLFW_JOYSTICK_15;
	glfw.JOYSTICK_16 = GLFW_JOYSTICK_16;
	glfw.JOYSTICK_LAST = GLFW_JOYSTICK_LAST;
	glfw.WINDOW = GLFW_WINDOW;
	glfw.FULLSCREEN = GLFW_FULLSCREEN;
	glfw.OPENED = GLFW_OPENED;
	glfw.ACTIVE = GLFW_ACTIVE;
	glfw.ICONIFIED = GLFW_ICONIFIED;
	glfw.ACCELERATED = GLFW_ACCELERATED;
	glfw.RED_BITS = GLFW_RED_BITS;
	glfw.GREEN_BITS = GLFW_GREEN_BITS;
	glfw.BLUE_BITS = GLFW_BLUE_BITS;
	glfw.ALPHA_BITS = GLFW_ALPHA_BITS;
	glfw.DEPTH_BITS = GLFW_DEPTH_BITS;
	glfw.STENCIL_BITS = GLFW_STENCIL_BITS;
	glfw.REFRESH_RATE = GLFW_REFRESH_RATE;
	glfw.ACCUM_RED_BITS = GLFW_ACCUM_RED_BITS;
	glfw.ACCUM_GREEN_BITS = GLFW_ACCUM_GREEN_BITS;
	glfw.ACCUM_BLUE_BITS = GLFW_ACCUM_BLUE_BITS;
	glfw.ACCUM_ALPHA_BITS = GLFW_ACCUM_ALPHA_BITS;
	glfw.AUX_BUFFERS = GLFW_AUX_BUFFERS;
	glfw.STEREO = GLFW_STEREO;
	glfw.WINDOW_AV_RESIZE = GLFW_WINDOW_NO_RESIZE;
	glfw.FSAA_SAMPLES = GLFW_FSAA_SAMPLES;
	glfw.OPENGL_VERSION_MAJOR = GLFW_OPENGL_VERSION_MAJOR;
	glfw.OPENGL_VERSION_MINOR = GLFW_OPENGL_VERSION_MINOR;
	glfw.OPENGL_FORWARD_COMPAT = GLFW_OPENGL_FORWARD_COMPAT;
	glfw.OPENGL_DEBUG_CONTEXT = GLFW_OPENGL_DEBUG_CONTEXT;
	glfw.OPENGL_PROFILE = GLFW_OPENGL_PROFILE;
	glfw.OPENGL_CORE_PROFILE = GLFW_OPENGL_CORE_PROFILE;
	glfw.OPENGL_COMPAT_PROFILE = GLFW_OPENGL_COMPAT_PROFILE;
	glfw.MOUSE_CURSOR = GLFW_MOUSE_CURSOR;
	glfw.STICKY_KEYS = GLFW_STICKY_KEYS;
	glfw.STICKY_MOUSE_BUTTONS = GLFW_STICKY_MOUSE_BUTTONS;
	glfw.SYSTEM_KEYS = GLFW_SYSTEM_KEYS;
	glfw.KEY_REPEAT = GLFW_KEY_REPEAT;
	glfw.AUTO_POLL_EVENTS = GLFW_AUTO_POLL_EVENTS;
	glfw.WAIT = GLFW_WAIT;
	glfw.NOWAIT = GLFW_NOWAIT;
	glfw.PRESENT = GLFW_PRESENT;
	glfw.AXES = GLFW_AXES;
	glfw.BUTTONS = GLFW_BUTTONS;
	glfw.AV_RESCALE_BIT = GLFW_NO_RESCALE_BIT;
	glfw.ORIGIN_UL_BIT = GLFW_ORIGIN_UL_BIT;
	glfw.BUILD_MIPMAPS_BIT = GLFW_BUILD_MIPMAPS_BIT;
	glfw.ALPHA_MAP_BIT = GLFW_ALPHA_MAP_BIT;
	glfw.INFINITY = GLFW_INFINITY;
	return &glfw;
}
*/


////////////////////////////////////////////////////////////////
// AUDIO
////////////////////////////////////////////////////////////////

#include "RtAudio.h"


#define AV_AUDIO_MSGBUFFER_SIZE_DEFAULT (1024 * 1024)

// the FFI exposed object:
static av_Audio audio;

// the internal object:
static RtAudio rta;

// the audio-thread Lua state:
//static lua_State * AL = 0;

int av_rtaudio_callback(void *outputBuffer, 
						void *inputBuffer, 
						unsigned int frames,
						double streamTime, 
						RtAudioStreamStatus status, 
						void *data) {
	
	audio.input = (float *)inputBuffer;
	audio.output = (float *)outputBuffer;
	audio.frames = frames;
	
	double newtime = audio.time + frames / audio.samplerate;
	
	size_t size = sizeof(float) * frames;
	
	// zero outbuffers:
	//memset(outputBuffer, 0, size);
	
	// copy in the buffers:
	float * dst = audio.output;
	float * src = audio.buffer + audio.blockread * audio.blocksize * audio.outchannels;
	memcpy(dst, src, size * audio.outchannels);
	
	//memset(src, 0, size * audio.outchannels);
	
	// advance the read head:
	audio.blockread++;
	if (audio.blockread >= audio.blocks) audio.blockread = 0;
	
	// this calls back into Lua via FFI:
	if (audio.onframes) {
		(audio.onframes)(&audio, newtime, audio.input, audio.output, frames);
	}
	
	audio.time = newtime;
	
	return 0;
}

void av_audio_start() {
	if (rta.isStreamRunning()) {
		rta.stopStream();
	}
	if (rta.isStreamOpen()) {
		// close it:
		rta.closeStream();
	}	
	
	unsigned int devices = rta.getDeviceCount();
	if (devices < 1) {
		printf("No audio devices found\n");
		return;
	}
	
	RtAudio::DeviceInfo info;
	RtAudio::StreamParameters iParams, oParams;
	
	printf("Available audio devices:\n");
	for (unsigned int i=0; i<devices; i++) {
		info = rta.getDeviceInfo(i);
		printf("Device %d: %dx%d (%d) %s\n", i, info.inputChannels, info.outputChannels, info.duplexChannels, info.name.c_str());
	}
	
	
	info = rta.getDeviceInfo(audio.indevice);
	printf("Using audio input %d: %dx%d (%d) %s\n", audio.indevice, info.inputChannels, info.outputChannels, info.duplexChannels, info.name.c_str());
	
	audio.inchannels = info.inputChannels;
	
	iParams.deviceId = audio.indevice;
	iParams.nChannels = audio.inchannels;
	iParams.firstChannel = 0;
	
	info = rta.getDeviceInfo(audio.outdevice);
	printf("Using audio output %d: %dx%d (%d) %s\n", audio.outdevice, info.inputChannels, info.outputChannels, info.duplexChannels, info.name.c_str());
	
	audio.outchannels = info.outputChannels;
	
	oParams.deviceId = audio.outdevice;
	oParams.nChannels = audio.outchannels;
	oParams.firstChannel = 0;

	RtAudio::StreamOptions options;
	//options.flags |= RTAUDIO_NONINTERLEAVED;
	options.streamName = "av";
	
	try {
		rta.openStream( &oParams, &iParams, RTAUDIO_FLOAT32, audio.samplerate, &audio.blocksize, &av_rtaudio_callback, NULL, &options );
		rta.startStream();
		printf("Audio started\n");
	}
	catch ( RtError& e ) {
		fprintf(stderr, "%s\n", e.getMessage().c_str());
	}
}

av_Audio * av_audio_get() {
	static bool initialized = false;
	if (!initialized) {
		initialized = true;
		
		rta.showWarnings( true );		
		
		// defaults:
		audio.samplerate = 44100;
		audio.blocksize = 256;
		audio.inchannels = 2;
		audio.outchannels = 2;
		audio.time = 0;
		audio.lag = 0.04;
		audio.indevice = rta.getDefaultInputDevice();
		audio.outdevice = rta.getDefaultOutputDevice();
		audio.msgbuffer.size = AV_AUDIO_MSGBUFFER_SIZE_DEFAULT;
		audio.msgbuffer.read = 0;
		audio.msgbuffer.write = 0;
		audio.msgbuffer.data = (unsigned char *)malloc(audio.msgbuffer.size);
		
		audio.onframes = 0;
		
		// one second of ringbuffer:
		int blockspersecond = audio.samplerate / audio.blocksize;
		audio.blocks = blockspersecond + 1;
		audio.blockstep = audio.blocksize * audio.outchannels;
		int len = audio.blockstep * audio.blocks;
		audio.buffer = (float *)calloc(len, sizeof(float));
		audio.blockread = 0;
		audio.blockwrite = 0;
		
		
		//AL = lua_open(); //av_init_lua();
		
		// unique to audio thread:
		//if (luaL_dostring(AL, "require 'audioprocess'")) {
		//	printf("error: %s\n", lua_tostring(AL, -1));
	//		initialized = false;
		//}
		 
	}
	return &audio;
}

