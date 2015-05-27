#! /bin/bash

# nested VM
#
# NB! Use virt-manager version 1.0.0 (here at trident) 1.0.1 fails with 
# ERROR    'Os' object has no attribute 'get_distro'
#


if [ ! "$1" ]
then
   echo "Usage: $0 vmNumber"
   exit
fi

vmNR=$1
dir=/root/kvmScripts
logDir=$dir/log
GB=$((10 + $vmNR))
vm=nested$vmNR
vnc=$((6900 + $vmNR))

mkdir $logDir
mkdir /root/images

virsh destroy $vm
virsh undefine $vm # Will be built from scratch

cd /root/images
file=ubuntu12.04.amd64.${GB}G.img 
/bin/rm $file
qemu-img create -f qcow2 $file ${GB}G

# Enter IP in /root/preseed/preseed.cfg
cat /root/preseed/preseed.cfg.orig | sed s/192.168.122.4/10.0.0.$vmNR/  | sed s/192.168.122.1/10.0.0.1/ > /root/preseed/preseed.tmp.cfg
cat /root/preseed/preseed.tmp.cfg | sed s/control2/$vm/ > /root/preseed/preseed.cfg

date > $logDir/startVM$vmNR

/root/virt-manager/virt-install --name $vm --ram 1024 --vcpus=1 \
--os-type=linux  --initrd-inject=/root/preseed/preseed.cfg \
--disk path=/root/images/$file,device=disk,bus=ide,format=qcow2 \
--bridge=virbr0 \
--location=http://no.archive.ubuntu.com/ubuntu/dists/precise/main/installer-amd64 \
--vnc --vncport=$vnc --vnclisten=0.0.0.0 \
--extra-args "file=file:/root/preseed/preseed.cfg"

# --location=http://archive.ubuntu.com/ubuntu/dists/precise/main/installer-amd64 \

echo "Waiting for virt-install to finish..."
echo ""
running=$(ps aux | grep "name $vm" | grep -v grep)

if [ ! "$running" ]
then
   echo "kvm not running, something went wrong. Exits and restarts building..."
   exec $0 "$@"
fi

min=0
while [ "$running" ]
do
   sleep 10
   ((wait = $wait + 10))
   rest=$(($wait % 60))
   if [ $rest = 0 ]; then 
      ((min = $min + 1))
      echo -en "Has waited $min minutes\r"
      if [ $min = 300 ]; then 
         echo "Has waited 300 minutes, 5 hours. Exits and restarts building..."
         exec $0 "$@"
      fi
   fi
   running=$(ps aux | grep "name $vm" | grep -v grep)
done
echo "virt-install finished"

date > $logDir/finishedVM$vmNR

virsh start $vm
sleep=$(( 30 + $vmNR ))
sleep $sleep

host=10.0.0.$vmNR
user=mroot
pw=lightblue

if [ ! -f /root/.ssh/id_dsa ]; then
   ssh-keygen -t dsa -N "" -f /root/.ssh/id_dsa
fi
ssh-keygen -f "/root/.ssh/known_hosts" -R $host

empty -l
if [ $? != 0 ]; then 
   apt-get install empty-expect -y
fi

loop=0
sshOK=$(ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@$host whoami |& grep -e "^root")
while [ ! "$sshOK" ]
do
   if [ $loop = 100 ]; then 
         echo "Has tried a hundred times. Exits and restarts building..."
         exec $0 "$@"
   fi
   # Rebooting takes time and operation not always successfull, hence looping
   ((loop = $loop + 1))
   killall empty # Might be collision with others, but sleeptime different. Fixed in the end
   sleep $sleep
   empty -f -i in -o out scp -o StrictHostKeyChecking=no /root/.ssh/id_dsa.pub $user@$host:
   empty -w -i out -o in "assword: " "$pw\n"
   echo "Part 1 finished"
   # empty -s -o in "exit\n"
   sleep 1 
   empty -f -i in1 -o out1 ssh -o StrictHostKeyChecking=no $user@$host "mkdir ~/.ssh  2> /dev/null;cat ~/id_dsa.pub >> ~/.ssh/authorized_keys "
   empty -w -i out1 -o in1 "assword: " "$pw\n"
   echo "Part 2 finished"
   #empty -s -o in2 "exit\n" 

   sleep 1
   empty -f -i in2 -o out2 ssh -t -o StrictHostKeyChecking=no $user@$host "sudo mkdir /root/.ssh  2> /dev/null;sudo cp /home/mroot/id_dsa.pub  /root/.ssh/authorized_keys "
   empty -w -i out2 -o in2 "for mroot: " "$pw\n"
   empty -s -o in2 "exit\n" 
   sleep 1
   echo "Part 3 finished"
   sshOK=$(ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@$host whoami |& grep -e "^root")
