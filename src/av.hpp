#ifndef AV_HPP
#define AV_HPP

#include "av.h"

#if defined(_WIN32) || defined(__WINDOWS_MM__) || defined(_WIN64)
	#define AV_WINDOWS 1
	// just placeholder really; Windows requires a bit more work yet.
	#include <windows.h>
	#include <direct.h>
	
	#include <gl\gl.h> 
	#include <gl\glu.h> 
	#include <glut.h>
	
	
	#define AV_PATH_MAX MAX_PATH
	#define AV_GETCWD _getcwd
	#define AV_SNPRINTF _snprintf
#else
	// Unixen:
	#include <unistd.h>
	#include <sys/time.h>
	#include <sys/stat.h>
	#include <time.h>
	#include <libgen.h>
	#include <utime.h>
	
	#if defined( __APPLE__ ) && defined( __MACH__ )
		#define AV_OSX 1
		#include <OpenGL/OpenGL.h>
		#include <GLUT/glut.h>

	#else
		#define AV_LINUX 1
		#include <GL/gl.h>
		#include <GL/glut.h>
		
	#endif
	
	#define AV_PATH_MAX PATH_MAX
	#define AV_GETCWD getcwd
	#define AV_SNPRINTF snprintf
#endif


#endif // AV_HPP