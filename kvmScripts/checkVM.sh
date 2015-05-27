#! /bin/bash

for vm in $(seq 3 12) 14
do 
   echo "VM$vm: "
#   scp /root/MMnested/run root@192.168.122.$vm:/root/MMnested 
    ssh -f -o BatchMode=yes -o connectTimeout=20 root@192.168.122.$vm /root/MMnested/run   
done
