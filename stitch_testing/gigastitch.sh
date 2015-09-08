#!/bin/bash

LOCALPATH="/Users/topher/Documents/gigavision_website/projects/BigBlowoutEast/images/lowres/2010_07_01_12/"
RESname="BigBlowoutEastSmall"
IMAGELIST="$LOCALPATH"../"$RESname"_imagelist_$$.txt
echo "ImageList: $IMAGELIST"
ls $LOCALPATH/*[0-9].jpg > $IMAGELIST
COLS=19
title="keyframe"
#imagelist="/Users/topher/Documents/TimeGraph/scripts/gigastitch_imagelist2.txt"

savegiga="/Users/topher/Documents/gigavision_website/projects/BigBlowoutEast/images/lowres/keyframe_output.gigapan"

#mastergiga="/Users/topher/Documents/gigavision_website/projects/BigBlowoutEast/images/lowres/test2.gigapan"
/Applications/GigaPan\ 1.1.1191/GigaPan\ Stitch\ 1.1.1191.app/Contents/MacOS/GigaPan\ Stitch\ 1.1.1191 --batch-mode --align-quit --title $title --image-list $IMAGELIST --rowfirst --downward --rightward --nrows $COLS 



#/Applications/GigaPan\ 1.1.1191/GigaPan\ Stitch\ 1.1.1191.app/Contents/MacOS/GigaPan\ Stitch\ 1.1.1191 --batch-mode --align-quit --title $title --image-list $imagelist --rowfirst --downward --rightward --nrows $COLS --master $mastergiga



#/Applications/GigaPan\ 1.1.1191/GigaPan\ Stitch\ 1.1.1191.app/Contents/MacOS/GigaPan\ Stitch\ 1.1.1191 --batch-mode --align-quit --title $title --image-list $imagelist --rowfirst --downward --rightward --nrows $COLS $savegiga


  