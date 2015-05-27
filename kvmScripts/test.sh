#! /bin/bash

host=192.168.122.122 # IP assigned to $vm
user=mroot
pw=lightblue

sshOK=$(ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@$host whoami |& grep -e "^root")
sleep 2
if [ ! "$sshOK" ]; then
   empty -f -i in -o out scp -o StrictHostKeyChecking=no /root/.ssh/id_dsa.pub $user@$host:
   empty -w -i out -o in "assword: " "$pw\n"
   echo "Part 1 finished"
   sleep 1 
   empty -f -i in1 -o out1 ssh -o StrictHostKeyChecking=no $user@$host "mkdir ~/.ssh  2> /dev/null;cat ~/id_dsa.pub >> ~/.ssh/authorized_keys "
   empty -w -i out1 -o in1 "assword: " "$pw\n"
   echo "Part 2 finished"
   sleep 1
   empty -f -i in2 -o out2 ssh -t -o StrictHostKeyChecking=no $user@$host "sudo mkdir /root/.ssh  2> /dev/null;sudo cp /home/$user/id_dsa.pub  /root/.ssh/authorized_keys "
   empty -w -i out2 -o in2 "for $user: " "$pw\n"
   empty -s -o in2 "exit\n" 
   sleep 1
   echo "Part 3 finished"
else
   echo "Already has root access to $host"
fi
echo "ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@$host whoami |& grep -e '^root'"
sshOK=$(ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@$host whoami |& grep -e "^root")
echo $sshOK