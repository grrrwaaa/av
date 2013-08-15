#ifndef AV_H
#define AV_H

#ifdef _WIN32
#define AV_EXPORT __declspec(dllexport)
#else
#define AV_EXPORT
#endif


#ifdef __cplusplus
	#include <stdint.h>
	
	#include "GL/glfw.h"
	extern "C" {
#endif

enum {
	AV_EVENT_TYPE_READ,
	AV_EVENT_TYPE_TIMER,
	AV_EVENT_TYPE_CLOSE,
	
	AV_EVENT_TYPE_COUNT
};

static const int AV_MAXEVENTS = 64;

typedef struct av_event_t {
	int type;
	int fd;
} av_event_t;

typedef struct av_loop_t {
	int queue;					// OSX: kqueue, Linux: epoll
	int numevents;				// how many events were populated by the last poll
	av_event_t * events;		
} av_loop_t;

AV_EXPORT av_loop_t * av_loop_new();
AV_EXPORT void av_loop_destroy(av_loop_t * loop);
AV_EXPORT int av_loop_add_fd_in(av_loop_t * loop, int fd);
AV_EXPORT int av_loop_add_fd_out(av_loop_t * loop, int fd);
AV_EXPORT int av_loop_remove_fd_in(av_loop_t * loop, int fd);
AV_EXPORT int av_loop_remove_fd_out(av_loop_t * loop, int fd);
AV_EXPORT int av_loop_run_once(av_loop_t * loop, double seconds);

AV_EXPORT void av_sleep(double seconds);
AV_EXPORT double av_now();
AV_EXPORT double av_filetime(const char * filename);

/*
const char * hostname();


int av_socket_tcp_client(const char * address, const char * port);
int av_socket_tcp_server(const char * address, const char * port);
int av_socket_listen(int sfd, int backlog);
int av_socket_accept(int fd);
int av_socket_write(int fd, const char * msg, int len);

int av_stream_read(int fd, char * buf, int size);

// basically fwrite:
int av_file_write(const void *ptr, int size_of_elements, int number_of_elements, void *a_file);
// basically fread:
int av_file_read(void *ptr, int size_of_elements, int number_of_elements, void *a_file);



int tcp_socket_server(const char * address, const char * port);
int socket_listen(int sfd, int backlog);
int socket_accept(int fd);

int tcp_socket_client(const char * address, const char * port);

int socket_close(int fd);

int socket_write(int fd, const char * msg, int len);
int stream_read(int fd, char * buf, int size);

int file_write(const void *ptr, int size_of_elements, int number_of_elements, void *a_file);
int file_read(void *ptr, int size_of_elements, int number_of_elements, void *a_file);

void * mmap_open(const char * filename, int size, int * filedescriptor);
void mmap_close(void * shared, int size, int fd);
*/

enum {
	// Standard ASCII non-printable characters 
	AV_KEY_ENTER		=3,		
	AV_KEY_BACKSPACE	=8,		
	AV_KEY_TAB			=9,
	AV_KEY_RETURN		=13,
	AV_KEY_ESCAPE		=27,
	AV_KEY_DELETE		=127,
		
	// Non-standard, but common keys
	AV_KEY_F1=256, 
	AV_KEY_F2, AV_KEY_F3, AV_KEY_F4, AV_KEY_F5, AV_KEY_F6, AV_KEY_F7, AV_KEY_F8, AV_KEY_F9, AV_KEY_F10, AV_KEY_F11, AV_KEY_F12,
	 
	AV_KEY_INSERT, 
	AV_KEY_LEFT, AV_KEY_UP, AV_KEY_RIGHT, AV_KEY_DOWN, 
	AV_KEY_PAGE_DOWN, AV_KEY_PAGE_UP, 
	AV_KEY_END, AV_KEY_HOME
};

typedef struct av_Window {
	int width, height;
	int is_fullscreen;
	int button;
	int shift, alt, ctrl;
	int is_stereo;
	double fps;
	
	void (*oncreate)(struct av_Window * self);
	void (*onresize)(struct av_Window * self, int w, int h);
	void (*onvisible)(struct av_Window * self, int state);
	void (*ondraw)(struct av_Window * self);
	void (*onkey)(struct av_Window * self, int event, int key);
	void (*onmouse)(struct av_Window * self, int event, int button, int x, int y);
	
} av_Window;

AV_EXPORT av_Window * av_window_create();
AV_EXPORT void av_window_setfullscreen(av_Window * self, int b);
AV_EXPORT void av_window_settitle(av_Window * self, const char * name);
AV_EXPORT void av_window_setdim(av_Window * self, int x, int y);

// called to reset state before a script closes, e.g. removing callbacks:
AV_EXPORT void av_state_reset(void * state);


enum {
	AV_AUDIO_CMD_EMPTY,
	AV_AUDIO_CMD_GENERIC = 128,
	AV_AUDIO_CMD_CLEAR,
	AV_AUDIO_CMD_VOICE_ADD,
	AV_AUDIO_CMD_VOICE_REMOVE,
	AV_AUDIO_CMD_VOICE_PARAM,
	AV_AUDIO_CMD_VOICE_CODE,
	
	AV_AUDIO_CMD_SKIP = 255
};

typedef struct av_msg_param {
	int id, pid;
	double value;
} av_msg_param;

typedef struct av_msgbuffer {
	int read, write, size, unused;
	unsigned char * data;
} av_msgbuffer;

typedef struct av_Audio {
	unsigned int blocksize;
	unsigned int frames;	
	unsigned int indevice, outdevice;
	unsigned int inchannels, outchannels;		
	
	double time;		// in seconds
	double samplerate;
	double lag;			// in seconds
	
	av_msgbuffer msgbuffer;
	
	// a big buffer for main-thread audio generation
	float * buffer;
	// the buffer alternates between channels at blocksize periods:
	int blocks, blockread, blockwrite, blockstep;
	
	// only access from audio thread:
	float * input;
	float * output;	
	void (*onframes)(struct av_Audio * self, double sampletime, float * inputs, float * outputs, int frames);
	
} av_Audio;

AV_EXPORT av_Audio * av_audio_get();
AV_EXPORT void av_audio_start(); 

#ifdef __cplusplus
	} // extern "C"

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
			#include <mach/mach.h>
			#include <mach/mach_time.h>
			#include <OpenGL/OpenGL.h>
			#include <GLUT/glut.h>
			
			#define AV_POLL_USE_KQUEUE
			#include <sys/event.h>
			#define AV_POLL_CREATE(n) kqueue()
			#define AV_POLL_EVENT	struct kevent
		#else
			#define AV_LINUX 1
			#include <GL/gl.h>
			#include <GL/glut.h>
		
			#define AV_POLL_USE_EPOLL
			#include <sys/epoll.h>
			#define AV_POLL_CREATE(n) epoll_create(n)
			#define AV_POLL_EVENT	struct epoll_event
		#endif
	
		#define AV_PATH_MAX PATH_MAX
		#define AV_GETCWD getcwd
		#define AV_SNPRINTF snprintf
	#endif // UNIX
#endif // #defined __cplusplus

#endif // #defined AV_H

