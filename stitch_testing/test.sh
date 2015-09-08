#!/bin/sh
#############################################################

RESname="BBE"
IMAGELIST=`echo "$RESname"_imagelist_"$$".txt`
IMAGELIST2="$RESname"_imagelist_"$$".txt
echo imagelist= $IMAGELIST
echo imagelist2= $IMAGELIST2

sh $LOGGER $SCRIPT "/Applications/GigaPan\ 1.1.1191/GigaPan\ Stitch\ 1.1.1191.app/Contents/MacOS/GigaPan\ Stitch\ 1.1.1191 --batch-mode --align-quit --title $title --image-list $IMAGELIST --rowfirst --downward --rightward --nrows $col --save-as $savegiga $MASTERPHRASE"
                
