#!/bin/sh
#############################################################
# File: 	UPDATEprogram.sh
# Author: 	Whitney Panneton
# Date: 	September 2, 2010
#	
# Function: Opens either the image or gigapan database and replaces the row or updates thems
#           The updates occur when new images are uploaded to old image sets or a gigapan is finished
#           The entire row of the image databases is replaced when the image cou
#
# Called By: IMGDBprogram.sh or GIGADBprogram.sh
# Calls: 		DBSORTprogram.sh, HTMLprogram.sh
#
# Important Environment Variables: ???
#
#############################################################

#LOAD Global Configuration
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$DIR"/../shared/config.ini

SCRIPT="UPDATEProgram.sh"

#### SETTING INPUT VARIABLES ####

prj=$1 # Project name (ie. BigBlowoutEast)
resolution=$2 # Image resolution (ie. lowres)
DB=$3 # Local path to the desinated database (ie. /Users/admin/Gigavision/projects/MeteoSLC/databases/db_MeteoSLC_images_fullres.csv)
DBHEADER=$4 # The database header which is the column names (ie. $name,$abspath,$imgcount,$cols,$row,$compset,$noncount,$imginfo,$stitched,$notes)
OPENHEADER=$5 # The values for that row (ie. 2010_05_13_06,/web/gigavision/projects/MeteoSLC/images/fullres/2010/2010_05/2010_05_13/2010_05_13_06,258,43,6,Full,0,NO,stitched,Good)
title=$6 # The image dir name (ie. 2010_08_20_12)
FINDER=$7 # The old data in the database if it exist for that title

#IT gets called so often - dont need to trace it. sh $LOGGER $SCRIPT "Starting UPDATEprogram.sh with $prj $resolution"

cd "$TMP_FLDR" ### Working directory for temporary files ###

echo "cd step"


############ START PROGRAM #################################

#echo "UpDATEprogram.sh on $DB"
#echo ""

if [ "$FINDER" != "$OPENHEADER" ]; then # If the FINDER (old data) is not eqaul to the OPENHEADER (new data) then...

    DBTYPE=`echo $DB | grep -o -E [[:alpha:]]+[.] | grep -o -E [[:alpha:]]+` # Set the type of database that is being updated (ie. image).  This is only used for disply purposes.

    if [ -z "$FINDER" ]; then # If FINDER is empty (-z) variable then...
        sh $LOGGER $SCRIPT "Added $title to "$prj"_$resolution $DBTYPE database" 
        echo "Added $title to "$prj"_$resolution $DBTYPE database" 

        echo $OPENHEADER >> $DB # Catinate OPENHEADER (new data) to the end of the database therefore no information is replace here
    else
        number=`echo $FINDER | grep -o ^[0-9]*$` # The line number of the FINDER, which is the row in database, if it was supplied.
        sh $LOGGER $SCRIPT "Finder= $FINDER Number=$number"
        if [ $number ];then # If number defined then...
            sed "$FINDER s:,N,:,$OPENHEADER,:" < $DB > DB_tmp_$$ # Replace the 
            mv DB_tmp_$$ $DB
            rm -f DB_tmp_$$
            
            echo "Update (number defined): Replace a row in the DB."
        else
            sh $LOGGER $SCRIPT "Updated $title in $prj_$resolution $DBTYPE database"
            sed "s|"^$FINDER.*$"|`echo $OPENHEADER`|g" < $DB > DB_tmp_$$
            mv DB_tmp_$$ $DB
            
            echo "Update (number not defined): Not sure what happens here!."
        fi
    fi
	
	# Now resort the database
    sh $GIGAVISION/DBSORTprogram.sh $DB "$DBHEADER"

	# Now update the HTML file.
    sh $GIGAVISION/HTMLprogram.sh $DB

fi

# Dont need to trace it.sh $LOGGER $SCRIPT "Finished UPDATEprogram.sh with $prj $resolution"
            