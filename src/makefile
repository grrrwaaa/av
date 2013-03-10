# run using nmake

# define macros
DIR_INCLUDE = win32/include
DIR_LIB = win32/lib
  
build: 
	cl /MT /I$(DIR_INCLUDE) av.cpp /link /LIBPATH:$(DIR_LIB) lua51.lib glut32.lib
	xcopy av.exe .. /D /Y
	xcopy *.dll .. /D /Y

run: build
	.\av.exe
	
all:
	run
	
clean:
	del *.exe *.obj