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
