#!/bin/sh
#############################################################
# File: 	logger.sh
# Author: 	Christopher Zimmermann
# Date: 	October 15, 2010
#	
# Function: Creates a log for the stitching process.

#LOGFLDR=/Gigavision/logs

#LOAD Global Configuration
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$DIR"/../shared/config.ini

echo $1 --- $2 >> "$LOGFLDR"/autostitch_log.txt
echo $1 --- $2