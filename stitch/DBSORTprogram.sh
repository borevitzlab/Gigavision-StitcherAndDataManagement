#! /bin/sh
#############################################################
# File: 	STATUSprogram.sh
# Author: 	Whitney Panneton
# Date: 	September 2, 2010
#
# Function: Sorts the database alphabetically (ignoring case) and numerically
#
# Operation: If there is no predefined database header (DBHEADER), which is the column names, then generate the DBHEADER from the defined database
#            Remove the header column from the database and sort the database ignoring case
#            Generate a temporary file for the DBHEADER removing the leading $ on each name.
#            Combine or catinate the database header (the column names) and then the rest of the database.
#
# Called by: UPDATEprogram,sh
#
#############################################################

#LOAD Global Configuration
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$DIR"/../shared/config.ini

SCRIPT="DBSORTProgram.sh"

DB=$1 			# local file path to database (e.x. /Users/admin/Gigavision/projects/MeteoSLC/databases/db_MeteoSLC_lowres_images.csv) 
DBHEADER=$2		# Empty or given header of database (e.x. $name,$abspath,$imgcount,$cols,$row,$compset,$noncount,$imginfo,$stitched,$notes)

if [ ! $DBHEADER ];then # If DBHEADER variable empty then ...
    DBHEADER=`head -n 1 $DB` # grab the first line from the database which is the column names.
fi

cd "$TMP_FLDR" ### Working directory for temporary files ###

sed '1d' $DB | sort -f > db_temp_$$ # Delete the first line of the database sort each row alphabetically (ignoring case) and numberically then make temp file 
echo $DBHEADER | sed 's:\$::g' > header_temp_$$ # Read DBHEADER and then remove the leading $ on each column name and make temp file
cat header_temp_$$ db_temp_$$ > $DB # Combine the header (column names) and the sorted database and save ove the old database file

# Remove temporary files
rm -f header_temp_$$
rm -f db_temp_$$

