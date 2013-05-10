#ifndef AV_H
#define AV_H

#ifdef _WIN32
#define AV_EXPORT __declspec(dllexport)
#else
#define AV_EXPORT
#endif

#ifdef __cplusplus
#include <stdint.h>
extern "C" {
#endif

AV_EXPORT void av_sleep(double seconds);
AV_EXPORT double av_time();
AV_EXPORT double av_filetime(const char * filename);

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
	double fps;
	
	void (*oncreate)(struct av_Window * self);
	void (*onresize)(struct av_Window * self, int w, int h);
	void (*onvisible)(struct av_Window * self, int state);
	void (*ondraw)(struct av_Window * self);
	void (*onkey)(struct av_Window * self, int event, int key);
	void (*onmouse)(struct av_Window * self, int event, int button, int x, int y);
	
} av_Window;

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
	
	// only access from audio thread:
	float * input;
	float * output;	
	void (*onframes)(struct av_Audio * self, double sampletime, float * inputs, float * outputs, int frames);
	
} av_Audio;

AV_EXPORT av_Window * av_window_create();

AV_EXPORT void av_window_setfullscreen(av_Window * self, int b);
AV_EXPORT void av_window_settitle(av_Window * self, const char * name);
AV_EXPORT void av_window_setdim(av_Window * self, int x, int y);

// called to reset state before a script closes, e.g. removing callbacks:
AV_EXPORT void av_state_reset(void * state);

AV_EXPORT av_Audio * av_audio_get();

// only use from main thread:
AV_EXPORT void av_audio_start(); 

// Stupid hack for clang CIndex module because of pass-by-value callback:
typedef struct {
	int kind;
	int xdata;
	void *data[3];
} CXCursor;

typedef struct av_clang_visitor {
	int (*fun)(CXCursor *cursor, CXCursor *parent);
} av_clang_visitor;
AV_EXPORT int av_clang_visit(CXCursor cursor, CXCursor parent, void * ud);

typedef struct lua_State lua_State;
AV_EXPORT int luaopen_lpeg (lua_State *L);
AV_EXPORT int luaopen_http_parser(lua_State* L);

#ifdef __cplusplus
}
#endif

#endif // AV_H
