#!/bin/bash
title="test1"
imagelist="/Users/topher/Documents/TimeGraph/scripts/gigastitch_imagelist2.txt"
savegiga="/Users/topher/Documents/gigavision_website/projects/BigBlowoutEast/images/lowres/2010_07_01_12/test1_output.gigapan"
mastergiga="/Users/topher/Documents/gigavision_website/projects/BigBlowoutEast/images/lowres/test2.gigapan"
#/Applications/GigaPan\ 1.1.1191/GigaPan\ Stitch\ 1.1.1191.app/Contents/MacOS/GigaPan\ Stitch\ 1.1.1191 --batch-mode --align-quit --title $title --image-list $imagelist --rowfirst --downward --rightward --nrows 2 $savegiga
/Applications/GigaPan\ 1.1.1191/GigaPan\ Stitch\ 1.1.1191.app/Contents/MacOS/GigaPan\ Stitch\ 1.1.1191 --batch-mode --align-quit --title $title --image-list $imagelist --rowfirst --downward --rightward --nrows 2 --master $mastergiga

  