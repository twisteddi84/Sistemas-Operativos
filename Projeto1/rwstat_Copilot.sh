#!/bin/bash

# This is a function that will write to the terminal the readbytes and writebytes of a process 

function get_pid_stats() {
    local pid=$1

    local sleeptime=$2

    # get the readbytes and writebytes of the process
    local readbytes=$(grep -E 'read_bytes' /proc/$pid/io | awk '{print $2}')
    
    local writebytes=$(grep -E 'write_bytes' -w /proc/$pid/io | awk '{print $2}')

    #sleep for sleeptime
    sleep $sleeptime

    # get the read and write bytes stats again
    local readbytes2=$(grep -E 'read_bytes' /proc/$pid/io | awk '{print $2}')

    local writebytes2=$(grep -E 'write_bytes' -w /proc/$pid/io | awk '{print $2}')

    # calculate the read bytes per second and write bytes per second

    local readbps=$((($readbytes2 - $readbytes) / $sleeptime))

    local writebps=$((($writebytes2 - $writebytes) / $sleeptime))

    #create a variable for the /proc/[pid]/comm file
    local comm=$(cat /proc/$pid/comm)

    #create a variable for the creation date and time without the seconds and year of the process
    local creationdate=$(date -d "$(ps -p $pid -o lstart | tail -1 | awk '{print $1, $2, $3, $4}')" +"%b %d %H:%M")

    #create a variable for the user of the process
    local user=$(ps -p $pid -o user | tail -1)

    #print a table with the process comm, user, pid, readbytes, writebytes, readbps, writebps, creationdate
    printf "\n %-20s %-10s %+6s %+10s %+10s %+10s %+10s %+15s \n" "$comm" "$user" "$pid" "$readbytes" "$writebytes" "$readbps" "$writebps" "$creationdate"

}

printf "\n %-20s %-10s %+6s %+10s %+10s %+10s %+10s %+15s \n" "COMM" "USER" "PID" "READB" "WRITEB" "RATER" "RATEW" "DATE"
ps -u $USER -o pid= | while read pid; do
# if the user has permission to read the /proc/[pid]/io file
    if [ -r /proc/$pid/io ]; then
        get_pid_stats $pid 1
    fi
done