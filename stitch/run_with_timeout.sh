#!/bin/bash
#############################################################
# File: 	run_with_timeout.sh
# Author: 	Christopher Zimmermann
# Date: 	January 20, 2010
#
# Function: To run the stitcher with a timeout of 3 hours - this is for the situation where the stitcher gets stuck and is unable to process the gigapan. Eventually it will timeout.
#
# Operations: 
#
# Based on: http://stackoverflow.com/questions/743219/bash-to-beep-if-command-takes-more-than-1-minute-to-finish

#LOAD Global Configuration
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$DIR"/../shared/config.ini

SCRIPT="run_with_timeout.sh"

sh $LOGGER $SCRIPT "Starting run_with_timeout.sh"

CMD_TO_RUN=$1
sh $LOGGER $SCRIPT "CMD_TO_RUN= $CMD_TO_RUN"

cd "$TMP_FLDR"
eval "$CMD_TO_RUN &"

pid=$! #Gets the process id of the last command you started.
echo pid= $pid

#Configure number of hours to run
HOURS_TO_RUN=2
SECONDS_TO_RUN=$(($HOURS_TO_RUN*60*60))

START_SECOND=$(date +%s) #Gets the current second

sh $LOGGER $SCRIPT " START_SECOND= $START_SECOND SECONDS_TO_RUN= $SECONDS_TO_RUN"

IS_NOT_RUNNING="0"

while [ "$IS_NOT_RUNNING" == "0" ]; do
    LOOP_SECOND=$(date +%s)
    SECONDS_ELAPSED=$(($LOOP_SECOND-$START_SECOND))
    echo SECONDS_ELAPSED= $SECONDS_ELAPSED SECONDS_TO_RUN= $SECONDS_TO_RUN

    if [ "$SECONDS_ELAPSED" -ge "$SECONDS_TO_RUN" ] ; then
        sh $LOGGER $SCRIPT  "Timeout has occurred... terminating process and exiting."
        kill -9 $pid #Stop executing this process.     
        break; #Exit Loop.
    fi
    
    kill -0 $pid # This simply gets the status of the running process.    
    IS_NOT_RUNNING=`echo "$?"` # $? holds response from last command - so it holds 1 if its not running, it holds 0 if it is running.
#echo "is not running: $IS_NOT_RUNNING"   
    sleep 60 #seconds.
done

sh $LOGGER $SCRIPT  "Completed run_with_timeout.sh"