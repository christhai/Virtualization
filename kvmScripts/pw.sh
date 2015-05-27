#! /bin/bash

# nested VM
#


if [ ! "$1" ]
then
   echo "Usage: $0 vmNumber"
   exit
fi

vmNR=$1
host=10.0.0.$vmNR
host=192.168.122.$vmNR
user=mroot
pw=lightblue

#rm /root/.ssh/id_dsa
#ssh-keygen -t dsa -N "" -f /root/.ssh/id_dsa
ssh-keygen -f "/root/.ssh/known_hosts" -R $host

apt-get install empty-expect -y
empty -f -i in -o out scp -o StrictHostKeyChecking=no /root/.ssh/id_dsa.pub $user@$host:
empty -w -i out -o in "assword: " "$pw\n"
empty -s -o in "exit\n"
sleep 1 
empty -f -i in2 -o out2 ssh -o StrictHostKeyChecking=no $user@$host "mkdir ~/.ssh  2> /dev/null;cat ~/id_dsa.pub >> ~/.ssh/authorized_keys "
empty -w -i out2 -o in2 "assword: " "$pw\n"
empty -s -o in2 "exit\n" 

sleep 1
empty -f -i in2 -o out2 ssh -t -o StrictHostKeyChecking=no $user@$host "sudo mkdir /root/.ssh  2> /dev/null;sudo cp /home/mroot/id_dsa.pub  /root/.ssh/authorized_keys "
empty -w -i out2 -o in2 "for mroot: " "$pw\n"
empty -s -o in2 "exit\n" 
sleep 1

#ssh root@$host "wget http://kernel.ubuntu.com/~kernel-ppa/mainline/v3.13.1-trusty/linux-headers-3.13.1-031301-generic_3.13.1-031301.201401291035_amd64.deb"
