sudo apt-get install g++ cmake libusb-1.0-0-dev freeglut3-dev libxmu-dev libxi-dev libasound2-dev

pushd luajit-2.0
make && sudo make install
popd

mkdir -p externs
cd externs

git clone git://github.com/OpenKinect/libfreenect.git
cd libfreenect

mkdir build
cd build
cmake ..
make

cp lib/libfreenect.* ../../../linux/lib64/
cp ../include/* ../../../linux/include/

sudo cp ../platform/linux/udev/51-kinect.rules /etc/udev/rules.d/
