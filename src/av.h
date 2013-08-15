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
	
	double fps;	
	void (*ontimer)(struct av_loop_t * self);
	
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

AV_EXPORT void av_glut_timerfunc(int id);

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

