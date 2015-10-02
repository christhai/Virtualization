#! /bin/bash

# Using newest versions from apt
# Making desktop

if [ ! "$1" ]
then
   echo "Usage: $0 vmNumber"
   exit
fi

# apt-get update

vmNR=$1
host=192.168.122.$vmNR
user=mroot
pw=lightblue
dir=/home/s199425/kvmScripts
logDir=$dir/log
GB=$((20 + $vmNR))    # 20GB image ++
vm=control$vmNR       # VM name
vnc=$((5900 + $vmNR))
vncNested=$((6900 + $vmNR))

virsh destroy $vm
virsh undefine $vm # Will be built from scratch

cd ../images
file=ubuntu14.04.amd64.${GB}G.img 
/bin/rm $file
# qemu-img create -o compat=0.10 -f qcow2 $file ${GB}G
qemu-img create -f qcow2 $file ${GB}G

# Enters IP and name in /root/preseed/preseed.cfg
cat ../preseed/preseed.cfg.orig | sed s/192.168.122.4/192.168.122.$vmNR/ > ../preseed/preseed.tmp.cfg
cat ../preseed/preseed.tmp.cfg | sed s/control2/$vm/ > ../preseed/preseed.cfg

date > $logDir/startVM$vmNR

virt-install --name $vm --ram 1024 --vcpus=1 \
--os-type=linux  --initrd-inject=../preseed/preseed.cfg \
--disk path=../images/$file,device=disk,bus=ide,format=qcow2 \
--bridge=virbr0 \
--location=http://no.archive.ubuntu.com/ubuntu/dists/trusty/main/installer-amd64 \
--vnc --vncport=$vnc --vnclisten=0.0.0.0 \
--extra-args "file=file:../preseed/preseed.cfg"

# --location=http://archive.ubuntu.com/ubuntu/dists/trusty/main/installer-amd64 \
cd $dir

echo "Waiting for virt-install to finish..."
echo ""
running=$(ps aux | grep "name $vm" | grep -v grep)

if [ ! "$running" ]
then
   echo "kvm not running, something went wrong. Exits and restarts building..."
      exec $0 "$@"
fi

# The following depends on the VM beeing booted by virt-install after building it
# If not, running=$(ps aux | grep "name $vm" | grep -v grep) should be tested for 
# and VM started after the following loop

netOK=$(ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@$host pwd |& grep -e "Permission denied")
min=0
while [ ! "$netOK" ]
do
   sleep 10
   ((wait = $wait + 10))
   rest=$(($wait % 60))
   if [ $rest = 0 ]; then 
      ((min = $min + 1))
      echo -en "Has waited $min minutes\r"
      if [ $min = 60 ]; then 
         echo "Has waited 60 minutes. Exits and restarts building..."
         exec $0 "$@"
      fi
   fi
   netOK=$(ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@$host pwd |& grep -e "Permission denied")
   done
echo "virt-install finished" > $logDir/finishedVM$vmNR
date >> $logDir/finishedVM$vmNR

# Should now be possible to connect using ssh
# sleep=40
#virsh start $vm
# sleep $sleep
