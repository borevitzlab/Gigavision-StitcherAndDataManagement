#!/bin/sh
#############################################################
# File: 	Autostitcher.sh
# Author: 	Whitney Panneton
# Date: 	August 20, 2010
#	
# Function: The primary script in the Automated Stitching System.  Upates all projects (each resolution as well) by
#           Makeing calles to update the image and gigapan for the last two months as well as stitching image sets wh appropriate.
#
# Operations: Mount the EEG server to the local computer.
#             Call on IMGDBprogram.sh to update the last two months of the image database
#             Remove zombie RESname_STITCHING_PID.txt files
#             Query the image databse for unstitched image sets
#             Compare current unstitched queue list with active stitching queue list
#             Generate new queue list for stitching if new unique image sets exist
#             Check the number image sets currently begin processed
#             Check if number of stitching processing units is below allocated amount
#             Call STATUSprogram.sh to update the stitching status on the local computer
#             Call GigaPan applicaiton to stitch image set if below allocated processing amount
#             Call GIGADBprogram.sh to update gigapan database if image stitched succesfully
#             Call STATUSprogram.sh to update the stitching status on the local computer
#             Unmount the EEG server if there is no other Autostitcher shells are running
#             
# Called By: 	CRON job.
# Calls: 	IMGDBprogram.sh STATUSprogram.sh GIGADBprogram.sh
#
# Important Environment Variables:
# USER - The user name for logging onto EEG
# PASS - The password associated with the USER
# PATH - Deafult varible used by shell to search for functions
# PROJECTFLDR - The complete path on EEG where projects are saved
# MOUNTFLDR - The complete path that the shell should use to mount EEG
# GIGAVISION - The complete path to the Gigavision program suite
# IFS (Internal Field Sperators) - Shell default variable used to delineate lists
# OLD_ifs - Used to store the deafult IFS before changing them.  Usefully if you want to change them back in the same shell
# RESname - The name of prj plus the resolution. For example, it could be BigBlowoutEast or BigBlowoutEastSmall depending on resolution
# prj
#############################################################

# QUESTIONS
# WHat is $ and $$ by themselves??
# $ signifies a enviromental variable and $$ is the PID (Processor ID) for the current shell.
## I used this in order to make each file unique when makeing temporary files

#################### Section 1 ##########################

# Configure variables / set directory

cd /
PASS=`head .pass2`
USER=`head .user2`

PATH=$PATH:/sbin
export PATH

####### Variables that need to be changed for custom stitching ###########
PROJECTFLDR=/web/gigavision/projects
MOUNTFLDR=/Users/admin/Gigavision/projects
GIGAVISION=/Users/admin/Gigavision/PROGRAMsuite
SCRIPTS_OFFSET_FLDR=/Users/admin/Gigavision/scripts_offset

LOGGER="/Users/admin/Gigavision/PROGRAMsuite/logger.sh"
SCRIPT="Autostitcher.sh"

#######################################################################

# Archive previous log file by renaming it
DATE=$(date +"%m_%d %H")
mv -f /Users/admin/Gigavision/logs/autostitch_log.txt /Users/admin/Gigavision/logs/autostitch_log_"$DATE".txt 
DATE=$(date +"%Y_%m_%d %H_%M_%S")
sh $LOGGER $SCRIPT "Starting Autostitcher.sh @ $DATE"

# ??? What is $IFS - an environment variable on the machine?
# IFs (Internal Field Sperators) is how the shell understands how list are seperated.


OLD_ifs=$IFS
if [ ! -d $MOUNTFLDR ];then
mkdir $MOUNTFLDR
fi
##mount_smbfs -f 775 -o nobrowse //$USER:$PASS@eeg/"$USER"/gigavision/projects "$MOUNTFLDR"
mount_smbfs -f 775 -o nobrowse //$USER:$PASS@gigavision/upload "$MOUNTFLDR"
cd "$TMP_FLDR" ### Working directory for temporary files ###



#################### Section 2 ##########################
PROJECT=`ls $MOUNTFLDR`
#PROCESS ONLY MeteoSLC
PROJECT="MeteoSLC"

