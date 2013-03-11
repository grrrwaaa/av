#!/bin/bash   

# debugging: 
set -x

SRCROOT=`pwd`
PLATFORM=`uname`
ARCH=`uname -m`
PRODUCT_NAME="av"
echo Building $PRODUCT_NAME for $PLATFORM $ARCH from $SRCROOT

echo generate FFI code
luajit h2ffi.lua av.h av_ffi_header

echo clean
rm -f $PRODUCT_NAME 
rm -f *.o
rm -f *.d

if [[ $PLATFORM == 'Darwin' ]]; then
	
	export MACOSX_DEPLOYMENT_TARGET=10.4
	
	# cross compile
	
	CC='g++'
	CFLAGS="-x c++ -fno-stack-protector -O3 -Wall -fPIC"
	DEFINES=""
	INCLUDEPATHS="-I/usr/local/include/luajit-2.0"
	
	LINK=$CC
	LDFLAGS32="-w -rdynamic -keep_private_externs"
	LDFLAGS64="$LDFLAGS32 -pagezero_size 10000 -image_base 100000000"
	
	LINKERPATHS="-Losx/lib"
	LIBRARIES="-lluajit -framework Carbon -framework Cocoa -framework CoreAudio -framework GLUT -framework OpenGL"
	
	echo compile 32
	rm -f *.o
	$CC -arch i386 -c $CFLAGS $DEFINES $INCLUDEPATHS av.cpp
	echo link 32
	$LINK -arch i386 $LDFLAGS32 $LINKERPATHS $LIBRARIES *.o -o app32
	
	echo compile 64
	rm -f *.o
	$CC -arch x86_64 -c $CFLAGS $DEFINES $INCLUDEPATHS av.cpp
	echo link 64
	$LINK -arch x86_64 $LDFLAGS64 $LINKERPATHS $LIBRARIES *.o -o app64
	
	# join them in fat love:
	echo fatten
	lipo -create app32 app64 -output $PRODUCT_NAME
	rm app32 app64
	
elif [[ $PLATFORM == 'Linux' ]]; then
	
	CC='g++'
	CFLAGS="-O3 -Wall -fPIC -ffast-math -Wno-unknown-pragmas -MMD"
	DEFINES="-D_GNU_SOURCE -DEV_MULTIPLICITY=1 -DHAVE_GETTIMEOFDAY -D__LINUX_ALSA__"
	INCLUDEPATHS="-I/usr/local/include/luajit-2.0 -I/usr/include/luajit-2.0"
	
	LINK=$CC
	LDFLAGS="-w -rdynamic -Wl,-E "
	LINKERPATHS="-L/usr/local/lib -L/usr/lib"
	#LIBRARIES="-lluajit-5.1 -lfreeimage -lGLEW -lGLU -lGL -lglut -lasound ../externs/libuv/libuv.a -lrt -lpthread"
	LIBRARIES="-lluajit-5.1 -lGLU -lGL -lglut"
	
	echo compile
	$CC -c $CFLAGS $DEFINES $INCLUDEPATHS av.cpp
	echo link
	$LINK $LDFLAGS $LINKERPATHS $LIBRARIES -Wl,-whole-archive *.o -Wl,-no-whole-archive $LIBRARIES -o $PRODUCT_NAME

else

	echo "unknown platform" $PLATFORM
	
fi

# documentation:
./ldoc.lua -v --title "AV Reference" --project "LuaJIT AV" --dir ../docs --output reference ../modules

echo copy
cp av ../

