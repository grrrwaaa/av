# grab source:
pushd ..
git submodule init && git submodule update
popd

pushd luajit-2.0

# build 32-bit
make clean
make CC="gcc -m32"
sudo make install
cp /usr/local/lib/libluajit-5.1.a ../osx/lib/libluajit32.a

# copy headers:
cp /usr/local/include/luajit-2.0/* ../osx/include/

# build 64-bit
make clean
make CC="gcc -m64"
make 
sudo make install
cp /usr/local/lib/libluajit-5.1.a ../osx/lib/libluajit64.a

# restore normality
make clean
make
sudo make install
sudo ln -sf /usr/local/bin/luajit-2.0.1 /usr/local/bin/luajit

popd

# create FAT binary:
pushd osx/lib
lipo -create libluajit32.a libluajit64.a -output libluajit.a
rm libluajit64.a
rm libluajit32.a
popd