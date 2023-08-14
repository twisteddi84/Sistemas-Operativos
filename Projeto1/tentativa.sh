#!/bin/bash

declare -A readvalues1=()
declare -A writevalues1=()

declare -A readvalues2=()
declare -A writevalues2=()

declare -A argumentos = ()


#Save all process read and write values in a dictionary and ignore the no permission error
for pid in $(ps -e -o pid=); do
    readvalues1[$pid]=$(grep -E 'read_bytes' /proc/$pid/io 2>/dev/null | awk '{print $2}')
    writevalues1[$pid]=$(grep -E 'write_bytes' -w /proc/$pid/io 2>/dev/null | awk '{print $2}')
done

#print the dictionary and sort by pid
for pid in "${!readvalues1[@]}"; do
    echo "PID: $pid - Read: ${readvalues1[$pid]} - Write: ${writevalues1[$pid]}"
done | sort -n -k 2

#Store first argument in sleeptime

sleeptime=$1

#sleep for sleeptime
sleep $sleeptime

#Save all process read and write values in a dictionary and ignore the no permission error
for pid in $(ps -e -o pid=); do
    readvalues2[$pid]=$(grep -E 'read_bytes' /proc/$pid/io 2>/dev/null | awk '{print $2}')
    writevalues2[$pid]=$(grep -E 'write_bytes' -w /proc/$pid/io 2>/dev/null | awk '{print $2}')
done


echo "---------------------"

#Print readvalue1 of pid 2412
echo "Readvalue1 of pid 2412: ${readvalues1[2412]}"
echo "Readvalue2 of pid 2412: ${readvalues2[2412]}"
echo "Writevalue1 of pid 2412: ${writevalues1[2412]}"
echo "Writevalue2 of pid 2412: ${writevalues2[2412]}"   
#Echo the difference between the read and write values of pid 2412
echo "Read difference: $((${readvalues2[2412]} - ${readvalues1[2412]}))"
echo "Write difference: $((${writevalues2[2412]} - ${writevalues1[2412]}))"
echo "RateWrite: $(((${writevalues2[2412]}-${writevalues1[2412]})/$sleeptime ))"
