VERSION="24.10"

truncate -s 5G rootfs.img
mkfs.ext4 rootfs.img
mkdir rootdir
mount -o loop rootfs.img rootdir

wget https://cdimage.ubuntu.com/ubuntu-base/releases/$VERSION/release/ubuntu-base-$VERSION-base-arm64.tar.gz
tar xzvf ubuntu-base-$VERSION-base-arm64.tar.gz -C rootdir

mkdir -p rootdir/data/local/tmp
mount --bind /dev rootdir/dev
mount --bind /dev/pts rootdir/dev/pts
mount --bind /proc rootdir/proc
mount -t tmpfs tmpfs rootdir/data/local/tmp
mount --bind /sys rootdir/sys

echo "nameserver 1.1.1.1" | tee rootdir/etc/resolv.conf
echo "box-builder" | tee rootdir/etc/hostname
echo "127.0.0.1 localhost
127.0.1.1 box-builder" | tee rootdir/etc/hosts

if uname -m | grep -q aarch64
then
  echo "cancel qemu install for arm64"
else
  wget https://github.com/multiarch/qemu-user-static/releases/download/v7.2.0-1/qemu-aarch64-static
  install -m755 qemu-aarch64-static rootdir/

  echo ':aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7:\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/qemu-aarch64-static:' | tee /proc/sys/fs/binfmt_misc/register
  echo ':aarch64ld:M::\x7fELF\x02\x01\x01\x03\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\xb7:\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/qemu-aarch64-static:' | tee /proc/sys/fs/binfmt_misc/register
fi

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:\$PATH
export DEBIAN_FRONTEND=noninteractive

mkdir -p rootdir/patches
cp patches/box86.patch rootdir/patches/box86.patch

chroot rootdir apt update
chroot rootdir apt upgrade -y
chroot rootdir apt install -y build-essential libc6-dev-armhf-cross libc6-dev-arm64-cross libc6-dev patch gcc-14-arm-linux-gnueabi gcc-14-aarch64-linux-gnu make cmake bash git dpkg python3 python-is-python3

mkdir -p rootdir/debs/
chroot rootdir git clone https://github.com/ptitSeb/box86 --depth 1 && cd box86 && patch -p1 < /patches/box86.patch && mkdir build && cd build && cmake .. -DCMAKE_C_COMPILER=/usr/bin/arm-linux-gnueabi-gcc-14 -DSD8G2=1 && make -j$(nproc) && make install DESTDIR=/debs
chroot rootdir git clone https://github.com/ptitSeb/box64 --depth 1 && cd box64 && mkdir build && cd build && cmake .. -DCMAKE_C_COMPILER=/usr/bin/aarch64-linux-gnu-gcc-14 -DSD8G2=1 && make -j$(nproc) && make install DESTDIR=/debs

cp -rf rootdir/debs/* debs/

dpkg-deb --build --root-owner-group debs
