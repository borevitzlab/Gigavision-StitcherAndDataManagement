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

/*
Given project, resolution and hour string -
determines the correct number of rows and columns from the CamConfig file
 
*/


ERROR_REPORTING(E_ALL);
//echo 'Determine Rows and Columns for this project.\r\n';
define('__ROOT__', dirname(dirname(__FILE__))); 
require_once(__ROOT__.'/shared/ts_offset_lib.php');  
require_once(__ROOT__.'/shared/ts_globals.php');  
    

/// CONFIG that should be passed in as parameters.
//php script.php -p projectname -f fullres(boolean) -d date
 
//defaults for testing						
$b_test = false;

$b_process_fullres = false;
$s_project = "";
$s_date_hourpath= "";

if ($b_test){
        $s_project = "BigBlowoutEast";
        $b_process_fullres = "fullres";
        $s_date_hourpath = "2010_09_22_12";
			
		$s_project = "MeteoSLC";
        $b_process_fullres = "fullres";
        $s_date_hourpath = "2010_09_22_12"; 
}


while(count($argv) > 0) {
    $arg = array_shift($argv);
    switch($arg) {
        case '-p':
            $s_project  = array_shift($argv);
            break;
        case '-f':
		if (array_shift($argv)=="fullres"){
			$b_process_fullres  = true;
		}else{
			$b_process_fullres  = false;
                }
		//echo "found f parameter." . $b_process_fullres;
            break;
	case '-d':
                $s_date_hourpath = array_shift($argv);
            break;
    }
}

//echo values for debugging purposes
//echo "project:$s_project fullres?:$b_process_fullres hour:$s_date_hourpath'\r\n";


if ($b_process_fullres){
	$s_res_dir = "fullres";
        $s_image_root="$s_project";
}else{
	$s_res_dir = "lowres";
        $s_image_root="${s_project}Small";
}
	

//Load in CamConfig database

$s_path_project_db_dir = "$s_project_dir/$s_project/databases/";
$s_path_camconfig =  $s_path_project_db_dir . "${s_project}_${s_res_dir}_camconfig.xml";

//echo "\r\n $s_path_camconfig \r\n";

$i_return = setCamConfigObjects_FromXML($s_path_camconfig);
if ($i_return != 0){
	logMsg("Could not open CamConfig file. Exiting. ${s_path_camconfig} \r\n\r\n");
	echo "Could not open CamConfig file. Exiting. ${s_path_camconfig} \r\n\r\n";
	exit();	
}



//Now find camconfig information for a specific date
$date = getDateFromHourPath($s_date_hourpath);

// Initialize variables to prevent PHP Notices.
$i_num_cols = 0;
$i_num_rows = 0;
$s_tilemaster_default="";

getCamConfigValues_WithDate($date);

echo "$i_num_cols,$i_num_rows,$s_tilemaster_default";

?>

