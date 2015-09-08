#! /bin/sh
#############################################################
# File: 	OPERATORprogram.sh
# Author: 	Whitney Panneton
# Date: 	August 20, 2010
#	
# Function: To interact with a user and the program suite for rebuilding databases.
#
# Operations: The user is asked the database type, prject folder location, desired mount folder,
#             desired project(s) to rebuild, and the resoulation of the databse.
#             After the survey, the operator then calls on IMGDB and GIGDB to udate the approbriate database.
#	
# Called By: 	human user through shell
# Calls: 	IMGDBprogram.sh and/or GIGADBprogram.sh
#
# Important Environment Variables:
# DATABASE - The databse that should be built (image,gigapan, or both)
# PROJECTFLDR - The complete path of the projects folder on EEG
# MOUNTFLDR - The complete path that the PROJECTFLDR shcould be mounted to locally
# prj - The project(s) that programs should update (1 to all projects)
# resolution - The resolution of the database and the image folder to search
# manual - Indicates to GIGADB and IMGDB that the entire database should be rebuilt
#############################################################

#LOAD Global Configuration
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$DIR"/../shared/config.ini

SCRIPT="OPERATORProgram.sh"

#### Setting of Environmental Vairables from Inputs ####
DATABASE=$1
if [ ! $DATABASE ];then
    echo "Q: Which database do you want to build?"
    echo "|---> Pick One: image or gigapan? (Hit Enter/Return for both options)"
    read DATABASE
    if [ ! $DATABASE ] || [ $DATABASE == both ];then
        DATABASE=both
    else
    
    #Spellchecking of typed awnsers
    
while :
do
        case $DATABASE in #For each case in $DATABASE...
            gigapan) ∑Ω
                DATABASE=gigapan #set $DATABSE to gigapan
                break # then break from the loop
                ;;
            image)
                DATABASE=image
                break
                ;;
            *)
                echo "|---> Only lmage,gigapan, or both.  Whats it going to be?"
		read DATABASE
        esac
done

    fi
fi


#Commenting out these parameters because in practice we always want to use configured values.
#PROJECTFLDR_PARAM=$2
#if [ ! $PROJECTFLDR_PARAM ];then
#    echo Q: What is the parent directory for gigavision projects?
#    echo "|---> Ex. $PROJECTFLDR (Hit Enter/Return for Default)"
#    read PROJECTFLDR_INPUT
#    if [ ! $PROJECTFLDR_INPUT ];then
#        # Default setting.  If want to change Default do that here
#        PROJECTFLDR=$PROJECTFLDR
#    else
#        PROJECTFLDR=$PROJECTFLDR_INPUT
#    fi
#else
#    PROJECTFLDR=$PROJECTFLDR_PARAM
#fi


#MOUNTFLDR_PARAM=$3
#if [ ! $MOUNTFLDR_PARAM ];then
#    echo "Q: Where do you want the server to mount?"
#    echo "|---> Ex. $MOUNTFLDR (Hit Enter/Return for Default)"
#    read MOUNTFLDR_INPUT
#    if [ ! $MOUNTFLDR_INPUT ];then
#        # Default setting.  If want to change Default do that here
#        MOUNTFLDR=$MOUNTFLDR
#    else
#        MOUNTFLDR=$MOUNTFLDR_INPUT
#    fi
#else
#    MOUNTFLDR=$MOUNTFLDR_PARAM
#fi


if [ "$DO_DRIVEMOUNT" == "yes" ];then
    if [ ! -d $MOUNTFLDR ];then
        mkdir $MOUNTFLDR
    fi
    ##mount_smbfs -f 775 -o nobrowse //$USER:$PASS@eeg/"$USER"/gigavision/projects "$MOUNTFLDR"
    mount_smbfs -f 775 -o nobrowse //$USER:$PASS@gigavision/upload "$MOUNTFLDR"
fi

OLD_ifs=$IFS


