#! /bin/bash

dir=/root
cd $dir
# git clone https://github.com/qemu/qemu.git # (Uses same version as trident, 1.7.50)
# Done in makeVM.sh:
# scp -r mroot@trident1.vlab.cs.hioa.no:/root/qemu/qemu qemu1.7.50
apt-get install make jed libpixman-1-dev pkg-config zlib1g zlib1g-dev libglib2.0-dev libosinfo-1.0-dev -y
apt-get install git build-essential bc -y
cd qemu1.7.50/
mkdir -p bin/native
cd bin/native/
../../configure --target-list=x86_64-softmmu
make clean
make
make install
rm /usr/bin/kvm
ln -s /root/qemu1.7.50/bin/native/x86_64-softmmu/qemu-system-x86_64 /usr/bin/kvm
# type kvm

#mkdir $dir/images
#cd $dir/images
#qemu-img create -f qcow2 ubuntu12.04.amd64.img 10G

cd $dir
apt-get install libtool python-dev autoconf automake autopoint xsltproc libyajl1 libyajl-dev libxml2-dev libxml2-utils libdevmapper-dev libpciaccess-dev libnl-dev -y
apt-get install python-urlgrabber python-libxml2 pm-utils w3c-dtd-xhtml cpu-checker gettext -y 
apt-get install -y libgnutls-dev
apt-get install -y libudev-dev dnsmasq # dnsmasq needed before compiling libvirt
apt-get install -y acpid # In order to be able to reboot using virsh
service dnsmasq stop # Or else conflict

# git clone git://libvirt.org/libvirt.git
# Copied from trident (version 1.2.3) avoiding new compiling errors

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

#root@control2:~/libvirt/virt-manager# ./virt-install --version
#Traceback (most recent call last):
#  File "./virt-install", line 26, in <module>
#      import libvirt
#      ImportError: No module named libvirt
# Therfore:
# apt-get install python-libvirt -y
# Warning: this also installs apt-version of libvirt 
# (so copy like below instead from dist-packages)

#root@control2:~/libvirt/virt-manager#  apt-get install python-libvirt
#Reading package lists... Done
#Building dependency tree       
#Reading state information... Done
#The following extra packages will be installed:
#  bridge-utils cgroup-lite dnsmasq-base ebtables gawk libapparmor1 libavahi-client3
#    libavahi-common-data libavahi-common3 libnetfilter-conntrack3 libnuma1 libsigsegv2
#      libvirt-bin libvirt0 libxenstore3.0
#      Suggested packages:
#        policykit-1 qemu-kvm qemu radvd lvm2
#	The following NEW packages will be installed:
#	  bridge-utils cgroup-lite dnsmasq-base ebtables gawk libapparmor1 libavahi-client3
#	    libavahi-common-data libavahi-common3 libnetfilter-conntrack3 libnuma1 libsigsegv2
#	      libvirt-bin libvirt0 libxenstore3.0 python-libvirt
	      
# NB! Uses virt-manager version 1.0.0 (here at trident) 1.0.1 fails with 
# ERROR    'Os' object has no attribute 'get_distro'
# Installed by makeVM.sh
# git clone     git://git.fedorahosted.org/virt-manager.git

# The rest now in makeVM.sh

# root@trident1:~# scp /usr/lib/python2.7/dist-packages/*libvirt* mroot@192.168.122.3:
# root@control2:~# cp /home/mroot/*libvirt* /usr/lib/python2.7

# root@control2:~# /root/virt-manager/virt-install --version
# 1.0.1

#root@trident1:~# virsh edit control2
#
#  <cpu mode='host-passthrough'>
#    </cpu>
# Or else kvm_amd won't load

# root@control2:~# modprobe kvm_amd
# root@control2:~# lsmod | grep kvm
# kvm_amd                60554  0 
# kvm                   468147  1 kvm_amd
# root@control2:~# 
 
