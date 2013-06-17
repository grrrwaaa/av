#!/bin/bash   

# debugging: 
#set -x

SRCROOT=`pwd`
PLATFORM=`uname`
ARCH=`uname -m`
echo Building for $PLATFORM $ARCH from $SRCROOT

echo generate FFI code
luajit h2ffi.lua av.h av_ffi_header

echo clean
rm -f lpeg-0.11/*.o
rm -f *.o
rm -f *.d

if [[ $PLATFORM == 'Darwin' ]]; then

	PRODUCT_NAME="av_osx"
	rm -f $PRODUCT_NAME 
	
	export MACOSX_DEPLOYMENT_TARGET=10.4
	
	# cross compile 86/64
	
	CC='clang++'
	CFLAGS="-fno-stack-protector -O3 -Wall -fPIC"
	DEFINES="-DEV_MULTIPLICITY=1 -DHAVE_GETTIMEOFDAY -D__MACOSX_CORE__"
	INCLUDEPATHS="-Iosx/include -Iinclude -Irtaudio-4.0.11 -Ilpeg-0.11 -Ihidapi/hidapi -I/usr/local/include/bullet/"
	SOURCES="-x c++ av.cpp rgbd.cpp av_audio.cpp rtaudio-4.0.11/RtAudio.cpp -x c lpeg-0.11/*.c http-parser/*.c hidapi/mac/hid.c"
	# bullet.cpp
	
	LINK='clang++'
	LDFLAGS32="-w -keep_private_externs"
	LDFLAGS64="$LDFLAGS32 -pagezero_size 10000 -image_base 100000000"
	
	LINKERPATHS="-Losx/lib"
	LIBRARIES="osx/lib/libluajit.a osx/lib/libfreenect.a osx/lib/libusb-1.0.a -framework Carbon -framework Cocoa -framework CoreAudio -framework GLUT -framework OpenGL -framework IOKit -lBulletDynamics -lBulletCollision -lLinearMath"
	
	#-framework AudioUnit -framework CoreAudio -framework AudioToolbox"
	
	#echo compile 32
	#rm -f *.o
	#$CC -arch i386 -c $CFLAGS $DEFINES $INCLUDEPATHS $SOURCES
	#echo link 32
	#$LINK -arch i386 $LDFLAGS32 $LINKERPATHS $LIBRARIES *.o -o app32
	
	echo compile 64
	rm -f *.o
	$CC -arch x86_64 -c $CFLAGS $DEFINES $INCLUDEPATHS $SOURCES
	echo link 64
	$LINK -arch x86_64 $LDFLAGS64 $LINKERPATHS $LIBRARIES *.o -o app64
	
	# join them in fat love:
	echo fatten
	#lipo -create app32 app64 -output $PRODUCT_NAME
	#rm app32 app64
	mv app64 $PRODUCT_NAME

	# documentation:
	#./ldoc.lua -v --dir ../docs --output reference ../modules	
	
	echo copy
	cp $PRODUCT_NAME ../
	
elif [[ $PLATFORM == 'Linux' ]]; then

	PRODUCT_NAME="av_linux"
	rm -f $PRODUCT_NAME 
	
	CC='g++'
	CFLAGS="-O3 -Wall -fPIC -ffast-math -Wno-unknown-pragmas -MMD"
	DEFINES="-D_GNU_SOURCE -DEV_MULTIPLICITY=1 -DHAVE_GETTIMEOFDAY -D__LINUX_ALSA__"
	INCLUDEPATHS="-Ilinux/include -I/usr/local/include/luajit-2.0 -I/usr/include/luajit-2.0 -Irtaudio-4.0.11 -Ilpeg-0.11 -Iinclude"
	SOURCES="av.cpp rgbd.cpp av_audio.cpp rtaudio-4.0.11/RtAudio.cpp"
	
	LINK=$CC
	LDFLAGS="-w -rdynamic -Wl,-E "
	LINKERPATHS="-L/usr/local/lib -L/usr/lib"
	#LIBRARIES="-lluajit-5.1 -lfreeimage -lGLEW -lGLU -lGL -lglut -lasound ../externs/libuv/libuv.a -lrt -lpthread"
	LIBRARIES="-lluajit-5.1 -lGLU -lGL -lglut -lasound -lrt -lpthread linux/lib64/libfreenect.a -lusb-1.0"
	
	echo compile
	$CC -c $CFLAGS $DEFINES $INCLUDEPATHS $SOURCES
	gcc -c $CFLAGS $DEFINES $INCLUDEPATHS lpeg-0.11/*.c http-parser/*.c
	echo link
	$LINK $LDFLAGS -Wl,-whole-archive *.o -Wl,-no-whole-archive $LINKERPATHS  $LIBRARIES -o $PRODUCT_NAME

	echo copy
	cp $PRODUCT_NAME ../
	
else

	echo "unknown platform" $PLATFORM
	
fi

