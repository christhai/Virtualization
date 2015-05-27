#! /bin/bash

# for vm in 2 3 4 6 9 10
for vm in 11 12 13 14
do
   ./makeVM.sh $vm
   echo "./makeVM.sh $vm"
done

echo "Finished -14"
