#! /bin/bash

# sometimes this occurs:
# -rw-r--r-- 1 root root        0 Apr 24 11:43 initrd.img-3.13.1-031301-generic
# It usually helps to do this over again...

cd /root
dpkg -i linux-image-3.13.1-031301-generic_3.13.1-031301.201401291035_amd64.deb

# /sbin/halt -f
# stopped and restarted by virsh

