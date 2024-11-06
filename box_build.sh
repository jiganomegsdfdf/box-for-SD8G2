VERSION="24.10"
wget https://cdimage.ubuntu.com/ubuntu-base/releases/$VERSION/release/ubuntu-base-$VERSION-base-arm64.tar.gz
tar xzvf ubuntu-base-$VERSION-base-arm64.tar.gz -C .

mkdir -p data/local/tmp
mount --bind /dev dev
mount --bind /dev/pts dev/pts
mount --bind /proc proc
mount -t tmpfs tmpfs data/local/tmp
mount --bind /sys sys

echo "nameserver 1.1.1.1" | tee etc/resolv.conf
echo "box-builder" | tee etc/hostname
echo "127.0.0.1 localhost
127.0.1.1 box-builder" | tee etc/hosts

if uname -m | grep -q aarch64
then
  echo "cancel qemu install for arm64"
else
  wget https://github.com/multiarch/qemu-user-static/releases/download/v7.2.0-1/qemu-aarch64-static
  install -m755 qemu-aarch64-static ./

  echo ':aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7:\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/qemu-aarch64-static:' | tee /proc/sys/fs/binfmt_misc/register
  echo ':aarch64ld:M::\x7fELF\x02\x01\x01\x03\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\xb7:\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/qemu-aarch64-static:' | tee /proc/sys/fs/binfmt_misc/register
fi

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:\$PATH
export DEBIAN_FRONTEND=noninteractive

chroot . apt update
chroot . apt upgrade -y
chroot . apt install -y build-essential libc6-dev-armhf-cross libc6-dev-arm64-cross libc6-dev patch gcc-14-arm-linux-gnueabi gcc-14-aarch64-linux-gnu make cmake bash git dpkg python3 python-is-python3

chroot . git clone https://github.com/ptitSeb/box86 --depth 1
chroot . git clone https://github.com/ptitSeb/box64 --depth 1

chroot . "cd box64 && mkdir build && cd build && cmake .. -DCMAKE_C_COMPILER=/usr/bin/aarch64-linux-gnu-gcc-14 -DSD8G2=1 && make -j$(nproc) && make install DESTDIR=../../debs/ "
chroot . "cd box86 && patch -p1 < ../patches/box86.patch && mkdir build && cd build && cmake .. -DCMAKE_C_COMPILER=/usr/bin/arm-linux-gnueabi-gcc-14 -DSD8G2=1 && make -j$(nproc) && make install DESTDIR=../../debs/ && cd ../../"

dpkg-deb --build --root-owner-group debs
