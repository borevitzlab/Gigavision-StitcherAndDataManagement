<?php
////////////////////////////////////////////////////////////////////////////////
//
//  TIMESCIENCE LLC
//  Copyright 2010 TimeScience LLC
//  All Rights Reserved.
//
//  NOTICE: TimeScience permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

ERROR_REPORTING(E_ALL);
echo 'TimeStitcher';

define('__ROOT__', dirname(dirname(__FILE__))); 
require_once(__ROOT__.'/shared/ts_offset_lib.php');  
require_once(__ROOT__.'/shared/ts_globals.php');  
    
$b_debug = false;

$s_project = "BigBlowoutEast";
$b_process_fullres = false;
$b_attempt_download = true;


$s_app_name = "timestitcher";
$s_key = "1";

$s_file_log_path = "$s_rootdir/logs/$s_app_name $s_key " . date("Y-m-d H:i:s"). " log.txt";
$s_file_errorlog_path = "$s_rootdir/logs/$s_app_name $s_key " . date("Y-m-d H:i:s"). " errorlog.txt";
$s_make_dir = "$s_rootdir/logs";
if (!is_dir($s_make_dir)){
	mkdir($s_make_dir, 0777,true);
}


logMsg("");
logMsg("--------------------------------------\r\n");
logMsg("Starting ${s_app_name} \r\n\r\n");

if ($b_process_fullres){
	$s_res_dir = "fullres";		
}else{
	$s_res_dir = "lowres";
}

//Load in Gigapan database
$s_path_project_db_dir = "$s_project_dir/$s_project/databases/";

$s_path_db = $s_path_project_db_dir . "db_${s_project}_${s_res_dir}_gigapans.csv";

$s_path_camconfig =  $s_path_project_db_dir . "${s_project}_${s_res_dir}_camconfig.xml";

$i_return = setSpanObjectsFromXML($s_path_camconfig);
if ($i_return != 0){
	logMsg("Could not open CamConfig file. Exiting. ${s_path_camconfig} \r\n\r\n");
	exit();	
}


$a_dates_to_process = Array();

$s_span = 4;
//setSpanVarsFromXML($s_span, "BigBlowoutEast_Full_camconfig.xml");
$s_hours = "8,16";
$CONFIG_MASTER_HOUR = "2010_07_01_12";
//$CONFIG_MASTER_HOUR = "2010_05_01_12";
//$CONFIG_MASTER_HOUR = "2010_09_27_12";

$s_dat_start = $a_camconfigs[$s_span]["s_dat_start"];
$s_dat_end = $a_camconfigs[$s_span]["s_dat_end"];

//$s_dat_start = "2010-07-02";
populateADatesToProcess($s_path_db,strtotime($s_dat_start),strtotime($s_dat_end),$s_hours);
//NOW $a_dates_to_process should be populated.

/**So now loop through dates - for each one
run the autostitcher.
*/

        

$PROJECTFLDR = "/web/borevitzlab/gigavision/projects";
$MOUNTFLDR = "/Users/admin/Gigavision/projects";

//local reality
$MOUNTFLDR = $s_project_dir;

$i_num_cols = $a_camconfigs[$s_span]["i_num_cols"];
logMsg("i_num_cols: $i_num_cols");

processGigapans($i_num_cols,$CONFIG_MASTER_HOUR,$s_res_dir);


logMsg("Finished ${s_app_name}\r\n");
logMsg("--------------------------------------");





//FILTER OUT EVERYTHING OUTSIDE OUR SPAN's date range.
//FILTER ON SPECIFIED HOUR

//Now scan gigapan list to see if there are any rows in the gigapan list that dont have an offset yet.
//watch out for header.
function populateADatesToProcess($s_path_db,$dat_start,$dat_end, $s_hour_filter){
        
        global $a_dates_to_process;
        
        $s_file_db = file($s_path_db); //sucks full contents into local variable.

        $a_hour_filter = explode(",",$s_hour_filter);
        
        foreach ($s_file_db as $s_line){
            //format = BigBlowoutEast_2009_09_26_10
            $a_fields = explode(",",$s_line);
            $s_dir = trim(substr($s_line,0,strpos($s_line,','))); //format is 03/06/2010 16:00
            $a_p = explode("_",$s_dir);
            
            //test if string is proper format - ie has _ chars. (This removes the header line.)
            if (array_key_exists(1,$a_p)){
                
                
                    $s_date = "$a_p[2]/$a_p[3]/$a_p[1] $a_p[4]:00";
                    $dat = strtotime($s_date);
                    
                    //is it withing bounds?
                    if ($dat >= $dat_start && $dat <= $dat_end){
                        //get hour of this date
                        $h = date("H",$dat);
                        
                        if (in_array($h,$a_hour_filter)){
                                
                                ///web/borevitzlab/gigavision/projects/BigBlowoutEast/images/fullres/2009/2009_09/2009_09_26/BigBlowoutEast_2009_09_26_10.gigapan
                                //build path to hour image directory:
				$s_hour_dir = $a_fields[0];
				$s_hour_dir = trim(substr($s_hour_dir,1 + strpos($s_hour_dir,'_'))); //format is 03/06/2010 16:00
                                $s_image_dir = dirname($a_fields[1]) . "/" . $s_hour_dir;
                                //$a_dates_to_process[$s_date]=$s_image_dir;
                                $a_dates_to_process[$s_dir]=$s_image_dir;
                        }
                        
                    }
                    	
            }	
        }          
}


