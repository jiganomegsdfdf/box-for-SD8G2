git clone https://github.com/ptitSeb/box64 --depth 1 $1/box64
cd $1/box64
patch -p1 < $1/patches/box64.patch
mkdir build
cd build
cmake $1/box64 -DCMAKE_C_COMPILER=/usr/bin/aarch64-linux-gnu-gcc-14 -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=aarch64 -DCMAKE_CROSSCOMPILING=TRUE -DSD8G2=1 
make -j$(nproc)
make install DESTDIR=$1/box96

git clone https://github.com/ptitSeb/box86 --depth 1 $1/box86
cd $1/box86
patch -p1 < $1/patches/box86.patch
mkdir build
cd build
cmake $1/box86 -DCMAKE_C_COMPILER=/usr/bin/arm-linux-gnueabihf-gcc-14 -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=aarch64 -DCMAKE_CROSSCOMPILING=TRUE -DSD8G2=1
make -j$(nproc)
make install DESTDIR=$1/box96

cd $1
chmod +x $1/box96/DEBIAN/postinst
dpkg-deb --build --root-owner-group box96