prj=$4
if [ ! $prj ];then
    echo "Q: Which project do you want to build a database?"
    echo "|---> Pick one: "`ls $MOUNTFLDR`" (Hit Enter/Return for all projects)"
    read awns
    if [ ! "$awns" ] || [ "$awns" == all ];then
        prj=`ls $MOUNTFLDR`
    else
    
    # Spellchecking of typed awnsers
    # Spell is checked on the varibale list of projects
    
    while : # while is used to create a loop and only stops with when break command is given
    do
        for list in `ls $MOUNTFLDR` # For each 'list' item in the $MOUNTFLDR (this is the projects)
        do
                # Check the spelling of each project with the one typed in
            case $list in
                $awns)
                    prj=$awns
                    tester=correct # Variable used to designate if the spelling was matched
                    break # Break the for cycle
                    ;;
            esac
        done
        case $tester in # this could also be accomplished with logic if argument
            correct)
                break # breaks the while loop
                ;;
                *)
                echo "|---> Wrong spelling. Try Again."
                read awns #read the user input and then starts the while loop over again with new awnser
        esac
    done
    fi
fi

resolution=$5
if [ ! $resolution ];then
    echo "Q: Which resolution do you want for each project?"
    echo "|---> Pick one: lowres or fullres? (Hit Enter/Return for all options)"
    read resolution
    if [ ! "$resolution" ] || [ "$resolution" == all ]; then
        resolution=all
    fi
else

    #Spellchecking of typed awnsers

while :
do
    case $resolution in
        lowres)
            resolution=lowres
            break
            ;;
        fullres)
            resolution=fullres
            break
            ;;
	all)
	    resolution=all
	    break
	    ;;
        *)
            echo "|---> Only lowres,fullres, or all.  Whats it going to be?"
	    read resolution
    esac
done
fi

manual=$6
if [ ! $manual ];then
    clear
    echo "This is what I have so far:"
    echo "|--------------------------------------------------------------------------"
#echo "| Project location  -------------------- $PROJECTFLDR"
#   echo "| Mount loaction for project folder ---------- $MOUNTFLDR"
    echo "| Project(s) to udpate ----------------------- `echo $prj`"
    echo "| Database type to update in each project(s) - $DATABASE"
    echo "| The resolution of the databases ------------ $resolution"
    echo "|--------------------------------------------------------------------------"
    echo
    echo "Q: Are you sure you want to update database(s)"
    echo "|---> Press Enter/Return to continue otherwise type No."  
    read manual
    if [ ! "$manual" ]; then
        manual=yes
    else
	echo "Your choice. Exiting script now.  Please call again."
	exit
	fi
fi


##################

    
    # Archive previous log file by renaming it
DATE=$(date +"%m_%d %H")
mv -f /Users/admin/Gigavision/logs/autostitch_log.txt /Users/admin/Gigavision/logs/autostitch_log_"$DATE".txt 
DATE=$(date +"%Y_%m_%d %H_%M_%S")

sh $LOGGER $SCRIPT "Starting OPERATORprogram.sh @ $DATE"
    


    for multiprj in $prj
    do
        if [ "$resolution" == all ]; then
                    # Find the differnt resolution folders for the project ($multiprj)
            localres=`ls $MOUNTFLDR/$multiprj/images`
        else
            localres=$resolution # set resolution to desired choice
        fi
        
        for res in $localres
        do
            if [ $DATABASE == both ];then
                sh $LOGGER $SCRIPT "OPERATORprogram.sh calling IMGDBprogram $res $multiprj"
                sh $GIGAVISION/IMGDBprogram.sh $PROJECTFLDR $MOUNTFLDR $multiprj $res $manual
                sh $LOGGER $SCRIPT "OPERATORprogram.sh calling GIGADBprogram $res $multiprj"
                sh $GIGAVISION/GIGADBprogram.sh $PROJECTFLDR $MOUNTFLDR $multiprj $res $manual #$savegiga
            else
                if [ $DATABASE == image ];then
                    sh $LOGGER $SCRIPT "OPERATORprogram.sh calling IMGDBprogram $res $multiprj"
                    sh $LOGGER $SCRIPT "sh IMGDBprogram.sh $PROJECTFLDR $MOUNTFLDR $multiprj $res $manual"
                    sh $GIGAVISION/IMGDBprogram.sh $PROJECTFLDR $MOUNTFLDR $multiprj $res $manual
                else
                    sh $LOGGER $SCRIPT "OPERATORprogram.sh calling GIGADBprogram $res $multiprj"
                    sh $GIGAVISION/GIGADBprogram.sh $PROJECTFLDR $MOUNTFLDR $multiprj $res $manual
                fi
            fi
        done
    done
   
   sh $LOGGER $SCRIPT "Complete"