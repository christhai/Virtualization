#! /bin/bash

# cloning an existing VM
# Using shutdown after editing VM, destroy might not sync

if [ ! "$1" -o ! "$2" ]
then
   echo "Usage: $0 serverNR1 serverNR2"
   echo "clones serverNR1 into serverNR2"
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

virsh shutdown $origVM # Should not run
sleep 2
while [ "$(virsh list | grep $vm )" ]
do
   virsh shutdown $vm  # Might exist
   (( loop++ ))
   if (( loop == 10 )); then
      virsh destroy $vm
      echo "$vm had to be destroyed"
   fi
   sleep 2
done

virsh undefine $vm # Will be built from scratch

file1=$imgDir/$imgName$vmNR1.img 
file2=$imgDir/$imgName$vmNR2.img 
/bin/cp $file1 $file2

uuid=$(uuidgen) # New uuid for libvirt xml-file
mac="52:54:00:9b:$(printf '%04X\n' $vmNR2 | cut -c 1-2,3-4 --output-delimiter=':')"

cat $qemuDir/$origVM.xml | sed s/$origVM/$vm/ > /tmp/xml
cat /tmp/xml | sed s/uuid\>.*\</uuid\>$uuid\</g > /tmp/xml2
cat /tmp/xml2 | sed s@$file1@$file2@g > /tmp/xml
cat /tmp/xml | sed s/"mac address='.*'"/"mac address=\'$mac\'"/g > $qemuDir/$vm.xml

sleep 5
virsh define $qemuDir/$vm.xml
virsh start $vm

sshOK=$(ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@$IP1 whoami |& grep -e "^root")
while [ ! "$sshOK" ]
do
echo "$IP1 not yet reachable using ssh"
sleep 5
sshOK=$(ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@$IP1 whoami |& grep -e "^root")
done
echo "$IP1 reachable using ssh"

net=/etc/network/interfaces
netTMP=/etc/network/interfaces.tmp
ssh root@$IP1 "cat $net | sed s/$IP1/$IP2/ > $netTMP; /bin/mv $netTMP $net"
#sleep 1
hosts=/etc/hosts
hostsTMP=/etc/hostsTmp
ssh root@$IP1 "cat $hosts | sed s/$IP1/$IP2/ > $hostsTMP"
ssh root@$IP1 "cat $hostsTMP | sed s/$origVM/$vm/g > $hosts; /bin/rm $hostsTMP"
echo "$hosts at $IP1:"
ssh root@$IP1 "cat $hosts"
#sleep 1
hostname=/etc/hostname
hostnameTMP=/etc/hostnameTmp
ssh root@$IP1 "cat $hostname | sed s/$origVM/$vm/ > $hostnameTMP; /bin/cp $hostnameTMP $hostname"
echo "$hostname at $IP1:"
ssh root@$IP1 "cat $hostname"

virsh shutdown $vm # store the networking files
sleep 3
while [ "$(virsh list | grep $vm )" ]
do
   virsh shutdown $vm  
   (( loop++ ))
   if (( loop == 10 )); then
      virsh destroy $vm
      echo "$vm had to be destroyed"
   fi
   sleep 2
done

sleep 3
virsh start $vm  # restarts VM with new IP and name

