git clone https://github.com/ptitSeb/box86 --depth 1
git clone https://github.com/ptitSeb/box64 --depth 1

cd box64
mkdir build
cd build
cmake .. -DCMAKE_CXX_COMPILER=/usr/bin/aarch64-linux-gnu-g++ -DCMAKE_C_COMPILER=/usr/bin/aarch64-linux-gnu-gcc -DSD8G2=1 
make -j$(nproc)
sudo make install DESTDIR=../../debs/

cd ../../box86
patch -p1 < ../patches/box86.patch
mkdir build
cd build
cmake .. -DCMAKE_CXX_COMPILER=/usr/bin/arm-linux-gnueabi-g++ -DCMAKE_C_COMPILER=/usr/bin/arm-linux-gnueabi-gcc -DSD8G2=1
make -j$(nproc)
sudo make install DESTDIR=../../debs/
cd ../../

dpkg-deb --build --root-owner-group debs
