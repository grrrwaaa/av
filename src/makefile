# run using nmake

# define macros
DIR_INCLUDE = "win32/include"
DIR_LIB = "win32/lib"

# cl /MT links the CRT statically, so that it can be used on systems that do not have the CRT installed.
# xcopy /Y suppresses the "Overwrite?" warnings 

build: 
	cl /MT /O2 /D__WINDOWS_DS__ /I$(DIR_INCLUDE) /I"rtaudio-4.0.11" /I"rtaudio-4.0.11/include" /I"lpeg-0.11" /I"include" av.cpp av_audio.cpp rtaudio-4.0.11/RtAudio.cpp lpeg-0.11/*.c /link /LIBPATH:$(DIR_LIB) lua51.lib glut32.lib libsndfile-1.lib Dsound.lib ole32.lib user32.lib
	xcopy av.exe .. /Y
	xcopy *.dll .. /Y
	del *.exe 

run: build
	.\av.exe
	
all:
	run
	
clean:
	del *.exe *.obj *.exp
