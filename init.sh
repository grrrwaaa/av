#!/bin/bash   

# debugging: 
set -x

ROOT=`pwd`
PLATFORM=`uname`
ARCH=`uname -m`
PRODUCT_NAME="av"
echo Initializing $PRODUCT_NAME for $PLATFORM $ARCH from $ROOT

git submodule init && git submodule update

pushd luajit-2.0

make
sudo make install
sudo ln -sf /usr/local/bin/luajit-2.0.1 /usr/local/bin/luajit

popd