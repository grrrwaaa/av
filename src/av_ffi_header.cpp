const char * av_ffi_header = ""
"-- generated from av.h on Mon Mar 11 15:22:54 2013 \n"
"local header = [[ \n"
" void av_sleep(double seconds); \n"
" double av_time(); \n"
" double av_filetime(const char * filename); \n"
"enum { \n"
" AV_KEY_ENTER =3, \n"
" AV_KEY_BACKSPACE =8, \n"
" AV_KEY_TAB =9, \n"
" AV_KEY_RETURN =13, \n"
" AV_KEY_ESCAPE =27, \n"
" AV_KEY_DELETE =127, \n"
" AV_KEY_F1=256, \n"
" AV_KEY_F2, AV_KEY_F3, AV_KEY_F4, AV_KEY_F5, AV_KEY_F6, AV_KEY_F7, AV_KEY_F8, AV_KEY_F9, AV_KEY_F10, AV_KEY_F11, AV_KEY_F12, \n"
" AV_KEY_INSERT, \n"
" AV_KEY_LEFT, AV_KEY_UP, AV_KEY_RIGHT, AV_KEY_DOWN, \n"
" AV_KEY_PAGE_DOWN, AV_KEY_PAGE_UP, \n"
" AV_KEY_END, AV_KEY_HOME \n"
"}; \n"
"typedef struct av_Window { \n"
" int width, height; \n"
" int is_fullscreen; \n"
" int button; \n"
" int shift, alt, ctrl; \n"
" double fps; \n"
" void (*oncreate)(struct av_Window * self); \n"
" void (*onresize)(struct av_Window * self, int w, int h); \n"
" void (*onvisible)(struct av_Window * self, int state); \n"
" void (*ondraw)(struct av_Window * self); \n"
" void (*onkey)(struct av_Window * self, int event, int key); \n"
" void (*onmouse)(struct av_Window * self, int event, int button, int x, int y); \n"
"} av_Window; \n"
" av_Window * av_window_create(); \n"
" void av_window_setfullscreen(av_Window * self, int b); \n"
" void av_window_settitle(av_Window * self, const char * name); \n"
" void av_window_setdim(av_Window * self, int x, int y); \n"
" void av_state_reset(void * state); \n"
"]] \n"
"local ffi = require 'ffi' \n"
"ffi.cdef(header) \n"
"return header \n";
const char * av_main = ""
"-- this code gets baked into the av application \n"
" \n"
"local filename = select(2, ...) or \"start.lua\" \n"
"local args = { select(3, ...) } \n"
" \n"
"-- add the modules search path: \n"
"package.path = './modules/?.lua;./modules/?/init.lua;'..package.path \n"
" \n"
"-- load the modules we need: \n"
"local ffi = require \"ffi\" \n"
"local builtin = require \"builtin\" \n"
"local lua = require \"lua\" \n"
"	 \n"
"-- a bit of helpful info: \n"
"print(string.format(\"using %s on %s (%s)\", jit.version, jit.os, jit.arch)) \n"
" \n"
"local watched = {} \n"
"local states = {} \n"
" \n"
"function av_tick() \n"
"	-- filewatch: \n"
"	for filename, mtime in pairs(watched) do \n"
"		local t = ffi.C.av_filetime(filename) \n"
"		if t > mtime then \n"
"			print('canceling', filename) \n"
"			cancel(states[filename]) \n"
"			 \n"
"			print('spawning', filename) \n"
"			spawn(filename) \n"
"		end \n"
"	end \n"
"end \n"
" \n"
"-- basic file spawning.  \n"
"-- this will allow us to scale up to filewatching and multiple states in the future \n"
" \n"
"function spawn(filename) \n"
"	print(string.rep(\"-\", 80)) \n"
"	watched[filename] = ffi.C.av_filetime(filename) \n"
"	 \n"
"	-- create a child Lua state to run user code in: \n"
"	L = lua.open() \n"
"	L:openlibs() \n"
"	states[filename] = L \n"
"	 \n"
"	-- 'prime' this state with the module search path and built-in FFI header: \n"
"	L:dostring([[ \n"
"		-- also search in /modules for Lua modules: \n"
"		package.path = './modules/?.lua;./modules/?/init.lua;'..package.path;  \n"
" \n"
"		-- define the AV header in FFI: \n"
"		local builtin_header = ... \n"
"		local ffi = require 'ffi' \n"
"		ffi.cdef(builtin_header) \n"
" \n"
"		-- initialize the window bindings: \n"
"		win = require \"window\" \n"
"		 \n"
"	]], builtin.header) \n"
"	 \n"
"	print(string.format(\"running %s at %s\", filename, os.date())) \n"
"	print(string.rep(\"-\", 80)) \n"
" \n"
"	L:dofile(filename, unpack(args)) \n"
"	 \n"
"	return L \n"
"end \n"
" \n"
"function cancel(L) \n"
"	-- before calling L:close(), we need to unregister any application callbacks! \n"
"	ffi.C.av_state_reset(L) \n"
"	-- should be safe to shutdown now: \n"
"	L:close() \n"
"	print(string.rep(\"-\", 80)) \n"
"end \n"
" \n"
"spawn(filename) \n";