for prj in $PROJECT
do
    RESname=$prj

    #################### Section 3 ##########################
    RES=`ls "$MOUNTFLDR"/"$prj"/images`
    for resolution in $RES
    do
        if [ "$resolution" == lowres ]; then
            RESname="$RESname"Small
        fi
        
        DATE=$(date +"%Y_%m_%d %H_%M_%S")
        sh $LOGGER $SCRIPT  "Starting Project/Resoution: $RESname @ $DATE."	
        ### CLZ - Add Automatic offsets here.
        sh $LOGGER $SCRIPT  "Calculating image offsets for new Gigapans."	
        if [ "$resolution" == lowres ]; then
            php $SCRIPTS_OFFSET_FLDR/offsetgenerator_auto.php -- -p $prj -f false
        else
            php $SCRIPTS_OFFSET_FLDR/offsetgenerator_auto.php -- -p $prj 
        fi
        
        sh $LOGGER $SCRIPT  "Section 3 - Scan image folders and update image database."
        
		# Update Image Database by scanning all of the image directories of the past two months 
		
        IMGDB=""$MOUNTFLDR"/"$prj"/databases/db_"$prj"_"$resolution"_images.csv"
        sh $LOGGER $SCRIPT  $IMGDB
        sh $GIGAVISION/IMGDBprogram.sh $PROJECTFLDR $MOUNTFLDR $prj $resolution no
        sh $LOGGER $SCRIPT  "IMGDBProgram.sh complete."
        #sh $GIGAVISION/OPERATORprogram.sh image $PROJECTFLDR $MOUNTFLDR $prj $resolution no 
        
		
		
        #################### Section 5 ##########################
	sh $LOGGER $SCRIPT  "Section 5 - Creating lists of images to stitch."
        
        # Update BigBlowoutEast_unstitched_.txt.
        
		# Looking in the images database (just created) to figure out which images it should stitch.
		
		
		
		# This does not kill off any currently stitching processs only updates the image database
		## This occurs becuae the stitcher loades the imagelist file, which has the image paths in it.
		
		
		# Find all rows with N and Full and Good. Put them in "BigBlowoutEast_unstitched_.txt.
                # The images are unstiched becuase N is not stiched, FULL means they have complete set of images, Good means they have the correct naming convention.
		# ??? But what are these rows? Why are they unstitched?
                # They are saved as unstitched becuase theses are imagesets that have not been stitched indicated by the database
                # however, the unstitched imagesets could be in a queue to be stitched (RESname_STITCHING.txt)
		
        (grep ",N," $IMGDB | grep "Full" | grep "Good") > "$RESname"_unstitched_$$.txt
        
        
        # Get rid of RESname_STITCHING_.txt files that are no longer being stitched.
                
		# Get a process list, Filter for Autostitcher, Filter out grep commands, and get the PID (Process ID)
                # It checks to see if other Autosticher programs are running
                # This is in place to remove zombie RESname_STITCHING.txt files
                # This had to be done for the STATUSprogram.sh which uses the STITCHING files to determine the amount in each queue.
        ps -u labadmin | grep Autostitcher | grep -v grep | grep -o -E  "[[:digit:]]+ [[:digit:]]+" | grep -o -E [[:digit:]]+$ | sort > PROCPID
        
                # This finds all of the PIDs of the files in the tmp folder
                # It then compares the currently running PIDs with all of the txt PIDs and delets the ones that are zombie files
		ls /Users/admin/Gigavision/tmp | grep -E -o "$RESname"_STITCHING_[[:digit:]]+ | grep -o -E [[:digit:]]+$ | sort > TXTPID
        TODELETE=`comm -13 PROCPID TXTPID`
        rm -f PROCPID
        rm -f TXTPID
        if [ "$TODELETE" ]; then
            for stitchpid in $TODELETE
            do
                rm -f `ls | grep $stitchpid`
            done
        fi
        
        
        
        
        
        
	# Update "$RESname"_STITCHING.txt
        
		# Find all files with the current RESname that are in a stitching queue for each running Autostitcher shell
                # Then compare the recently unstitched rows (image sets) with the ones in the queue
                # If there are new rows (image sets) that are not in a queue then start stitching them
                # They are set to the TOSTITCH vairable.
		
                # This allows the stitcher not to stitch the same image set twice
                # and it allows it to move onto other projects that are not currently being stitched
		
            OTHERS=`find /Users/admin/Gigavision/tmp -maxdepth 1 -regex "^.*"$RESname"_STITCHING.*$"`
            if [ $OTHERS ];then
				# Combine/catinate all of the STITCHING.txt files that have the same RESname
                cat $OTHERS | sort -f > Gathered_STITCHING_$$.txt
				# Compare 2 files and output the rows that only exist in "$RESname"_unstitched_$$.txt
				# IE, create "$RESname"_STITCHING_$$.txt, which holds only the rows from _unstitched that are not currently being stitched.
                comm -13 Gathered_STITCHING_$$.txt "$RESname"_unstitched_$$.txt > "$RESname"_STITCHING_$$.txt
		
				# Delete these temp files.
                rm -f Gathered_STITCHING_$$.txt
                rm -f "$RESname"_unstitched_$$.txt
            else 
                mv "$RESname"_unstitched_$$.txt "$RESname"_STITCHING_$$.txt            
            fi
            
            
            
            
            
            # Use sort to order them in reverse order so that the latest gigapans will stitch first.
            #TOSTITCH=`cat "$RESname"_STITCHING_$$.txt`
            TOSTITCH=`sort -r "$RESname"_STITCHING_$$.txt`


        #################### Section 6 ##########################
	sh $LOGGER $SCRIPT  "Section 6 - Start stitching queued items."	
		# Check stitch status, and Start stitching if appropriate.
		# Maintain and Report status.
		
		# UNITS: Number of Gigapan processes currently running.
		# List processes, Filter on Gigapan, Remove grep, count number of lines, get the value.
                # Units are set here in order to run STATUSprogram when there are no gigapans to stitch
                UNITS=`ps -u labadmin | grep GigaPan | grep -v grep | wc -l | grep -o [[:digit:]]` 
		
        if [ -z "$TOSTITCH" ]; then
			# Nothing to stitch.
            sh $LOGGER $SCRIPT  "Nothing to stitch."
            rm -f "$RESname"_STITCHING_$$.txt
            sh $LOGGER $SCRIPT  "Removed STITCHING .txt files"
            sh $LOGGER $SCRIPT  "Removed $RESname _STITCHING_ $$ .txt"
        else
            sh $LOGGER $SCRIPT  "Prepare to stitch."
            
            LISTS=`find /Users/admin/Gigavision/tmp -maxdepth 1 -regex "^.*"$RESname"_imagelist.*$"`
            rm -f $LISTS
	    sh $LOGGER $SCRIPT  "Removed temp files."	
                        
            IFS=" "
			# AMOUNT: Actual number of gigapans to be stitched.
            AMOUNT=`echo $TOSTITCH | wc -l | grep -o -E [[:digit:]]+`
            
            sh $LOGGER $SCRIPT  "AMOUNT $AMOUNT"
            
            IFS=$OLD_ifs
            COUNT=1  ### Used to count how many gigapans have been completed ###
            
            sh $LOGGER $SCRIPT  Images that are going to be stitched:
            IFS=" "
            sh $LOGGER $SCRIPT  $TOSTITCH
            IFS=$OLD_ifs
            sh $LOGGER $SCRIPT  ----------------
                
                
            sh $LOGGER $SCRIPT  "Calling STATUSprogram.sh after evaluating what to stitch."
            sh $GIGAVISION/STATUSprogram.sh $MOUNTFLDR $RESname 0 $UNITS no
            sh $LOGGER $SCRIPT  "Back from STATUSprogram.sh"
        fi
        
        done ### Closing resolution ###
    rm -f "$RESname"_STITCHING_$$.txt
