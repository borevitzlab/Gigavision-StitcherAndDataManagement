#! /bin/sh
#############################################################
# File: 	STATUSprogram.sh
# Author: 	Whitney Panneton
# Date: 	August 20, 2010
#	
# Function: Generate an html file that shows the image sets waiting to be stitched
#           and which image sets are currently being stitched
#
# Operations: Generate a list of each RESname and sort them alphbetically
#               Record the RESnames (NAMES) and queue amount (NUMBERS) of old queue.html
#               Create new queue.html file and replace recorded names and numbers (this is to clear zombie queues and pr)
#               Update current queue amount for the input RESname
#               Update the number of stitching processes and the titles of them
#               Bold the RESnames of currenlty stitching queues and input resname
#	
# Called By: 	Autostitcher.sh
#
#############################################################

#LOAD Global Configuration
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$DIR"/../shared/config.ini

SCRIPT="STATUSProgram.sh"

#sh $LOGGER $SCRIPT "Starting "

cd "$TMP_FLDR"

#### Setting of Environmental Vairables from Inputs ####
MOUNTFLDR=$1
RESname=$2
COUNT=$3
UNITS=$4
ONOFF=$5
CURRENT=$6

#OTHERS holds a list of all the "stitching" files - ie BigBlowoutEastSmall_STITCHING_32930.txt
OTHERS=`ls "$TMP_FLDR" | grep "$RESname"_STITCHING`

#sh $LOGGER $SCRIPT "OTHERS= [ $OTHERS ]"

if [ -z "$OTHERS" ]; then
#sh $LOGGER $SCRIPT "STATUSprogram trace 4B - NO OTHERS."
    AMOUNT=0
else
    #AMOUNTB would just hold the contents of OTHERS.
    #AMOUNTB=`cat $OTHERS`
    #sh $LOGGER $SCRIPT "AMOUNTB= $AMOUNTB"
    
    AMOUNT=`cat $OTHERS | sort | wc -l | grep -o -E [[:digit:]]+` #CLZ - I think this command is somewhat correct - but it was causing failing of the script - a hang.
    
#sh $LOGGER $SCRIPT "STATUSprogram trace 4 (Amount= $AMOUNT) "
fi

OLD_ifs=$IFS

#################

sh $LOGGER $SCRIPT "Starting STATUSprogram.sh with $RESname"

#### BUILD STATUS QUEUE HTML ####
projects=`ls $MOUNTFLDR`
renames=$projects              
    for prj in $projects
    do
                # Make a list of RESnames for each project
        if [ -d "$MOUNTFLDR"/"$prj"/images/lowres ];then
            renames=`printf "%s\n" $renames "$prj"Small`
        fi
    done
    
    IFS=" "
    renames=`echo $renames | sort -f`
    IFS=$OLD_ifs
    TEST=0
                # If a queue.html file exists, collect the RESnames and there associated queue amount
#sh $LOGGER $SCRIPT "Does queue file exist?"
    if [ -e queue.html ];then
        sh $LOGGER $SCRIPT "yes."
        NUMBERS=(`grep -E -o "\- [[:digit:]]+" < queue.html | grep -o -E [[:digit:]]+`)
        NAMES=`grep -E -o "[[:alpha:]]+<?/?b?>? -" < queue.html | grep -o -E [[:alpha:]]\{2,\}`
        TEST=1
    fi
    
    #sh $LOGGER $SCRIPT "Write to queue.html"
    
                # Generate a clean queue.html file.  This remove zombie processes (bold RESnames) and queue amounts
    echo '<html><body><small><pre>' > queue.html
    echo 'Active GigaPan <b>stitching</b> & queue:' >> queue.html
    printf "\t%s - 0\n" $renames >> queue.html
    echo ------------------- >> queue.html
    echo "Currently Stitching 0 gigapans:" >> queue.html
    echo '      |->' >> queue.html
    echo ------------------- >> queue.html
    echo Page Updated: `date` >> queue.html
    echo '</small></pre></html></body>' >> queue.html
    
    i=0
                # Replace the collected RESnames and queue NUMBERS from the replaced queue.html
                # The $TEST protects the process occuring if the queue.html gets deleted
    #sh $LOGGER $SCRIPT "Prepare to replace values in queue.html"
    if [ $TEST -eq 1 ];then
#sh $LOGGER $SCRIPT "Replace values in queue.html"
        for each in $NAMES
        do
            sed "s|$each - [0-9]*|$each - ${NUMBERS[$i]}|" < queue.html > queuetmp.html
            i=`expr $i + 1`
        mv queuetmp.html queue.html
    done
    fi
    
                #Upate the status of the currently stitching project (RESname)
#sh $LOGGER $SCRIPT "update queuetmp.html"
sed "s|$RESname - [0-9]*|$RESname - `expr $AMOUNT - $COUNT`|" < queue.html > queuetmp.html
#sh $LOGGER $SCRIPT "1"
                # Find the title of the other image sets being stitched
TITLES=`ps -u "$STITCHING_USER" | grep -E -o "title [[:alpha:]]+[[:digit:]_]+ " | grep -E -o "[[:alpha:]]+[[:digit:]_]+"`

if [ $UNITS = 0 ];then
    CURRENT="NO TITLES"
fi

sed "s|Currently Stitching [0-9]* gigapans:|Currently Stitching $UNITS gigapans:|" < queuetmp.html > queuetmp2.html
rm -f queuetmp.html

sed "s+|->+|-> $CURRENT $TITLES+" < queuetmp2.html > queuetmp3.html

                # Print the date and time (with the time zone) of update

sed "s|^Page Update.*$|`date "+Page Update: %c %Z"`|" < queuetmp3.html > queue.html
rm -f queuetmp3.html


                # Find the RESnames of currently stitching image sets and bold there names
PROCESSING=`ps -u "$STITCHING_USER" | grep -E -o "title [[:alpha:]]+" | grep -E -o "[[:alpha:]]+$"`


for pro in $PROCESSING
do
    sed "s|$pro |<b>$pro</b> |" < queue.html > queuetmp.html
    mv queuetmp.html queue.html
done


                # Bold the RESname of the current image set
if [ "$ONOFF" == yes ]; then
    sed "s|$RESname |<b>$RESname</b> |" < queue.html > queuetmp.html
    mv queuetmp.html queue.html
fi

#sh $LOGGER $SCRIPT "Copy queue.html to server."

sh $GIGAVISION/upload_queue.sh

#sh $LOGGER $SCRIPT "Finished STATUSprogram.sh with $RESname"
