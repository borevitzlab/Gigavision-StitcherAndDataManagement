#! /bin/sh

#LOAD Global Configuration
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$DIR"/../shared/config.ini

SCRIPT="GIGADBProgram.sh"

#### Setting of Environmental Vairables from Inputs ####
PROJECTFLDR=$1
MOUNTFLDR=$2
prj=$3
resolution=$4
manual=$5
gigapan=$6

sh $LOGGER $SCRIPT "Starting GIGADBprogram.sh with $project $resolution"


cd "$TMP_FLDR" ### Working directory for temporary files ###

########################

GIGADB=""$MOUNTFLDR"/"$prj"/databases/db_"$prj"_"$resolution"_gigapans.csv"
if [ ! -e "$GIGADB" ];then
    echo TMPHEADER > $GIGADB
fi

IMGDB=""$MOUNTFLDR"/"$prj"/databases/db_"$prj"_"$resolution"_images.csv"
if [ ! -e "$IMGDB" ];then
    echo TMPHEADER > $IMGDB
fi

######################################

if [ $manual == yes ]; then
    sh $LOGGER $SCRIPT "Searching for all .gigapan files in $prj/images/$resolution.  This will take a long time. Don't watch the pot boil."
    TODO=`find $MOUNTFLDR/$prj/images/$resolution -name '*.gigapan' -maxdepth 4 | sort -f`
else
    TODO=$gigapan
fi

for savegiga in $TODO
do
qualityCON=
title=`echo $savegiga | grep -o -E [[:alpha:]]+_2[[:digit:]]\{3\}_[0-9][0-9]_[0-9][0-9]_[0-9][0-9]`
FLDR=`echo $savegiga | grep -o -E 2[[:digit:]]\{3\}_[0-9][0-9]_[0-9][0-9]_[0-9][0-9]`

if [ -e "$savegiga" ];then
FINISH=`grep "Total time" $savegiga`
    if [ -z "$FINISH" ]; then
	
		# Dont save to Database.
		
        stitched="Cancellation"
        qualityCON="$title cancelled before stitching completed."
    else
        pixrad=`grep "pixels_per_radian" $savegiga | grep -o -E [[:digit:]]+.[[:digit:]]+`
        if [ 10002 == "$pixrad" ];then
		
			# Dont save to Database.
			
            stitched="PixPerRad Error"
            qualityCON="$title has Pixel Per Radian error. Check images in $prj $resolution folder $FLDR."
        else
            if [ ! $pixrad  ] ; then
                pixrad=NA
            fi
    
            stitched="stitched"
            imgcount=`grep "^Input.*" $savegiga | grep -o -E ": [[:digit:]]+ " | grep -o -E [[:digit:]]+`
    
            if [ ! $imgcount  ] ; then
                imgcount=NA
            fi
            
            if [ "$DO_DRIVEMOUNT" == "yes" ];then
                abspath=`echo $savegiga | sed "s|"$MOUNTFLDR"|"$PROJECTFLDR"|"`
                
            else
                abspath=`echo $savegiga`
            fi
