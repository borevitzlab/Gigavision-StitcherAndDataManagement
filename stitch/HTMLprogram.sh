#! /bin/sh
#############################################################
# File: 	STATUSprogram.sh
# Author: 	Whitney Panneton
# Date: 	August 20, 2010
#
# Function: Creates a html file of last rows of input database for display on the web
#
# Operation: Take input databse and make save file with html extension instead of csv
#            Copy the header of the database and set it to DBHEADER
#            Read the last rows of the database (origonally 20) and insert html tags for small font, center alignmnet, and table.
#            Create html file that starts with default html and table tags, then add the database header and add small font and center alignment tags.
#            Replace < and /> html tags from image path colum database with html tags for greater then (this allows them to be displayed)
#
# Called by: UPDATEprogram.sh
#
#############################################################

DB=$1
DBhtml=`echo $DB | sed "s|csv$|html|"`
if [ ! -e "$DBhtml" ];then
    echo TMPHEADER > $DBhtml
fi

DBHEADER=`head -n 1 $DB`

cd "$TMP_FLDR" ### Working directory for temporary files ###

#### ADDING HTML TAGS TO MAKE TABLE ####
tail -n 20 $DB | sed "s|,|</small></center></td><td><center><small>|g" | sed "s|^|<tr><td><center><small>|g" | sed "s|$|</small></center></tr></td>|g" > htmltemp_$$
( echo '<html><body><table border="1">' ; ( echo "$DBHEADER" | sed "s|^|<tr><td><center><small><b>|g" | sed "s|,|</b></small</center></td><td><center><small><b>|g" | sed "s|$|</b></small></center></tr></td>|g" ); cat htmltemp_$$ ; echo '</table></small></body></html>' ) > htmltemp2_$$
(cat htmltemp2_$$ | sed "s|<image path|\&lt;image<font color=\"white\">_</font>path|g" | sed "s|\"/>|\"/\&gt;|g" | sed "s|/images/|/images/<br />|g") > $DBhtml
rm -f htmltemp2_$$
rm -f htmltemp_$$

