#! /bin/bash

dir=/root
cd $dir
git clone https://github.com/qemu/qemu.git 
apt-get install make jed libpixman-1-dev pkg-config zlib1g zlib1g-dev libglib2.0-dev libosinfo-1.0-dev -y
apt-get install git build-essential bc -y
cd qemu
mkdir -p bin/native
cd bin/native/
../../configure --target-list=x86_64-softmmu
make clean
make
make install
rm /usr/bin/kvm
ln -s /usr/local/bin/qemu-system-x86_64 /usr/bin/kvm

cd $dir
apt-get install libtool python-dev autoconf automake autopoint xsltproc libyajl1 libyajl-dev libxml2-dev libxml2-utils libdevmapper-dev libpciaccess-dev libnl-dev -y
apt-get install python-urlgrabber python-libxml2 pm-utils w3c-dtd-xhtml cpu-checker gettext -y 
apt-get install -y libgnutls-dev
apt-get install -y libudev-dev dnsmasq # dnsmasq needed before compiling libvirt
apt-get install -y acpid # In order to be able to reboot using virsh
service dnsmasq stop # Or else conflict

cd $dir/qemu
git clone git://libvirt.org/libvirt.git
# Before: Copied from trident (version 1.2.3) avoiding new compiling errors

cd $dir/qemu/libvirt
make clean
./autogen.sh --system
make
make install


kvm-ok -version
# if
#INFO: /dev/kvm does not exist
#HINT:   sudo modprobe kvm_amd
#INFO: Your CPU supports KVM extensions
#KVM acceleration can be used
# mknod /dev/kvm c 10 232

cd $dir
apt-get install python-distro-info python-ipaddr -y