echo "abspath $abspath"
flashpath=`echo $savegiga | sed "s|"$MOUNTFLDR"|<image path=\"$PROJECTFLDR_URL|" | sed "s:gigapan$:data\"/>:"`
	
			# Extracting info from Gigapan file
			
            cols=`grep "^Input.*" $savegiga | grep -o -E "[[:digit:]]+ columns" | grep -E -o [[:digit:]]+`
            if [ ! $cols  ] ; then
                cols=NA
            fi
    
            row=`grep "^Input.*" $savegiga | grep -o -E "[[:digit:]]+ rows" | grep -E -o [[:digit:]]+`
            if [ ! $row ] ; then
                row=NA
            fi
        
            height=`grep "Panorama size:" $savegiga | grep -o -E "[[:digit:]]+ pixels" | grep -o -E [[:digit:]]+`
            if [ ! $height  ] ; then
                height=NA
            fi
    
            width=`grep "Panorama size:" $savegiga | grep -o -E "\([[:digit:]]+" | grep -o -E [[:digit:]]+`
            if [ ! $width  ] ; then
                width=NA
            fi

            HOVER=`grep "Horizontal overlap:" $savegiga | grep -o -E "[[:digit:]]+\.[[:digit:]]+ to [[:digit:]]+\.[[:digit:]]+" | sed s/" to "/-/`
            if [ ! $HOVER  ] ; then
                hoverupper=NA
                hoverlower=NA
            else
                hoverupper=`echo $HOVER | grep -o -E "[[:digit:]]+\.[[:digit:]]+$"`
                hoverlower=`echo $HOVER | grep -o -E "^[[:digit:]]+\.[[:digit:]]+"`
            fi

            VOVER=`grep "Vertical overlap:" $savegiga | grep -o -E "[[:digit:]]+\.[[:digit:]]+ to [[:digit:]]+\.[[:digit:]]+" | sed s/" to "/-/`
            if [ ! $VOVER  ] ; then
                voverupper=NA
                voverlower=NA
            else
                voverupper=`echo $VOVER | grep -o -E "[[:digit:]]+\.[[:digit:]]+$"`
                voverlower=`echo $VOVER | grep -o -E "^[[:digit:]]+\.[[:digit:]]+"`
            fi

            quality=1
	
	
			# Now insert the collected data into the GIGA DB.
	
            ##################################
            #### HEADER TERMS FOR GIGA DB ####
            GIGAHEADER='$title,$abspath,$flashpath,$imgcount,$cols,$row,$height,$width,$pixrad,$hoverlower,$hoverupper,$voverlower,$voverupper,$quality,$hide'
            
            if [ "$manual" != yes ];then
                echo "|--------- title: $title"
                echo "|------- abspath: $abspath"
                echo "|----- flashpath: $flashpath"
                echo "|-------imgcount: $imgcount"
                echo "|--- STITCH DIMS: $cols by $row"
                echo "|------ PIX DIMS: $width by $height"
                echo "|-------- pixrad: $pixrad"
                echo "|-- HORZ OVERLAP: $hoverlower to $hoverupper"
                echo "|-- VORZ OVERLAP: $voverlower to $voverupper"
            fi
            ##################################
            
            FINDER=`grep -m 1 "^$title" $GIGADB`
            OPENHEADER=`eval echo $GIGAHEADER`
            sh $GIGAVISION/UPDATEprogram.sh $prj $resolution $GIGADB "$GIGAHEADER" "$OPENHEADER" $title "$FINDER"
            
        fi ## [ 10002 == "$pixrad" ] ##
    fi ## [ -z "$FINISH" ] ##
else
    stitched="Cancellation"
    qualityCON="$title cancelled without generating .gigapan. Check amount of images in "$prj": "$resolution": "$FLDR" and number of columns used."

fi ######## [ -e $savegiga ] ############



# Send out emails if we have a problem with the quality.
if [ "$qualityCON" ]; then
    echo "`if [ "$manual" == yes ]; then echo '[ RE-build ] '; fi``date` ->  `echo $qualityCON`" >> "$MOUNTFLDR"/"$prj"/databases/db_"$prj"_"$resolution"_quality.txt
    #test=`grep `eval echo $qualityCON` < db_"$prj"_"$resolution"_quality.txt`
        
        # If the operator is being and databases are being rebuilt then do not send out emails.  It get annoying  but could be useful
        # remove the number signs to reactive the email alert system below
    #if [ $manual == no ]; then
    # echo $qualityCON | mail -s "STITCHER ALERT" borevitz_cameras@lists.uchicago.edu
    #fi
    
fi

#Update the image database to set this gigapan as stitched.
if [ $manual == no ]; then
    title=`echo $title | grep -E -o 2[[:digit:]]\{3\}_[0-9][0-9]_[0-9][0-9]_[0-9][0-9]$`
    FINDER=`grep -n -m 1 "^$title" $IMGDB | grep -E -o ^[0-9]+`
    sh $GIGAVISION/UPDATEprogram.sh $prj $resolution $IMGDB "" $stitched $title "$FINDER"
fi

sh $LOGGER $SCRIPT "Finished GIGADBprogram.sh with $project $resolution"

done