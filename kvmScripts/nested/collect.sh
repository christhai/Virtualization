#! /bin/bash

dir=/root/MMnested/perfdata/logdata
for vm in $(seq 3 12)
do 
   echo -n "VM$vm: "
   scp -r root@192.168.122.$vm:$dir vm$vm 
done
