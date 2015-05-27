#! /bin/bash

cd /root
apt-get install jed -y

wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v3.13.1-trusty/linux-headers-3.13.1-031301-generic_3.13.1-031301.201401291035_amd64.deb
wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v3.13.1-trusty/linux-image-3.13.1-031301-generic_3.13.1-031301.201401291035_amd64.deb
wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v3.13.1-trusty/linux-headers-3.13.1-031301_3.13.1-031301.201401291035_all.deb
dpkg -i linux-headers-3.13.1-031301_3.13.1-031301.201401291035_all.deb
dpkg -i linux-headers-3.13.1-031301-generic_3.13.1-031301.201401291035_amd64.deb
dpkg -i linux-image-3.13.1-031301-generic_3.13.1-031301.201401291035_amd64.deb

# sometimes this occurs:
# -rw-r--r-- 1 root root        0 Apr 24 11:43 initrd.img-3.13.1-031301-generic
# It usually helps to reboot and do
#
#dpkg -i linux-image-3.13.1-031301-generic_3.13.1-031301.201401291035_amd64.deb
#
# once more
# 
# stopped and restarted by virsh

