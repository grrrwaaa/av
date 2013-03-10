av
==

Audio-visual creative coding with LuaJIT

## Running

```av``` is the launcher; it is a thin wrapper around LuaJIT 2.0. 
The first argument should be a lua script to launch; otherwise it will attempt to find a file called "start.lua".

## Building

### OSX

Xcode developer tools should be sufficient (Xcode itself is not required)

Then it should be enough to say ```cd src && ./build.sh```

### Ubuntu

Tested on Ubuntu 12.10

I needed to ```sudo apt-get install git g++ freeglut3-dev``` for ```./init.sh``` to succeed

### Windows

Tested on Windows 7 (64-bit)

Open a Visual Studio Command Prompt:
	
	cd src
	nmake
	