///web/borevitzlab/gigavision/projects/BigBlowoutEast/images/fullres/2009/2009_09/2009_09_26/BigBlowoutEast_2009_09_26_10.gigapan
//s_master_hour is the hour of the master gigapan ie 2010_07_01_12.
function processGigapans($i_num_cols,$s_master_hour,$resolution){
        
	global $a_camconfigs;
        global $a_dates_to_process;
        global $s_stitcher_url;
	global $s_gigavision_dir;
	
	global $PROJECTFLDR, $MOUNTFLDR;
	global $b_process_fullres;
	global $b_debug;
	
        $i_time_process_start = time();
        
	$TMP="$s_gigavision_dir/tmp";

	$COLS = $i_num_cols;
	
	$RESname = "BigBlowoutEast";
	
	$IMAGELIST = "$TMP/${RESname}_imagelist_1.txt";
	
	
	$mastergiga = getGigapanPathFromHour($s_master_hour,$MOUNTFLDR,$RESname,$resolution,true);
	
	$i = 0;
        foreach ($a_dates_to_process as $s_hour_dir => $s_image_dir){
                
		logMsg(" hour dir: $s_hour_dir master hour: $s_master_hour");
		$s_hour_dir_comp = substr($s_hour_dir,strlen($s_hour_dir)-strlen($s_master_hour));
		logMsg(" hour dir compare: $s_hour_dir_comp");
		
		if ($i>-1 && $s_hour_dir_comp != $s_master_hour){
			logMsg("[Process $s_hour_dir]");
			//convert web url to file path url
			//LOCALPATH=`echo $2 | sed "s:$PROJECTFLDR:$MOUNTFLDR:"`
			$s_image_dir = str_replace($PROJECTFLDR,$MOUNTFLDR,$s_image_dir);
	
			$LOCALPATH = $s_image_dir;
	
			//Generate imagelist file
			$s_cmd = "ls $LOCALPATH/*[0-9].jpg > $IMAGELIST";
			//logMsg("create imagelist with: $s_cmd");
			//run command.
			interactiveShellExec($s_cmd);             
				      
		       ///Users/topher/Documents/gigavision_website/projects/BigBlowoutEast/images/fullres/2010/2010_07/2010_07_01
			//$s_output_dir = str_replace("fullres","fullres_timestitch",$s_image_dir);
			
			//remove hour directory
			$s_output_hour = basename($s_image_dir);
			//echo ("s_output_hour = $s_output_hour");
			
		
			$s_output_dir = getGigapanPathFromHour($s_output_hour,$MOUNTFLDR,$RESname,$resolution,true);
			//logMsg("s_output_dir= $s_output_dir");
			//break;
		
	
			$title = $s_hour_dir;
			$savegiga = $s_output_dir;
			
			
			logMsg("save path: $savegiga");
		       logMsg("master: $mastergiga");
		       
		       if (!$b_debug){
				$s_cmd = "$s_stitcher_url --batch-mode --align-quit --title $title --image-list $IMAGELIST --rowfirst --downward --rightward --nrows $COLS --save-as $savegiga  --master $mastergiga";
			       logMsg("run stitcher with: $s_cmd");  
				interactiveShellExec($s_cmd);
			}
		}//if
		$i++;
		//break;
        }//for

}


//s_master_hour is the hour of the master gigapan ie 2010_07_01_12.
function getGigapanPathFromHour($s_master_hour,$MOUNTFLDR,$RESname,$resolution,$b_timestitch){
	
	global $b_process_fullres;
	
	$a_time = explode("_",$s_master_hour);
	$y = $a_time[0];
	$m = $a_time[1];
	$d = $a_time[2];
	$h = $a_time[3];
	
	if ($b_process_fullres){
		$RESname2 = "BigBlowoutEast";
	}else{
		$RESname2 = "BigBlowoutEastSmall";
	}
	
	if ($b_timestitch){
		$s_path = "$MOUNTFLDR/$RESname/images/${resolution}_timestitch/$y/${y}_${m}/${y}_${m}_${d}/${RESname2}_${s_master_hour}.gigapan";	
	}else{
		$s_path = "$MOUNTFLDR/$RESname/images/$resolution/$y/${y}_${m}/${y}_${m}_${d}/${RESname2}_${s_master_hour}.gigapan";	
	}
	return ($s_path);
}



?>

