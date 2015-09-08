#!/bin/sh
#############################################################
# File: 	IMGDBprogram.sh
# Author: 	Whitney Panneton
# Date: 	August 20, 2010
#
# Function: To update the last two month or the entire image database of the designated project and resolution
#
# Operations: Generate a RESname given the input resolution type and project name
#             If called by the Operator (manual = yes), then make IMGFLDRS the complete path to the resolution folder (fullres or lowres)
#             Otherwise IMGFLDRS is a list of two complete paths to the month folder level (ex. /web/gigavision/projects/MeteoSLC/images/fullres/2010/2010_08)
#             
#

#LOAD Global Configuration
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$DIR"/../shared/config.ini


SCRIPT="IMGDBProgram.sh"

#### Setting of Environmental Vairables from Inputs ####
#Example:
#  IMGDBprogram.sh /web/borevitzlab/gigavision/projects /Users/admin/Gigavision/projects FNVBackDune fullres yes

PROJECTFLDR=$1
MOUNTFLDR=$2
prj=$3
resolution=$4
manual=$5
RESname=$prj
if [ "$resolution" == lowres ]; then
    RESname="$RESname"Small
fi


cd "$TMP_FLDR" ### Working directory for temporary files ###

sh $LOGGER $SCRIPT  "Starting IMAGEDBprogram.sh with $RESname"

OLD_ifs=$IFS
###############

IMGDB=""$MOUNTFLDR"/"$prj"/databases/db_"$prj"_"$resolution"_images.csv"
if [ ! -e "$IMGDB" ];then
    echo TEMPHEADER > $IMGDB
fi

    # Determine Start Direcgtory
######################################

if [ "$manual" == yes ]; then
    IMG_DIR=$MOUNTFLDR/$prj/images/$resolution
else
        
    YESTYEAR=`date -v-1m +%Y` # The year, 1 month ago.
    YESTYEAR=2010 # The year, 1 month ago.
    YESTMONTH=01 #`date -v-1m +%m` # The month, 1 month ago.
    TOYEAR=`date +%Y`			# The current year.
    TOMONTH=`date +%m`			# The current month.

	# IMG_DIR is a list of two directories, The image dir from last month - and the image dir from this month.
        # E.x. IMG_DIR="/Users/admin/Gigavision/projects/MeteoSLC/images/fullres/2010/2010_08 /Users/admin/Gigavision/projects/MeteoSLC/images/fullres/2010/2010_09"
    IMG_DIR="$MOUNTFLDR/$prj/images/$resolution/$YESTYEAR/$YESTYEAR"_"$YESTMONTH $MOUNTFLDR/$prj/images/$resolution/$TOYEAR/$TOYEAR"_"$TOMONTH"
fi



UPDATEMEM=0   ###### QUICK MEMORY TO SEE IF THE DATABASE WAS UPDATED #####
#################### Section 4 ##########################
    #Loop through img_dir's
