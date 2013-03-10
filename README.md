# av

Audio-visual creative coding with LuaJIT

## Running

**Windows:** launch *av.exe*

**Linux:** run ```./av``` (an optional argument specifies a different .lua file to run)

**OSX:** run from a terminal as ```./av```, or just by double-clicking on **av**. 

When launched it will run the contents of ```start.lua```. If this file is edited & saved while *av* is running, it will be relaunched.

The *av* app is just a thin wrapper around LuaJIT 2.0 with a binding to a window (currently GLUT) and a few other basic system utilities. Most other modules are Lua/LuaJIT.

## Building

### OSX

Xcode developer tools should be sufficient (Xcode itself is not required).

Then it should be enough to say 
	
	cd src
	./build.sh

### Ubuntu

Tested on Ubuntu 12.10

	cd src
	./build.sh

I needed to ```sudo apt-get install git g++ freeglut3-dev``` for this to succeed.

### Windows

Tested on Windows 7 (64-bit)

Open a Visual Studio Command Prompt:
	
	cd src
	nmake
	
