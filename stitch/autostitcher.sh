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

echo ""
echo ""
echo ""
echo ""

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$DIR"/../shared/config.ini

cd /

PATH=$PATH:/sbin
export PATH

####### Variables that need to be changed for custom stitching ###########

SCRIPT="Autostitcher.sh"

#######################################################################

# Archive previous log file by renaming it
DATE=$(date +"%m_%d %H")
mv -f "$LOG_AUTOSTITCH".txt "$LOG_AUTOSTITCH"_"$DATE".txt 
DATE=$(date +"%Y_%m_%d %H_%M_%S")
sh $LOGGER $SCRIPT "Starting Autostitcher.sh @ $DATE"



# If this script is running - dont run it again.

# UNITS: Number of Gigapan processes currently running.
# List processes, Filter on Gigapan, Remove grep, count number of lines, get the value.
# Units are set here in order to run STATUSprogram when there are no gigapans to stitch
#UNITS=`ps -u labadmin | grep GigaPan | grep -v grep | wc -l | grep -o [[:digit:]]` 

# ??? What is $IFS - an environment variable on the machine?
# IFs (Internal Field Sperators) is how the shell understands how list are seperated.

OLD_ifs=$IFS

if [ "$DO_DRIVEMOUNT" == "yes" ];then
    if [ ! -d $MOUNTFLDR ];then
    mkdir $MOUNTFLDR
    fi
    ##mount_smbfs -f 775 -o nobrowse //$USER:$PASS@eeg/"$USER"/gigavision/projects "$MOUNTFLDR"
    mount_smbfs -f 775 -o nobrowse //$USER:$PASS@gigavision/upload "$MOUNTFLDR"
fi

cd $TMP_FLRD ### Working directory for temporary files ###





#################### INIT 1 - Round Robin Determine Project to Run. ##########################
sh $LOGGER $SCRIPT "### INIT 1. Determine Projects To Run (And order) #####"

PROJECT_LIST=`ls $MOUNTFLDR`
#PROCESS ONLY MeteoSLC
#PROJECT="MeteoSLC"

# Reorder list so that the last item to start stitching will be the first.
sh $LOGGER $SCRIPT "Raw Project List: $PROJECT_LIST"

cd $TMP_FLDR
PROJECT_TO_RUN=`cat current_project.txt`
sh $LOGGER $SCRIPT "Most recent project: $PROJECT_TO_RUN"

i=0
b_save=0
PROJECT_LIST_ORDERED=""
cutoff=100
for prj in $PROJECT_LIST
do
#echo "Process $prj"   
    if [ "$prj" == "$PROJECT_TO_RUN" ]; then
#        echo $prj > $TMP_FLRD/current_project.txt
#        echo "Yes, $prj = $PROJECT_TO_RUN"
        b_save=1
        cutoff=$i;
    fi
    # Is it this projects turn?   
    if [ "$b_save" == 1 ]; then
#       echo "save $prj to $i"
        PROJECT_LIST_ORDERED=`echo $PROJECT_LIST_ORDERED $prj`
    fi
    i=$((i+1))
#echo "Now PROJECT=$PROJECT"
done

#echo "Now append the first entries to the end of the array."
j=0;
for prj in $PROJECT_LIST
do
#    echo "Process $prj"    
    if [ "$j" -lt "$cutoff" ]; then       
#        echo "save $prj to $i"        
        PROJECT_LIST_ORDERED=`echo $PROJECT_LIST_ORDERED $prj`
    fi
    j=$((j+1))
    i=$((i+1))
done
PROJECT_LIST=$PROJECT_LIST_ORDERED
echo 
sh $LOGGER $SCRIPT "Ordered Projects to run: $PROJECT_LIST"



# Filter projects out
PROJECT_LIST_FILTERED=""
for prj in $PROJECT_LIST
do
    INSTR=`echo "$PROJECTS_TO_PROCESS" | grep -c "$prj"`
    if [ "$INSTR" != "0" ]; then
        #        echo "save $prj to $i"        
        PROJECT_LIST_FILTERED=`echo $PROJECT_LIST_FILTERED $prj`
    fi
done
PROJECT_LIST=$PROJECT_LIST_FILTERED
echo 
sh $LOGGER $SCRIPT "Filtered Projects to run: $PROJECT_LIST"





#################### PROJECT LOOP ##########################
sh $LOGGER $SCRIPT
sh $LOGGER $SCRIPT "##### INIT 2. Start Project Loop #####"