for update in $IMG_DIR
do
    if [ -d "$update" ]; then #If it is a directory.
	
		# Find all hour directories.
		# Explicitly: Search and put in IMGFLDRS list all items that match the pattern: XXXX_XX_XX_XX where X are numbers.
		
		# The difference between these two options is the depth (maxdepth changes) for each search.  This is to save processing time.
        if [ "$manual" == yes ]; then
            sh $LOGGER $SCRIPT   "Searching for all image folders in $prj -> $resolution. This will take awhile. Go do something else."
            IMGFLDRS=`find $update -type d -regex "^.*[0-9]\{4\}_[0-9]\{2\}_[0-9]\{2\}_[0-9]\{2\}$" -maxdepth 5 | sort`
        else
            sh $LOGGER $SCRIPT   "Searching for image folders in $prj -> $resolution -> `basename $update`. This will take a few minutes."
            IMGFLDRS=`find $update -type d -regex "^.*[0-9]\{4\}_[0-9]\{2\}_[0-9]\{2\}_[0-9]\{2\}$" -maxdepth 3 | sort`
        fi
		
                # Looping through many image folders. "2010_08_01_12" for example.
                # Scan data in each folder (including if gigapan file exists) and write a summary up about it.
        for fldr in $IMGFLDRS
        do
            name=`basename $fldr` 	# Everything after last /
            PARENT=`dirname $fldr`	# Everything before last / 
            savegiga=$PARENT/"$RESname"_$name.gigapan

            if [ "$DO_DRIVEMOUNT" == "yes" ];then
                abspath=`echo $fldr | sed "s|"$MOUNTFLDR"|"$PROJECTFLDR"|"`
            else
                abspath=`echo $fldr`
            fi

            echo "abspath $abspath"
			# Count the number of image files. All files that match (something like) SomeLetters_XX_XX_XX_XXXX.jpg
            imgcount=`ls $fldr/ | grep -E [[:alpha:]]+_2[[:digit:]]\{3\}_[0-9][0-9]_[0-9][0-9]_.+_[[:digit:]]\{4\}.jpg$ | wc -l | grep -o -E [[:digit:]]+`
                        # Count the number of non-image files - things that did not match the above pattern.
            noncount=`ls $fldr/ | grep -v -E [[:alpha:]]+_2[[:digit:]]\{3\}_[0-9][0-9]_[0-9][0-9]_.+_[[:digit:]]\{4\}.jpg$ | wc -l | grep -o -E [[:digit:]]+`
            cols=       # Set and reset the value of the col variable from last image folder
            imginfo=NO  # Set and reset the value of imginfo variable from last image folder
			
			# Get number of Columns and Rows.
			# First try to read an _imageinfo.txt file if it is there, otherwise use default values.
			
            if [ -e $fldr/"$prj"_imageinfo.txt ]; then
                cols=`grep "Columns" $fldr/"$prj"_imageinfo.txt | grep -E -o [[:digit:]]+`
                row=`grep "Rows" $fldr/"$prj"_imageinfo.txt | grep -E -o [[:digit:]]+`
                #captured=`grep "Captured" $fldr/"$prj"_imageinfo.txt | grep -E -o [[:digit:]]+`
                imginfo=YES
            else
			# No imageinfo.txt file detected...
		
                
                #CLZ
                #Call php file to extract proper rows and cols given project name, resolution and date string.
                #result = php GetColsAndRowsFromCamConfig.php $prj $resolution $name
                #COLSROWS=`php GetColsAndRowsFromCamConfig.php --p BigBlowoutEast --f fullres --d 2010_03_22_12`
                sh $LOGGER $SCRIPT   "Call: php "$GIGAVISION"/get_camconfig_info.php -p $prj -f $resolution -d $name"
            
                COLSROWS=`php "$GIGAVISION"/get_camconfig_info.php -p $prj -f $resolution -d $name`

                sh $LOGGER $SCRIPT   "Result: $COLSROWS"
                #echo rows and columns: $COLSROWS
                OLD_ifs=$IFS
                IFS=","
                A_COLS_ROWS=($COLSROWS)
                cols=${A_COLS_ROWS[0]}
                row=${A_COLS_ROWS[1]}              
                #echo rows : $row
                #echo cols : $cols             
                IFS=$OLD_ifs
                          
                        
                #### IF PARTIAL IMAGE UPLOAD AND NO imageinfo.txt FILE ####
                if [ ! "$cols" ]; then
                    cols=NA
                    row=NA
                    #echo "a"
                fi
                #if empty - also set to NA
                if [ ! -n "$cols" ]; then
                    cols=NA
                    row=NA
                    #echo "b"
                fi
            fi  ### closing [ -e $dir/$RESname_imageinfo.txt ] ######
                   
             #echo final rows : $row
             #   echo final cols : $cols
                
            ###### NOTES SECTION #######
			
			# This attempts to evaluate how well the images were captured,
			# and writes the results into the notes column.
			
            if [ $imgcount -gt 1 ]; then
			
			# 'title' is captured to assess quality by matching it with other data. (??? Looks for first instance of an image. )
			# 'title' should look like BigBlowoutEast_XXXX_XX_XX_XX
                title=`ls $fldr/ | grep -m 1 -E -o [[:alpha:]]+_[[:digit:]]\{4\}_[[:digit:]]\{2\}_[[:digit:]]\{2\}_[[:digit:]]\{2\}`
                if [ -z "$title" ]; then
			# Did not match the pattern.
                    notes="Wrong Image names"
                else
			# 'SYSCHECK' looks like BigBlowoutEast_XXXX_XX_XX_XX
                        # This is a check to see if the RESname on the image files is the same as the directory it is in
                    SYSCHECK=$RESname"_"$name
                    if [ $SYSCHECK == $title ]; then
                        notes="Good"
                    else
                        notes="Image System name and date do not match Folder"
                    fi
                fi
            else
                notes="One or fewer Stitchable Images"
            fi
                    
                    
                    
            ############################
        
            # Have these images already been stitched? (By checking if the .gigapan file already exists.)
            # Yes this means that the images have been stitched (even if it is a bad gigapan).
            # A bad gigapan implies one that was interupted or has a pixrad error

                        #   if the savegiga file exists...then
            if [ -f "$savegiga" ]; then
            
            
                        # Check to see if the .gigapan file is actually a completed fiel
                        # If connect is interupted or the computer is shutdown the file with not have thie Total time stamp
                        
                        # What is the quality of the stitching. - Did it stitch?
                        # Sets 'pixrad', 'notes' and 'stitched' column.  
                FINISH=`grep "Total time" $savegiga`
                if [ ! -z "$FINISH" ]; then
          
                    pixrad=`grep "pixels_per_radian" $savegiga | grep -o -E [[:digit:]]+.[[:digit:]]+`
                    if [ 10002 == "$pixrad" ];then
                        stitched="PixPerRad Error"
                        notes="Not actual Pano"
                    else
                        # Success !
                        stitched="stitched"
                    fi			
			  
                else
                        #There is no 'Total Time' - stitching failed somehow.
                        #This means that stitching will not be attempted again. You would need to delete the .gigapan file to attempt a restitch.
                    stitched="Stitch Failed/Cancelled"
                    notes="Not actual Pano"      
                fi             
                
            else
                #No gigapan file
                stitched=N
            fi

			# Set 'compset' column. Check if we got the correct number of images and rows - and set 'compset' column.
                        # This is a check to make sure it image set makes a complete gigapan
			
            if [ "$cols" == NA ]; then
                compset=NA
            else
                if [ $imgcount -eq `expr $row \* $cols` ]; then
                    compset="Full"
                else
                    compset="Partial"
                fi
                sh $LOGGER $SCRIPT   "ImgCount Result: $compset ,rows: $row ,cols: $cols"
            fi
                    
					
					
			#### Now add all the collected data about the image folder into a row.		
					
            ##########################################
            ### HEADER AND LINE INPUT FOR IMAGE DB ###
            IMGHEADER='$name,$abspath,$imgcount,$cols,$row,$compset,$noncount,$imginfo,$stitched,$notes'
            ##########################################

			# 'FINDER' is there a row with this name already in the existing Image Database??
            FINDER=`grep -m 1 "^$name" $IMGDB`
            if [ "$FINDER" != "`eval echo $IMGHEADER`" ];then
				# If 'FINDER' matches the current IMGHEADER row, Mark that we are going to update that row.
                UPDATEMEM=`expr $UPDATEMEM + 1`
            fi
            
			# Now put it in the database. Use the UPDATEprogram.sh script.
            OPENHEADER=`eval echo $IMGHEADER`
            sh $GIGAVISION/UPDATEprogram.sh $prj $resolution $IMGDB "$IMGHEADER" "$OPENHEADER" $name "$FINDER"
        done ## Closeing fldr ##
		
        
    else
        sh $LOGGER $SCRIPT   "No updates to "$prj"_"$resolution" -> `basename $update` "
    fi ### Closing [ -d "$update" ] ###
done ### Closing update ###
if [ $UPDATEMEM -eq 0 ]; then
            sh $LOGGER $SCRIPT   "No updates to "$prj"_$resolution image database for the last 2 months"
else
sh $LOGGER $SCRIPT   Finished "$prj"_$resolution database updates
fi

sh $LOGGER $SCRIPT  "Finished IMGDBprogram.sh with $RESname"
