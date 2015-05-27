#! /bin/bash

# cloning an existing VM

if [ ! "$1" -o ! "$2" ]
then
   echo "Usage: $0 serverNR1 serverNR2"
   echo "clones sernveNR1 into serverNR2"
   exit
fi

vmNR1=$1
vmNR2=$2

qemuDir=/etc/libvirt/qemu
imgDir=/root/qemu/images
imgName=ubuntu14.04.amd64.4G
origVM=server$vmNR1
vm=server$vmNR2       # VM name
IP1=192.168.122.$vmNR1
IP2=192.168.122.$vmNR2
user=mroot
pw=lightblue
dir=/root/kvmScripts
ios=/root/IncludeOS

#ssh-keygen -f "/root/.ssh/known_hosts" -R $IP1 
#ssh-keygen -f "/root/.ssh/known_hosts" -R $IP2

# For some reason server name is not always set, hence the following loop
serverNameOK=$(ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@$IP2 hostname |& grep -e "^$vm")
while [ ! "$serverNameOK" ]
do
echo "$IP2 server name not set"
hostname=/etc/hostname
hostnameTMP=/etc/hostnameTmp
ssh root@$IP2 "cat $hostname | sed s/$origVM/$vm/ > $hostnameTMP"
ssh root@$IP2 "/bin/cp $hostnameTMP $hostname"
echo "cat $hostname | sed s/$origVM/$vm/ > $hostnameTMP; /bin/cp $hostnameTMP $hostname"
echo "$hostname at $IP2:"
ssh root@$IP2 "cat $hostname"
sleep 3
virsh shutdown $vm 
sleep 3
virsh start $vm  # restarts VM with new IP and name
sleep 10
serverNameOK=$(ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@$IP2 hostname |& grep -e "^$vm")
done

echo "$IP2 server name set to $serverNameOK"

