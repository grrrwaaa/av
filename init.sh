#!/bin/bash   

ROOT=`pwd`
PLATFORM=`uname`
ARCH=`uname -m`
PRODUCT_NAME="av"
echo Initializing $PRODUCT_NAME for $PLATFORM $ARCH from $ROOT

echo updating repository
git pull

echo requesting submodules
git submodule init && git submodule update


pushd luajit-2.0
make clean

MAKELUAJIT="make"

if [[ $ARCH == 'i386' ]]; then
	
	# this was necessary on OSX
	MAKELUAJIT='make CC="gcc -m32"'
fi

echo $MAKELUAJIT
$MAKELUAJIT

echo installing luajit
sudo make install
sudo ln -sf /usr/local/bin/luajit-2.0.1 /usr/local/bin/luajit

popd

./build.sh