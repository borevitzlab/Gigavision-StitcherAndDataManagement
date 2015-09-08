#!/bin/bash
#############################################################
# File: 	simple_stitch.sh
# Author: 	Christopher Zimmermann
# Date: 	October 18, 2010
#	
# Function: Run the stitcher on one gigapan and control the output.
#
MOUNTFLDR=/Users/admin/Gigavision/projects

LOCALPATH="$MOUNTFLDR"/BigBlowoutEast/images/fullres/2010/2010_09/2010_09_28/2010_09_28_12
#LOCALPATH="$MOUNTFLDR"/BigBlowoutEast/images/fullres/2010/2010_07/2010_07_01/2010_07_01_12
TMP=/Users/admin/Gigavision/tmp

#RESname="BigBlowoutEastSmall"
RESname="BigBlowoutEast"


# CREATE THE IMAGELIST FILE.
IMAGELIST="$TMP"/"$RESname"_timestitch_imagelist_$$.txt
echo "ImageList: $IMAGELIST"
ls $LOCALPATH/*[0-9].jpg > $IMAGELIST
COLS=19
title="BigBlowoutEast_2010_09_28_12"

#savegiga="$MOUNTFLDR"/BigBlowoutEast/images/lowres_test/BigBlowoutEastSmall_2010_08_03_12.gigapan
#savegiga="$MOUNTFLDR"//BigBlowoutEast/images/fullres_timestitch/2010/2010_07/2010_07_01/2010_07_01_12.gigapan
savegiga="$MOUNTFLDR"//BigBlowoutEast/images/fullres_timestitch/2010/2010_09/2010_09_28/2010_09_28_12.gigapan
echo "savegiga: $savegiga"
mastergiga="$MOUNTFLDR"/BigBlowoutEast/images/fullres_timestitch/2010/2010_09/2010_09_27/2010_09_27_12.gigapan
echo "mastergiga: $mastergiga"
# TIME STITCH
/Applications/GigaPan\ 1.1.1191/GigaPan\ Stitch\ 1.1.1191.app/Contents/MacOS/GigaPan\ Stitch\ 1.1.1191 --batch-mode --align-quit --title $title --image-list $IMAGELIST --rowfirst --downward --rightward --nrows $COLS --save-as $savegiga  --master $mastergiga

# NORMAL STITCH
#/Applications/GigaPan\ 1.1.1191/GigaPan\ Stitch\ 1.1.1191.app/Contents/MacOS/GigaPan\ Stitch\ 1.1.1191 --batch-mode --align-quit --title $title --image-list $IMAGELIST --rowfirst --downward --rightward --nrows $COLS --save-as $savegiga  



#/Applications/GigaPan\ 1.1.1191/GigaPan\ Stitch\ 1.1.1191.app/Contents/MacOS/GigaPan\ Stitch\ 1.1.1191 --batch-mode --align-quit --title $title --image-list $imagelist --rowfirst --downward --rightward --nrows $COLS --master $mastergiga



#/Applications/GigaPan\ 1.1.1191/GigaPan\ Stitch\ 1.1.1191.app/Contents/MacOS/GigaPan\ Stitch\ 1.1.1191 --batch-mode --align-quit --title $title --image-list $imagelist --rowfirst --downward --rightward --nrows $COLS $savegiga
