#!/bin/bash
#############################################################
# File: 	simple_stitch.sh
# Author: 	Christopher Zimmermann
# Date: 	October 18, "$YEAR"
#	
# Function: Run the stitcher on one gigapan and control the output.
#

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$DIR"/../shared/config.ini



RESname="BigBlowoutEast"
PROJECT="BigBlowoutEast"

RES=fullres
#YEAR=2010
#MONTH=07
#DAY=01
#HOUR=12
#YEAR=2009
#MONTH=09
#DAY=26
#HOUR=12

YEAR=2010
MONTH=09
DAY=30
HOUR=12
COLS=19

#YEAR=2009
#MONTH=11
#DAY=25
#HOUR=12
#COLS=22

#master
MYEAR=2010
MMONTH=07
MDAY=01
MHOUR=12


LOCALPATH="$MOUNTFLDR"/"$PROJECT"/images/"$RES"/"$YEAR"/"$YEAR"_"$MONTH"/"$YEAR"_"$MONTH"_"$DAY"/"$YEAR"_"$MONTH"_"$DAY"_"$HOUR"

# CREATE THE IMAGELIST FILE.
IMAGELIST="$TMP_FLDR"/"$RESname"_imagelist_$$.txt
echo "ImageList: $IMAGELIST"
ls $LOCALPATH/*[0-9].jpg > $IMAGELIST

title="$PROJECT"_"$YEAR"_"$MONTH"_"$DAY"_"$HOUR"
echo "title: $title"
#savegiga="$MOUNTFLDR"//"$PROJECT"/images/"$RES"_timestitch/"$YEAR"/"$YEAR"_"$MONTH"/"$YEAR"_"$MONTH"_"$DAY"/"$RESname"_"$YEAR"_"$MONTH"_"$DAY"_"$HOUR".gigapan
savegiga="$MOUNTFLDR"/"$PROJECT"/images/"$RES"/"$YEAR"/"$YEAR"_"$MONTH"/"$YEAR"_"$MONTH"_"$DAY"/"$RESname"_"$YEAR"_"$MONTH"_"$DAY"_"$HOUR".gigapan
echo "savegiga: $savegiga"
#mastergiga="$MOUNTFLDR"/"$PROJECT"/images/"$RES"_timestitch/"$MYEAR"/"$MYEAR"_"$MMONTH"/"$MYEAR"_"$MMONTH"_"$MDAY"/"$RESname"_"$MYEAR"_"$MMONTH"_"$MDAY"_"$MHOUR".gigapan
mastergiga="$MOUNTFLDR"/"$PROJECT"/images/"$RES"/"$MYEAR"/"$MYEAR"_"$MMONTH"/"$MYEAR"_"$MMONTH"_"$MDAY"/"$RESname"_"$MYEAR"_"$MMONTH"_"$MDAY"_"$MHOUR".gigapan
#echo "master: $mastergiga"

## TIME STITCH
CMD_TO_RUN="$STITCHER_PATH --batch-mode --align-quit --title $title --image-list $IMAGELIST --rowfirst --downward --rightward --nrows $COLS --save-as $savegiga  --master $mastergiga "

# NORMAL STITCH
#CMD_TO_RUN="$STITCHER_PATH --batch-mode --align-quit --title $title --image-list $IMAGELIST --rowfirst --downward --rightward --nrows $COLS --save-as $savegiga "

eval "$CMD_TO_RUN"