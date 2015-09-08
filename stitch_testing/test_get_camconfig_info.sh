#!/bin/sh

# Call test_get_camconfig_info.sh - Demonstrates how to extract rows and columns from CamConfig file for a specific project and date.
#COLSROWS=`php get_camconfig_info.php -p BigBlowoutEast -f fullres -d 2010_03_22_12`
COLSROWS=`php get_camconfig_info.php -p MeteoSLC -f fullres -d 2010_09_30_12`

#echo rows and columns: $COLSROWS

OLD_ifs=$IFS
IFS=","
A_COLS_ROWS=($COLSROWS)
COLS=${A_COLS_ROWS[0]}
ROWS=${A_COLS_ROWS[1]}
TILEMASTER=${A_COLS_ROWS[2]}
echo rows : $ROWS
echo cols : $COLS
echo tilemaster : $TILEMASTER

IFS=$OLD_ifs

#Now test building mastergiga
MOUNTFLDR="mount"
PROJECT="prj"
RES="res"
RESname="resname"

IFS="_"
A_M=($TILEMASTER)
MYEAR=${A_M[0]}
MMONTH=${A_M[1]}
MDAY=${A_M[2]}
MHOUR=${A_M[3]}
IFS=$OLD_ifs


mastergiga="$MOUNTFLDR"/"$PROJECT"/images/"$RES"_timestitch/"$MYEAR"/"$MYEAR"_"$MMONTH"/"$MYEAR"_"$MMONTH"_"$MDAY"/"$RESname"_"$MYEAR"_"$MMONTH"_"$MDAY"_"$MHOUR".gigapan
echo "master: $mastergiga"