for prj in $PROJECT_LIST
do
    sh $LOGGER $SCRIPT ""
    sh $LOGGER $SCRIPT ""
    
    sh $LOGGER $SCRIPT  "### Starting Project: $prj ###"
    cd $TMP_FLDR

    echo $prj > "current_project.txt"
    

    RESname=$prj

    
    
    echo $prj > Gathered_STITCHING_$$.txt #What is this for?
    RES=`ls "$MOUNTFLDR"/"$prj"/images`
    
    #################### RESOLUTION LOOP ##########################
    
    for resolution in $RES
    do

        #Make sure resolution does not have an _ . This removes the test directories.
        INSTR=`echo "$resolution" | grep -c "_"`
        if [ "$INSTR" != "0" ]; then
          # string found
          sh $LOGGER $SCRIPT  "$resolution has an _ in it. Skipping."
          rm -f Gathered_STITCHING_$$.txt
          continue #
        else
          # string not found
          sh $LOGGER $SCRIPT  "$resolution does not have _ in it."
        fi

        #Filter out resolutions.
        INSTR=`echo "$RESOLUTIONS_TO_PROCESS" | grep -c "$resolution"`
        if [ "$INSTR" != "0" ]; then
            # string found
            sh $LOGGER $SCRIPT  "$resolution in RESOLUTIONS_TO_PROCESS."
            
            
        else
            # string not found
            sh $LOGGER $SCRIPT  "$resolution not in RESOLUTIONS_TO_PROCESS. Skipping"
            rm -f Gathered_STITCHING_$$.txt
            continue
        fi

        
        
        if [ "$resolution" == lowres ]; then
            RESname="$RESname"Small
        fi
        
        sh $LOGGER $SCRIPT  ""
        sh $LOGGER $SCRIPT  ""
        
        DATE=$(date +"%Y_%m_%d %H_%M_%S")
        sh $LOGGER $SCRIPT  "###### Starting ProjectResoution: $RESname /  $resolution @ $DATE."	
        
        sh $LOGGER $SCRIPT  "### STEP 1 - Calculate image offsets."

        if [ "$DO_OFFSETCALC" == "yes" ];then
                sh $LOGGER $SCRIPT  "Calculating image offsets for new Gigapans."	
                if [ "$resolution" == lowres ]; then
                    php $SCRIPTS_OFFSET_FLDR/offsetgenerator_auto.php -- -p $prj -f false
                else
                    php $SCRIPTS_OFFSET_FLDR/offsetgenerator_auto.php -- -p $prj 
                fi
        fi

        sh $LOGGER $SCRIPT  ""
        sh $LOGGER $SCRIPT  "### STEP 2 - Scan image folders and update image database."
        
		# Update Image Database by scanning all of the image directories of the past two months 
		
        IMGDB=""$MOUNTFLDR"/"$prj"/databases/db_"$prj"_"$resolution"_images.csv"
        sh $LOGGER $SCRIPT  $IMGDB
        sh $GIGAVISION/IMGDBprogram.sh $PROJECTFLDR $MOUNTFLDR $prj $resolution no
        sh $LOGGER $SCRIPT  "IMGDBProgram.sh complete."
	
		
        #################### STEP 3 ##########################
        sh $LOGGER $SCRIPT  ""
        sh $LOGGER $SCRIPT  "### STEP 3 - Creating lists of images to stitch."
        
        # Update BigBlowoutEast_unstitched_.txt.
        
		# Looking in the images database (just created) to figure out which images it should stitch.
		
		
		
		# This does not kill off any currently stitching processs only updates the image database
		## This occurs becuae the stitcher loades the imagelist file, which has the image paths in it.
		
		
		# Find all rows in IMGDB with N and Full and Good. Put them in "BigBlowoutEast_unstitched_.txt.
                # The images are unstiched becuase N is not stiched, FULL means they have complete set of images, Good means they have the correct naming convention.
		
                # They had been saved as unstitched becuase theses are imagesets that have not been stitched indicated by the database
                # however, the unstitched imagesets could be in a queue to be stitched (RESname_STITCHING.txt)
		
        (egrep ",N,|Cancellation" $IMGDB | grep "Full" | grep "Good") > "$RESname"_unstitched_$$.txt
        
        
        # Get rid of RESname_STITCHING_.txt files that are no longer being stitched.
                
		# Get a process list, Filter for Autostitcher, Filter out grep commands, and get the PID (Process ID)
                # It checks to see if other Autosticher programs are running
                # This is in place to remove zombie RESname_STITCHING.txt files
                # This is for the STATUSprogram.sh which uses the STITCHING files to determine the amount in each queue.
        ps -u "$STITCHING_USER" | grep Autostitcher | grep -v grep | grep -o -E  "[[:digit:]]+ [[:digit:]]+" | grep -o -E [[:digit:]]+$ | sort > PROCPID
        
                # This finds all of the PIDs of the files in the tmp folder
                # It then compares the currently running PIDs with all of the txt PIDs and delets the ones that are zombie files
		ls "$TMP_FLDR" | grep -E -o "$RESname"_STITCHING_[[:digit:]]+ | grep -o -E [[:digit:]]+$ | sort > TXTPID
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
		
            OTHERS=`find "$TMP_FLDR" -maxdepth 1 -regex "^.*"$RESname"_STITCHING.*$"`
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
            TOSTITCH=`cat "$RESname"_STITCHING_$$.txt`
            #TOSTITCH=`sort -r "$RESname"_STITCHING_$$.txt`





        #################### STEP 4 ##########################
        sh $LOGGER $SCRIPT  ""
        sh $LOGGER $SCRIPT  "### STEP 4 - Start stitching queued items."	
		# Check stitch status, and Start stitching if appropriate.
		# Maintain and Report status.
		
		# UNITS: Number of Gigapan processes currently running.
		# List processes, Filter on Gigapan, Remove grep, count number of lines, get the value.
                # Units are set here in order to run STATUSprogram when there are no gigapans to stitch
                UNITS=`ps -u "$STITCHING_USER" | grep GigaPan | grep -v grep | wc -l | grep -o [[:digit:]]` 
		
        if [ -z "$TOSTITCH" ]; then
			# Nothing to stitch.
            sh $LOGGER $SCRIPT  "Nothing to stitch."
            rm -f "$RESname"_STITCHING_$$.txt
            sh $LOGGER $SCRIPT  "Removed STITCHING .txt files"
            sh $LOGGER $SCRIPT  "Removed $RESname _STITCHING_ $$ .txt"
        else
            sh $LOGGER $SCRIPT  "Prepare to stitch."
            
            LISTS=`find "$TMP_FLDR" -maxdepth 1 -regex "^.*"$RESname"_imagelist.*$"`
            rm -f $LISTS
	    sh $LOGGER $SCRIPT  "Removed temp files."	
                        
            IFS=" "
			# AMOUNT: Actual number of gigapans to be stitched.
            AMOUNT=`echo $TOSTITCH | wc -l | grep -o -E [[:digit:]]+`
            
            sh $LOGGER $SCRIPT  "# items to stitch: $AMOUNT"
            
            IFS=$OLD_ifs
            COUNT=1  ### Used to count how many gigapans have been completed ###
            
            #sh $LOGGER $SCRIPT  Images that are going to be stitched:
            #IFS=" "
            #sh $LOGGER $SCRIPT  $TOSTITCH
            #IFS=$OLD_ifs
            sh $LOGGER $SCRIPT  ----------------
                
               
            for dir in $TOSTITCH
            do
            
            echo "IMG DB LINE TO STITCH: $dir"
            
            PROCESS_STITCH=1
            
            if [ "$PROCESS_STITCH" ]; then
            
                
                #exit
                
                
                UNITS=`ps -u "$STITCHING_USER" | grep GigaPan | grep -v grep | wc -l | grep -o [[:digit:]]` 
				# ??? ONLY START STITCHING IF THERE IS LESS THEN 2 instances currently running.
                                # This is correct.  This limits the number of GigaPan programs that can run simultaneously
                                # This is for performance only.  A faster computer could handle more
                                # Change the number to increase or decrease the number of simultaneous stitching
                sh $LOGGER $SCRIPT  "Gigpan Apps already running: $UNITS"

                if [ $UNITS -lt 2 ]; then
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
                    sh $LOGGER $SCRIPT "LOCALPATH: $LOCALPATH"

                    parent=`dirname $LOCALPATH`
                    savegiga=""$parent"/"$RESname"_$1.gigapan" # Where to save the gigapan.
                    col=$4
                    row=$5
                    IFS=$OLD_ifs
                

                    #Test if 12:00
                    echo FLDR=$FLDR
                    if [ "$DO_ONLY_STITCH_NOON" == "yes" ];then                    
                        if [[ "$FLDR" == ????_??_??_12 ]]
                        then
                        sh $LOGGER $SCRIPT "Is a noon gigapan"
                        else
                        sh $LOGGER $SCRIPT "Is not a noon gigapan"
                        continue #Loop to the next item in the list.
                        fi
                    fi

                    sh $LOGGER $SCRIPT  "-------- $COUNT of $AMOUNT ---------"
                    sh $LOGGER $SCRIPT  "Saving to $savegiga"
                    sh $LOGGER $SCRIPT  "Number of Columns: $col"
                    
                    sh $LOGGER $SCRIPT  "Create image list: $RESname _imagelist_$$.txt"
                    cd "$TMP_FLDR"


					# Build a list of all of the images for that image set, which will be passed to the Gigapan stitcher.
                    ls $LOCALPATH/*[0-9].jpg > "$RESname"_imagelist_$$.txt
  

                    # STATUSprogram.sh generates a html file that shows which which queues are being processed
                    # STATUSprogram needs COUNT, number of items in queue, UNITS, where it is in the queue
                    # YES indicates to STATUSprogram that this RESname is currently being processed
                    sh $GIGAVISION/STATUSprogram.sh $MOUNTFLDR $RESname $COUNT $UNITS yes $title
                    
                

                        
                    # Run Stitcher - if possible run a "timestitch" where the image is matched to a master image.
                    sh $LOGGER $SCRIPT "Determine Master image."

                    # Attempt to find appropriate master image from CamConfig file
                    name=$FLDR
                    sh $LOGGER $SCRIPT   "Call: php "$GIGAVISION"/get_camconfig_info.php -p $prj -f $resolution -d $name"
                
                    CAMCONFIGINFO=`php "$GIGAVISION"/get_camconfig_info.php -p $prj -f $resolution -d $name`
                    sh $LOGGER $SCRIPT   "CamConfig Result: $CAMCONFIGINFO"

                    OLD_ifs=$IFS
                    IFS=","
                    A_CAMCONFIGINFO=($CAMCONFIGINFO)
                    TILEMASTER=${A_CAMCONFIGINFO[2]}           
                    IFS=$OLD_ifs
                    
                    if [ ! "$TILEMASTER" ]; then
                        ## run normal stitch with no tilemaster
                        # Run the Gigapan stitching application!
                        MASTERPHRASE=""   
                        MASTERTIME=""
                        sh $LOGGER $SCRIPT "No Master Gigapan found in CamConfig."
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
                        
                        MASTERTIME="$MYEAR"_"$MMONTH"_"$MDAY"_"$MHOUR"
                        mastergiga="$MOUNTFLDR"/"$prj"/images/"$resolution"/"$MYEAR"/"$MYEAR"_"$MMONTH"/"$MYEAR"_"$MMONTH"_"$MDAY"/"$RESname"_"$MYEAR"_"$MMONTH"_"$MDAY"_"$MHOUR".gigapan
                        sh $LOGGER $SCRIPT "Master Gigapan From CamConfig: $mastergiga"
                        ## TODO - Determine if master gigapan actually exists - and stitch it if not. Or report error.
                        
						if [ ! -f $mastergiga ];
						then
							sh $LOGGER $SCRIPT "Master Gigapan File does not exist, so stitch it now: $mastergiga"
                        
							#Run with timeout.
							#BigBlowoutEast_2010_05_14_12
							title_master=""$RESname"_$MASTERTIME" # Title for the gigapan.
							
							sh $LOGGER $SCRIPT  "Master: Create image list for masterstitch: $RESname _imagelist_master_$$.txt"
							cd "$TMP_FLDR"
							# Build a list of all of the images for that image set, which will be passed to the Gigapan stitcher.
							LOCALPATH_master="$MOUNTFLDR"/"$prj"/images/"$resolution"/"$MYEAR"/"$MYEAR"_"$MMONTH"/"$MYEAR"_"$MMONTH"_"$MDAY"/"$MYEAR"_"$MMONTH"_"$MDAY"_"$MHOUR"                        
							sh $LOGGER $SCRIPT  "Master: LOCALPATH_master= $LOCALPATH_master"
							ls $LOCALPATH_master/*[0-9].jpg > "$RESname"_imagelist_master_$$.txt
							
							IMAGELIST_master="$RESname"_imagelist_master_"$$".txt
							sh $LOGGER $SCRIPT  "Master: imagelist= $IMAGELIST_master"			
							sh $LOGGER $SCRIPT  "Starting Stitch: $RESname @ $DATE."
							AUTOSTITCH_CMD_master="$STITCHER_PATH --batch-mode --align-quit --title $title_master --image-list $IMAGELIST_master --rowfirst --downward --rightward --nrows $col --save-as $mastergiga"
							sh $GIGAVISION/run_with_timeout.sh "$AUTOSTITCH_CMD_master"
							sh $LOGGER $SCRIPT  "Master Stitch Complete: $RESname @ $DATE."  
						fi
                        MASTERPHRASE=" --master $mastergiga"
                    fi     

                    #Use this to Disable Master stitching
                    #MASTERPHRASE=""   
                       
                    DATE=$(date +"%Y_%m_%d %H_%M_%S")
                    sh $LOGGER $SCRIPT  "Starting Stitch: $RESname @ $DATE."
                    START_SECOND=$(date +%s)
            
                    IMAGELIST="$RESname"_imagelist_"$$".txt
                    sh $LOGGER $SCRIPT  "imagelist= $IMAGELIST"

                    AUTOSTITCH_CMD="$STITCHER_PATH --batch-mode --align-quit --title $title --image-list $IMAGELIST --rowfirst --downward --rightward --nrows $col --save-as $savegiga $MASTERPHRASE"

                                    
                    if [ "$DO_STITCH" == "yes" ];then

                        #Write which gigapan it tried to stitch to into source image directory.:
                        echo $MASTERTIME > "$LOCALPATH/mastertime.txt"
                        
                        echo autostitch_cm= $AUTOSTITCH_CMD
                        sh $LOGGER $SCRIPT "autostitch_cm= $AUTOSTITCH_CMD"
                        echo "$DATE $RESname -  $AUTOSTITCH_CMD" >> "$LOGFLDR"/a_stitch_log.txt
                        
                        # Run without timeout
                        #eval "$AUTOSTITCH_CMD"
  
                        #Run with timeout.
                        echo "Run with timeout." >> "$LOGFLDR"/a_stitch_log.txt 
                        sh $GIGAVISION/run_with_timeout.sh "$AUTOSTITCH_CMD"

                        
                        DATE=$(date +"%Y_%m_%d %H_%M_%S")
                        FINISH_SECOND=$(date +%s)
                        MINUTES_ELAPSED=$((($FINISH_SECOND-$START_SECOND)/60))
                        sh $LOGGER $SCRIPT  "Stitch Complete in $MINUTES_ELAPSED Minutes: $RESname @ $DATE."     
                        echo "$DATE $RESname - Stitch Complete in $MINUTES_ELAPSED Minutes." >> "$LOGFLDR"/a_stitch_log.txt 

                        
                    fi  #DO_STITCH          
                
                # Note: EVERYTHING PAUSES until Stitcher is finished.   
                        		
                rm -f "$RESname"_imagelist_$$.txt
        

		

                #################### STEP 5 ##########################
                sh $LOGGER $SCRIPT  ""
                sh $LOGGER $SCRIPT  "### STEP 5 - Get the information from gigapan files and put in gigapan database."
                # Get the information from the gigapan file(s) and put it in the gigapan database.
                # Essentially run the GIGADBprogram.sh
			
			
                sh $GIGAVISION/GIGADBprogram.sh $PROJECTFLDR $MOUNTFLDR $prj $resolution no $savegiga
                #sh $GIGAVISION/OPERATORprogram.sh gigapan $PROJECTFLDR $MOUNTFLDR $prj $resolution no $savegiga
            
			
            #################### Step 6 ##########################
            sh $LOGGER $SCRIPT  "### STEP 6 - Update Status."
			# Update Status
			
                    COUNT=`expr $COUNT + 1`
                fi ### Closing [ $UNITS -lt 3 ] ###
				# Keeps STITCHING.txt file so that the queue remains eventhough it cannot be stitched at this time
                                # Further explaintion about this process can be found in the STATUSprogram header.	
            fi ## Closing PerformStitch
            


            if [ "$DO_ONLY_ONLY_ONE_STITCH_PER_PROJECT" == "yes" ];then
                break ## Break out of loop because we only want to do one iteration.
            fi
            
            done  ### Closing dir ###
        
        fi  ## Closing [ -z $TOSTITCH ] ###
        
        
        sh $LOGGER $SCRIPT  "Calling STATUSprogram.sh after stitching (or determining no stitching necessary)"
        sh $GIGAVISION/STATUSprogram.sh $MOUNTFLDR $RESname 0 $UNITS no
        sh $LOGGER $SCRIPT  "Back from STATUSprogram.sh"
        

        
        
    done ### Closing resolution ###
    rm -f "$RESname"_STITCHING_$$.txt
done  ### Closing prj ###

echo "-" > "$TMP_FLRD"/current_project.txt

############### Update Summary file ##############
                    # The script will not attempt to unmount if a GigaPan application is running.

#CLZ disable unmounting - this is a test to see if this is what is causing the error: Permission denied (publickey,gssapi-with-mic,password). lost connection
#Processing=`ps -u "$STITCHING_USER" | grep -v grep | grep -m 1 GigaPan`
#if [ ! "$Processing" ]; then
#umount $MOUNTFLDR
#rmdir $MOUNTFLDR
#fi

sh $LOGGER $SCRIPT  "Complete."