done  ### Closing prj ###








############### Perform RoundRobin Stitching - stitch one instance from each project. ##############

if [ false ]; then
for prj in $PROJECT
do
    RESname=$prj

    #################### Section 3 ##########################
    RES=`ls "$MOUNTFLDR"/"$prj"/images`
    for resolution in $RES
    do
        if [ "$resolution" == lowres ]; then
            RESname="$RESname"Small
        fi
        
        DATE=$(date +"%Y_%m_%d %H_%M_%S")
        sh $LOGGER $SCRIPT  "Starting Project/Resoution: $RESname @ $DATE."



# Use sort to order them in reverse order so that the latest gigapans will stitch first.
            #TOSTITCH=`cat "$RESname"_STITCHING_$$.txt`
            TOSTITCH=`sort -r "$RESname"_STITCHING_$$.txt`



        if [ -z "$TOSTITCH" ]; then
			# Nothing to stitch.
            sh $LOGGER $SCRIPT  "Nothing to stitch."
            rm -f "$RESname"_STITCHING_$$.txt
            
            #sh $LOGGER $SCRIPT  "Removed STITCHING .txt files"
            #sh $LOGGER $SCRIPT  "Removed $RESname _STITCHING_ $$ .txt"
        else
            #sh $LOGGER $SCRIPT  "Prepare to stitch."
            
            for dir in $TOSTITCH
            do
            
		UNITS=`ps -u labadmin | grep GigaPan | grep -v grep | wc -l | grep -o [[:digit:]]` 
				# ??? ONLY START STITCHING IF THERE IS LESS THEN 2 instances currently running.
                                # This is correct.  This limits the number of GigaPan programs that can run simultaneously
                                # This is for performance only.  A faster computer could handle more
                                # Change the number to increase or decrease the number of simultaneous stitching
                if [ $UNITS -lt 1 ]; then
                    UNITS=`expr $UNITS + 1`
                
                    #### EXTRACT STITCHING VARIABLES FROM DATABASE ####
					
					# What happens here is $dir, which is a row of the database, is set to default vairbles in the shell
                                        # Since I have changed the IFS to ",", the shell will give the defult names for each column.
                                        # $1, $2, and so on represent the values of that column for that row.
					
                    IFS=,
                    set $dir
                    FLDR=$1
                    title=""$RESname"_$1" # Title for the gigapan.
                    LOCALPATH=`echo $2 | sed "s:$PROJECTFLDR:$MOUNTFLDR:"`
                    parent=`dirname $LOCALPATH`
                    savegiga=""$parent"/"$RESname"_$1.gigapan" # Where to save the gigapan.
                    col=$4
                    row=$5
                    IFS=$OLD_ifs
                
            sh $LOGGER $SCRIPT  -------- $COUNT of $AMOUNT ---------
            sh $LOGGER $SCRIPT  Saving to $savegiga
            sh $LOGGER $SCRIPT  Number of Columns: $col
            
            
					# Build a list of all of the images for that image set, which will be passed to the Gigapan stitcher.
                    ls $LOCALPATH/*[0-9].jpg > "$RESname"_imagelist_$$.txt
            					
                                        # STATUSprogram.sh generates a html file that shows which which queues are being processed
                                        # and which queues are not being processed
                                        # During updating the STATUSprogram needs these variables to know which queue is being updated (RESname)
                                        # the total count of that queue (COUNT) and the where it is in the queue (UNITS)
                                        # yes indicate to STATUSprogram that this RESname is currently being processed
                    sh $GIGAVISION/STATUSprogram.sh $MOUNTFLDR $RESname $COUNT $UNITS yes $title
                    
			
					
                        # Run Stitcher - if possible run a "timestitch" where the image is matched to a master image.
                        
                        # Attempt to find appropriate master image from CamConfig file
                        
                        sh $LOGGER $SCRIPT   "Call: php "$GIGAVISION"/get_camconfig_info.php -p $prj -f $resolution -d $name"
            
                CAMCONFIGINFO=`php "$GIGAVISION"/get_camconfig_info.php -p $prj -f $resolution -d $name`
                OLD_ifs=$IFS
                IFS=","
                A_CAMCONFIGINFO=($CAMCONFIGINFO)
                TILEMASTER=${A_CAMCONFIGINFO[3]}           
                IFS=$OLD_ifs
                
                if [ ! "$TILEMASTER" ]; then
                    ## run normal stitch with no tilemaster
                    # Run the Gigapan stitching application!
                    MASTERPHRASE=""        
                    
                else
                    # Run matching stitcher.
                    
                    #prepare path to tilemaster
                    #master
                    IFS="_"
                    A_M=($TILEMASTER)
                    MYEAR=${A_M[0]}
                    MMONTH=${A_M[1]}
                    MDAY=${A_M[2]}
                    MHOUR=${A_M[3]}
                    IFS=$OLD_ifs
                    
                    mastergiga="$MOUNTFLDR"/"$PROJECT"/images/"$RES"_timestitch/"$MYEAR"/"$MYEAR"_"$MMONTH"/"$MYEAR"_"$MMONTH"_"$MDAY"/"$RESname"_"$MYEAR"_"$MMONTH"_"$MDAY"_"$MHOUR".gigapan
                    echo "master: $mastergiga"
                    
                    MASTERPHRASE=" --master $mastergiga"

                    #write out mastergiga file to image directory so we know with which master image it was stitched.
                fi      
                
                DATE=$(date +"%Y_%m_%d %H_%M_%S")
                 sh $LOGGER $SCRIPT  "Starting Stitch @ $DATE."	     
                sh $LOGGER $SCRIPT "/Applications/GigaPan\ 1.1.1191/GigaPan\ Stitch\ 1.1.1191.app/Contents/MacOS/GigaPan\ Stitch\ 1.1.1191 --batch-mode --align-quit --title $title --image-list $RESname_imagelist_$$.txt --rowfirst --downward --rightward --nrows $col --save-as $savegiga $MASTERPHRASE"
                echo "/Applications/GigaPan\ 1.1.1191/GigaPan\ Stitch\ 1.1.1191.app/Contents/MacOS/GigaPan\ Stitch\ 1.1.1191 --batch-mode --align-quit --title $title --image-list $RESname_imagelist_$$.txt --rowfirst --downward --rightward --nrows $col --save-as $savegiga $MASTERPHRASE"
                #/Applications/GigaPan\ 1.1.1191/GigaPan\ Stitch\ 1.1.1191.app/Contents/MacOS/GigaPan\ Stitch\ 1.1.1191 --batch-mode --align-quit --title $title --image-list "$RESname"_imagelist_$$.txt --rowfirst --downward --rightward --nrows $col --save-as $savegiga "$MASTERPHRASE"
                /Applications/GigaPan\ 1.1.1191/GigaPan\ Stitch\ 1.1.1191.app/Contents/MacOS/GigaPan\ Stitch\ 1.1.1191 --batch-mode --align-quit --title $title --image-list "$RESname"_imagelist_$$.txt --rowfirst --downward --rightward --nrows $col --save-as $savegiga
                     
                     
                     # EVERYTHING PAUSES until Stitcher is finished.   
                        		
                    rm -f "$RESname"_imagelist_$$.txt
        
		
		
            #################### Section 7 ##########################
                    sh $LOGGER $SCRIPT  "Section 7 - Get the information from gigapan files and put in gigapan database."
			# Get the information from the gigapan file(s) and put it in the gigapan database.
			# Essentially run the GIGADBprogram.sh
			
			
                    sh $GIGAVISION/GIGADBprogram.sh $PROJECTFLDR $MOUNTFLDR $prj $resolution no $savegiga
                    #sh $GIGAVISION/OPERATORprogram.sh gigapan $PROJECTFLDR $MOUNTFLDR $prj $resolution no $savegiga
            
			
            #################### Section 8 ##########################
        
			# Update Status
			
                    COUNT=`expr $COUNT + 1`
                fi ### Closing [ $UNITS -lt 3 ] ###
				# Keeps STITCHING.txt file so that the queue remains eventhough it cannot be stitched at this time
                                # Further explaintion about this process can be found in the STATUSprogram header.	
            done  ### Closing dir ###
        fi  ## Closing [ -z $TOSTITCH ] ###
        
        
        sh $LOGGER $SCRIPT  "Calling STATUSprogram.sh after stitching (or determining no stitching necessary)"
        sh $GIGAVISION/STATUSprogram.sh $MOUNTFLDR $RESname 0 $UNITS no
        sh $LOGGER $SCRIPT  "Back from STATUSprogram.sh"
        
        
        
        
        
        



    done ### Closing resolution ###
    #rm -f "$RESname"_STITCHING_$$.txt
done  ### Closing prj ###
fi ## Closing if perform stitch.


############### Update Summary file ##############
                    # The script will not attempt to unmount if a GigaPan application is running.
Processing=`ps -u labadmin | grep -v grep | grep -m 1 GigaPan`

#CLZ disable unmounting - this is a test to see if this is what is causing the error: Permission denied (publickey,gssapi-with-mic,password). lost connection
#if [ ! "$Processing" ]; then
#umount $MOUNTFLDR
#rmdir $MOUNTFLDR
#fi

sh $LOGGER $SCRIPT  "Complete."