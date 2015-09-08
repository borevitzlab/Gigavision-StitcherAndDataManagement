#!/bin/bash

LOGGER="/Users/admin/Gigavision/PROGRAMsuite/logger.sh"
SCRIPT="run_with_timeout.sh"

sh $LOGGER $SCRIPT "Starting run_with_timeout.sh"

$* & #Runs whatever command you used as a parameter.

#sh "Applications/GigaPan\ 1.1.1191/GigaPan\ Stitch\ 1.1.1191.app/Contents/MacOS/GigaPan\ Stitch\ 1.1.1191 --batch-mode --align-quit --title BigBlowoutEastSmall_2011_01_13_12 --image-list BB_example_imagelist.txt --rowfirst --downward --rightward --nrows 19 --save-as  /Users/admin/Gigavision/projects/BigBlowoutEast/images/lowres/2011/2011_01/2011_01_13/BigBlowoutEastSmall_2011_01_13_12_test.gigapan"

pid=$! #Gets the process id of the command you started.
echo pid= $pid

#Configure number of hours to run
HOURS_TO_RUN=1

START_HOUR=$(date +%M) #Gets the current hour
START_MINUTE=$(date +%S) # Gets the current minute
END_HOUR=$(($START_HOUR+$HOURS_TO_RUN))
echo END_HOUR= $END_HOUR
if [ $END_HOUR > 23 ]; then
 #END_HOUR=$(($END_HOUR-24))
 echo wrap hour
fi
echo END_HOUR adjusted= $END_HOUR


IS_NOT_RUNNING="0"

while [ "$IS_NOT_RUNNING" == "0" ]; do
    LOOP_HOUR=$(date +%M)
    LOOP_MINUTE=$(date +%S)
    echo LOOP_HOUR= $LOOP_HOUR LOOP_MINUTE= $LOOP_MINUTE
    
    if [[ $LOOP_HOUR == $END_HOUR ]] ; then
        if [ "$LOOP_MINUTE" > "$END_MINUTE"] ; then
            echo "Timeout has occurred... terminating process and exiting."
            kill -9 $pid
            #Stop executing this process.
            break;
        fi
    fi
    
    kill -0 $pid # This simply gets the status of the running process.
    
    IS_NOT_RUNNING=`echo "$?"` # $? holds response from last command - so it holds 1 if its not running, it holds 0 if it is running.
    echo "is not running: $IS_NOT_RUNNING"   
    sleep 2 #Sleep 5 seconds.
done

echo "Completed run_with_timeout.sh"