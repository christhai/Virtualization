#! /bin/bash

# Using newest versions from apt

if [ ! "$1" ]
then
   echo "Usage: $0 vmNumber"
   exit
fi

apt-get update

vmNR=$1
dir=/root/kvmScripts
logDir=$dir/log
GB=$((20 + $vmNR))
vm=control$vmNR
vnc=$((5900 + $vmNR))
vncNested=$((6900 + $vmNR))

virsh destroy $vm
virsh undefine $vm # Will be built from scratch

cd /root/qemu/images
file=ubuntu14.04.amd64.${GB}G.img 
/bin/rm $file
qemu-img create -f qcow2 $file ${GB}G

# Enter IP in /root/preseed/preseed.cfg
cat /root/preseed/preseed.cfg.orig | sed s/192.168.122.4/192.168.122.$vmNR/ > /root/preseed/preseed.tmp.cfg
cat /root/preseed/preseed.tmp.cfg | sed s/control2/$vm/ > /root/preseed/preseed.cfg

date > $logDir/startVM$vmNR

/root/virt-manager/virt-install --name $vm --ram 10240 --vcpus=4 \
--os-type=linux  --initrd-inject=/root/preseed/preseed.cfg \
--disk path=/root/qemu/images/$file,device=disk,bus=ide,format=qcow2 \
--bridge=virbr0 \
--location=http://no.archive.ubuntu.com/ubuntu/dists/trusty/main/installer-amd64 \
--vnc --vncport=$vnc --vnclisten=0.0.0.0 \
--extra-args "file=file:/root/preseed/preseed.cfg"

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
      
min=0
while [ "$running" ]
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
   running=$(ps aux | grep "name $vm" | grep -v grep)
done
echo "virt-install finished"

date > $logDir/finishedVM$vmNR

sleep=40
virsh start $vm
sleep $sleep

host=192.168.122.$vmNR
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
   if [ $loop = 20 ]; then 
         echo "Has tried 20 times. Exits and restarts building..."
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

scp -r /root/preseed root@$host:/root/
scp -r $dir root@$host:/root/

ssh root@$host "echo GRUB_RECORDFAIL_TIMEOUT=2 >> /etc/default/grub"
# In order to make reboot automatic after unclean shutdown
ssh root@$host /usr/sbin/update-grub

# ssh root@$host "/bin/bash -x $dir/kernel.sh"
#ssh root@$host "wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v3.13.1-trusty/linux-headers-3.13.1-031301-generic_3.13.1-031301.201401291035_amd64.deb"
#ssh root@$host "wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v3.13.1-trusty/linux-image-3.13.1-031301-generic_3.13.1-031301.201401291035_amd64.deb"
#ssh root@$host "wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v3.13.1-trusty/linux-headers-3.13.1-031301_3.13.1-031301.201401291035_all.deb"
#ssh root@$host "dpkg -i linux-headers-3.13.1-031301_3.13.1-031301.201401291035_all.deb"
#ssh root@$host "dpkg -i linux-headers-3.13.1-031301-generic_3.13.1-031301.201401291035_amd64.deb"
#ssh root@$host "dpkg -i linux-image-3.13.1-031301-generic_3.13.1-031301.201401291035_amd64.deb"
#scp $dir/initrd.img-3.13.1-031301-generic root@$host:/boot/ # This img is sometimes not made...
# Needs to reboot into new kernel. destroy-start fails for some reason
#ssh root@$host "reboot"
#echo "WM kernel installation finished. Waiting 30 sec for reboot into new kernel"

ssh root@$host "apt-get install -y kvm libvirt-bin git"
ssh root@$host "apt-get install -y xinit lxde-core tightvncserver lxterminal chromium-browser"
vncserver=$((1000 + $vmNR))

ssh mroot@$host "mkdir ~/.vnc"
scp $dir/vnc/passwd mroot@$host:~/.vnc
scp $dir/vnc/xstartup mroot@$host:~/.vnc

ssh mroot@$host "vncserver :$vncserver -geometry 1920x1200"
dport=$((5900 + $vncserver))
iptables -t nat -A PREROUTING -p tcp --dport $dport -j DNAT --to-destination $host

exit

scp -r /root/MMnested root@$host:/root/     # Micro Machines

# scp /usr/lib/python2.7/dist-packages/*libvirt* root@$host:/usr/lib/python2.7
# ssh root@$host /root/virt-manager/virt-install --version

ssh root@$host "service dnsmasq stop" # Or else conflict
ssh root@$host "virsh net-destroy default" # The default 192.168.122.0 network
ssh root@$host "virsh net-undefine default"
scp -r $dir/default.xml root@$host:/etc/libvirt/qemu/networks/default.xml
ssh root@$host "virsh net-define /etc/libvirt/qemu/networks/default.xml"
ssh root@$host "virsh net-autostart default"
ssh root@$host "virsh net-start default"

scp -r $dir/rc.local root@$host:/etc

date > $logDir/finishedNewVM$vmNR

# Making a couple of nested VM's, -f means background, making the 
# scripts run in parallel

#ssh -f root@$host "$dir/makeNestedVM.sh 2"
#ssh -f root@$host "$dir/makeNestedVM.sh 3"