done

# Same kernel for nested host?

#scp -r /root/preseed root@$host:/root/
#scp -r $dir root@$host:/root/
# ssh root@$host "/bin/bash -x $dir/kernel.sh"
ssh root@$host "wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v3.13.1-trusty/linux-headers-3.13.1-031301-generic_3.13.1-031301.201401291035_amd64.deb"
ssh root@$host "wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v3.13.1-trusty/linux-image-3.13.1-031301-generic_3.13.1-031301.201401291035_amd64.deb"
ssh root@$host "wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v3.13.1-trusty/linux-headers-3.13.1-031301_3.13.1-031301.201401291035_all.deb"
ssh root@$host "dpkg -i linux-headers-3.13.1-031301_3.13.1-031301.201401291035_all.deb"
ssh root@$host "dpkg -i linux-headers-3.13.1-031301-generic_3.13.1-031301.201401291035_amd64.deb"
ssh root@$host "dpkg -i linux-image-3.13.1-031301-generic_3.13.1-031301.201401291035_amd64.deb"
scp $dir/initrd.img-3.13.1-031301-generic root@$host:/boot/ # This img is sometimes not made...
# Needs to reboot into new kernel. destroy-start fails for some reason
ssh root@$host "reboot"
echo "WM kernel installation finished. rebooting into new kernel"

kernelVersion="3.13"
loop=0
sshOK=$(ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@$host uname -a |& grep -e $kernelVersion)
# Demands nested host is up with the new kernel version, or starts from scratch after many trials
while [ ! "$sshOK" ]
do
   if [ $loop = 120 ]; then 
         echo "Has tried for two hours. Exits and restarts building from scratch..."
         exec $0 "$@"
   fi
   # Rebooting takes time and operation not always successfull, hence looping
   ((loop = $loop + 1))
   sleep 60
   echo "Has connected root@$host $loop times"
   sshOK=$(ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@$host uname -a |& grep -e "3.13")
done

#sleep 30

# Doesn't need qemu and libvirt at nested host (yet?)
#scp -r /root/qemu1.7.50 root@$host:/root/qemu1.7.50
#ssh root@$host "mkdir /root/qemu"
#scp -r /root/qemu/libvirt root@$host:/root/qemu/  # Because it is like this at trident/control
#ssh root@$host "/bin/bash -x /root/kvmScripts/vm.sh"

#scp -r /root/virt-manager root@$host:/root/ # Version 1.0.0 

#scp /usr/lib/python2.7/dist-packages/*libvirt* root@$host:/usr/lib/python2.7
#ssh root@$host /root/virt-manager/virt-install --version

#ssh root@$host "modprobe kvm_amd"
#ssh root@$host "libvirtd -d"
#sleep 5 # Some folders must be made first?

#ssh root@$host "service dnsmasq stop" # Or else conflict
#ssh root@$host "virsh net-destroy default" # The default 192.168.122.0 network
#ssh root@$host "virsh net-undefine default"
#scp -r $dir/default.xml root@$host:/etc/libvirt/qemu/networks/default.xml
#ssh root@$host "virsh net-define /etc/libvirt/qemu/networks/default.xml"
#ssh root@$host "virsh net-autostart default"
#ssh root@$host "virsh net-start default"

# Nested; test another layer :)
#GB=$((10 + $vmNR))
#scp /root/preseed/preseedNested.cfg root@$host:/root/preseed/preseed.cfg
#file=/root/images/ubuntu12.04.amd64.${GB}G.img 
#ssh root@$host "/bin/rm $file"
#ssh root@$host "mkdir /root/images"
#ssh root@$host "qemu-img create -f qcow2 $file ${GB}G"
#ssh root@$host "/root/virt-manager/virt-install --name controlNested --ram 2048 --vcpus=1 --os-type=linux  --initrd-inject=/root/preseed/preseed.cfg --disk path=$file,device=disk,bus=virtio,format=qcow2 --bridge=virbr0 --location=http://archive.ubuntu.com/ubuntu/dists/precise/main/installer-amd64 --vnc --vncport=$vncNested --vnclisten=0.0.0.0 --extra-args \"file=file:/root/preseed/preseed.cfg\""

date > $logDir/finishedNewVM$vmNR
