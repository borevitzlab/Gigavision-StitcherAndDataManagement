#!/bin/sh
#############################################################
# File: 	upload_queue.sh
# Author: 	Christopher Zimmermann
# Date: 	October 15, 2010
#	
# Function: Upload the queue file to the web server.

#LOAD Global Configuration
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$DIR"/../shared/config.ini

SCRIPT="upload_queue.sh"

#echo "Starting upload_queue.sh "

#sh $LOGGER $SCRIPT "Starting upload_queue.sh "
cd /

PATH=$PATH:/sbin
export PATH

####### Variables that need to be changed for custom stitching ###########


if [ "$DO_DRIVEMOUNT_QUEUE" == "yes" ];then
    if [ ! -d $QUEUE_FLDR ];then
        mkdir $QUEUE_FLDR
    fi
    ##mount_smbfs -f 775 -o nobrowse //$USER:$PASS@eeg/"$USER"/gigavision/projects "$MOUNTFLDR"
    mount_smbfs -f 775 -o nobrowse //$USER:$PASS@gigavision/gvadmin "$QUEUE_FLDR"
fi


cd "$TMP_FLDR" ### Working directory for temporary files ###


# Here is the copy
cp -f queue.html "$QUEUE_FLDR"/queue.html

if [ "$DO_DRIVEMOUNT_QUEUE" == "yes" ];then
    umount $QUEUE_FLDR
    rmdir $QUEUE_FLDR
fi

#sh $LOGGER $SCRIPT "Finished upload_queue.sh "