# run using nmake

# define macros
DIR_INCLUDE = "win32/include"
DIR_LIB = "win32/lib"

# cl /MT links the CRT statically, so that it can be used on systems that do not have the CRT installed.
# xcopy /Y suppresses the "Overwrite?" warnings 
build: 
	cl /MT /I$(DIR_INCLUDE) /I"rtaudio-4.0.11" /I"include" av.cpp av_audio.cpp rtaudio-4.0.11/RtAudio.cpp /link /LIBPATH:$(DIR_LIB) lua51.lib glut32.lib
	xcopy av.exe .. /Y
	xcopy *.dll .. /Y
	del *.exe 

run: build
	.\av.exe
	
all:
	run
	
clean:
	del *.exe *.obj *.exp
