sudo apt-get install libusb-1.0-dev

mkdir -p externs
cd externs


git clone git://github.com/OpenKinect/libfreenect.git
pushd libfreenect
mkdir build
cd build
cmake ..
make

cp lib/libfreenect.* ../../../linux/lib64/

sudo cp ../platform/linux/udev/51-kinect.rules /etc/udev/rules.d

popd
