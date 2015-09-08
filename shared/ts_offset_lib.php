<?php

date_default_timezone_set("America/Los_Angeles");

function getDateFromHourPath($s_hour){
	$a_p = explode("_",$s_hour);          
        //test if string is proper format - ie has _ chars. (This removes the header line.)
        if (array_key_exists(1,$a_p)){
		$s_date = "$a_p[1]/$a_p[2]/$a_p[0]";		
	}else{
		return null;
	}
        if (array_key_exists(3,$a_p)){
		$s_date = $s_date . " $a_p[3]:00";		
	}else{
		$s_date = $s_date . " 00:00";
	}
 
        $dat = strtotime($s_date);
	return $dat;
}


function getPhoto(){
	global $y,$m,$d,$h;
	
	
	$dat_now = new DateTime("$y-$m-$d $h:00", new DateTimeZone('Pacific/Nauru')); 
	$dat_config5_start = new DateTime("2010-5-29", new DateTimeZone('Pacific/Nauru')); 
	
	if ($dat_now <=$dat_config5_start){
		$s_photo = "0109";
	} else{
		$s_photo = "0100";
	}
	
	return $s_photo;
}

function getUrlStringValue($urlStringName, $returnIfNotSet) {  
   if(isset($_GET[$urlStringName]) && $_GET[$urlStringName] != "")  
     return $_GET[$urlStringName];  
   else  
     return $returnIfNotSet;  
} 


function sZeroify($sIn) {		
	$i_length= strlen($sIn);
	if ($i_length == 1){
		return ("0$sIn");
	}else{
		return $sIn;
	}
}

function sZeroify4($sIn) {		
	$i_length= strlen($sIn);
	
	if ($i_length == 1){
		return ("000$sIn");
	}else if ($i_length == 2){
		return ("00$sIn");
	}else if ($i_length == 3){
		return ("0$sIn");
	}else {
		return $sIn;
	}
}

function interactiveShellExec($s_command){
	$handle = popen($s_command,'r');
	   while( !feof($handle)){
   		$buffer = fgets($handle);
   		echo "$buffer";
   		@ob_flush();
   		flush();
	}
	pclose($handle);
}



function prepareOffsetFiles($s_file_offsets_path, $s_imagelist_path,&$file_offsets,&$file_imagelist){
	//delete file first
	if (file_exists($s_file_offsets_path)){
		unlink($s_file_offsets_path);
	}
	if (file_exists($s_imagelist_path)){
		unlink($s_imagelist_path);
	}
//if (is_writable($s_file_offsets_path){
	$file_offsets = fopen($s_file_offsets_path, 'a+');
	$file_imagelist = fopen($s_imagelist_path, 'a+');
	
	fwrite($file_imagelist,"<?xml version=\"1.0\" encoding=\"utf-8\" ?>\r\n");
	fwrite($file_imagelist,"<imagelist>\r\n");
}

function finishOffsetfiles(&$file_offsets,&$file_imagelist){
	fclose($file_offsets);
	fwrite($file_imagelist,"</imagelist>\r\n");
	fclose($file_imagelist);
}



function calculateOffsets($s_file, &$i_x_offset, &$i_y_offset, &$i_count){
	
	if (!file_exists($s_file)){                     
		return 101;
        }
		
	try{
		$file = fopen($s_file,"r");
	} catch (Exception $e) {
		return 100;
	}
	if (! $file) return 100;
	

	echo "\n\nProcessing: $s_file \n";
	$i_x_accumulator = 0;
	$i_y_accumulator = 0;
	$i_count = 0;
	
	while(!feof($file)){
		
		//echo fgets($file);
		//Check start of line for character c - then its a control point.
		$s_line = fgets($file);
		if ($s_line[0] == 'c'){
			
			//echo "control point:" . $s_line;
			//extract x values and calculate difference.
			$a_values = explode(" ",$s_line);
			$x1 = $a_values[3];
			$x1 = substr($x1,1);
			$x2 = $a_values[5];
			$x2 = substr($x2,1);
			
			$y1 = substr($a_values[4],1);
			$y2 = substr($a_values[6],1);
			
			$i_x_delta = (int)$x1 - (int)$x2;
			$i_y_delta = (int)$y1 - (int)$y2;
			//echo "x1: $x1 , x2: $x2  xd: $i_x_delta   -   y1:$y1, y2:$y2 yd: $i_y_delta \n";
			
			$i_count++;
			$i_x_accumulator += $i_x_delta;
			$i_y_accumulator += $i_y_delta;
		}
	}
	
	fclose($file);
	
	if ($i_count > 0){
		$i_x_offset = round($i_x_accumulator / $i_count ,0) ;
		$i_y_offset = round($i_y_accumulator / $i_count,0) ;
	}else{
		$i_x_offset = .1;//-.01;
		$i_y_offset = .1;//-.01;
	}
	
	echo "\n Final Offsets: x:$i_x_offset y:$i_y_offset \n\n";
	return 0;
}



	

	function logMsg($s_msg){
		global $s_file_log_path;
		
		echo "MSG:::: $s_msg \r\n";
		$s_msg_log = date("Y-m-d H:i:s")." - $s_msg \r\n";
		
		$file_log = fopen($s_file_log_path, 'a+');	
		fwrite($file_log,$s_msg_log);
		fclose($file_log);
	}


	function logError($s_msg){
		global $s_file_errorlog_path;
		
		echo "ERROR:::: $s_msg \r\n";
		logMsg("ERROR:::: $s_msg ");
		
		
		$s_msg_log = date("Y-m-d H:i:s")." - ERROR: $s_msg \r\n";
		
		$file_log = fopen($s_file_errorlog_path, 'a+');	
		fwrite($file_log,$s_msg_log);
		fclose($file_log);
	}
        
        function logMT($s_msg){
		global $s_file_mtlog_path;
		
		echo "MT:::: $s_msg \r\n";
		$s_msg_log = date("Y-m-d H:i:s")." - $s_msg \r\n";
		
		$file_log = fopen($s_file_mtlog_path, 'a+');	
		fwrite($file_log,$s_msg_log);
		fclose($file_log);
	}

 //GUESS PHOTO POSITION based on position of tile
 /**
  * Returns integer of photo.
  * Also sets i_x_photo_guess and i_y_photo_guess parameters.
  */
function guessPhotoPosition($s_tilepath, &$i_x_photo_guess, &$i_y_photo_guess){
        global $photo_rows;
        global $photo_cols;
        global $stitch_w; 
        global $stitch_h;
               
        $i_x_mt = 0;
        $i_y_mt = 0;
        
        getXYPixelCoordinatesOfTile($s_tilepath, 0,9, $i_x_mt, $i_y_mt);
        $f_x_mt_ratio = $i_x_mt / $stitch_w;
        $f_y_mt_ratio = $i_y_mt / $stitch_h;
        
        //echo "Tile Postition. x: $i_x_mt y: $i_y_mt \r\n";	
        $i_x_photo_guess = round($f_x_mt_ratio * $photo_rows) + 1;
        $i_y_photo_guess = round($f_y_mt_ratio * $photo_cols);
        $i_photo = ($i_y_photo_guess) * ($photo_rows) + $i_x_photo_guess;
        if ($i_photo==0){
                $i_photo = 1;
        }     

        
        return $i_photo;
}

/**
Get coordinates of tile based on the path and starting depth.

$i_depth_top;//where the tree is starting. - so just parse the last chars.
*/
function getXYPixelCoordinatesOfTile($s_tilepath,$i_depth_top,$i_max_depth,&$i_x,&$i_y){

	global $tile_width;

	$i_x = 0;
	$i_y = 0;
	
	$quadrant=-1;
	
        if ($s_tilepath=="100000"){
                $dummy=3;
        }if ($s_tilepath=="000001"){
                $dummy=3;
        }
	for ($i = $i_depth_top; $i <= $i_max_depth; $i++){
		$quadrant = substr($s_tilepath, $i, 1);
		$i_height_in_sub_tree = $i_max_depth - $i - 1;
				
		if ($quadrant=="0"){
			$i_x += 0;
			$i_y += 0;
		}elseif($quadrant=="1"){
			$i_x += $tile_width * pow(2,$i_height_in_sub_tree);
			$i_y += 0;
		}elseif($quadrant=="2"){
			$i_x += 0;
			$i_y += $tile_width * pow(2,$i_height_in_sub_tree);
		}elseif($quadrant=="3"){
			$i_x += $tile_width * pow(2,$i_height_in_sub_tree);
			$i_y += $tile_width * pow(2,$i_height_in_sub_tree);
		}
	}
}


/*
function calculateOffsetsImageSizes($s_file, &$i_x_offset, &$i_y_offset, &$i_count){
		
	$file = fopen($s_file,"r");
	if (! $file) return 100;
	

	echo "\n\nProcessing: $s_file \n";
	$i_x_accumulator = 0;
	$i_y_accumulator = 0;
	$i_count = 0;
	
	$i_image_index = 1;
	$i_image_process_res = 1600;
	
	while(!feof($file)){
		
		
		
		//echo fgets($file);
		//Check start of line 
		$s_line = fgets($file);
		
		
		//Check for i to find images
		if ($s_line[0] == 'i'){
			$a_values = explode(" ",$s_line);
			
			$w = substr($a_values[1],1);
			$h = substr($a_values[2],1);
			if ($w >= $h){
				//w is larger.
				if ($w > $i_image_process_res){
					$f_reduction_ratio = 	$i_image_process_res / $w;
					$w = round($w * $f_reduction_ratio);
					$h = round($h * $f_recuction_ratio);
				}
			}else{
				//h is larger.
				if ($h > $i_image_process_res){
					$f_reduction_ratio = 	$i_image_process_res / $w;
					$w = round($w * $f_reduction_ratio);
					$h = round($h * $f_recuction_ratio);
				}	
			}
	
			//assign to proper image.	
			if ($i_image_index ==1){
				$w1 = $w;
				$h1 = $h;
			}else{
				$w2 = $w;
				$h2 = $h;
			}

			$i_image_index ++;			
		}
		
		
		//for character c - then its a control point.
		
		if ($s_line[0] == 'c'){
			
			//echo "control point:" . $s_line;
			//extract x values and calculate difference.
			$a_values = explode(" ",$s_line);
			$x1 = substr($a_values[3],1);
			$x2 = substr($a_values[5],1);
			
			$y1 = substr($a_values[4],1);
			$y2 = substr($a_values[6],1);
			
			
			$i_x_delta = (int)$x1 - (int)$x2;
			$i_y_delta = (int)$y1 - (int)$y2;
			//echo "x1: $x1 , x2: $x2  xd: $i_x_delta   -   y1:$y1, y2:$y2 yd: $i_y_delta \n";
			
			$i_count++;
			$i_x_accumulator += $i_x_delta;
			$i_y_accumulator += $i_y_delta;
		}
	}
	
	fclose($file);
	
	if ($i_count > 0){
		$i_x_offset = round($i_x_accumulator / $i_count ,0) ;
		$i_y_offset = round($i_y_accumulator / $i_count,0) ;
	}else{
		$i_x_offset = .1;//-.01;
		$i_y_offset = .1;//-.01;
	}
	
	echo "\n Final Offsets: x:$i_x_final y:$i_y_final \n\n";
	return 0;
}*/

/**
 * Argument should have no r at front. For example: 01002300
 */
function createTileFilePath($s_tilepath){
   $s_return = "";
   $i_len = strlen($s_tilepath);
   if ($i_len > 2){
      $s_return .= "r" . substr($s_tilepath,0,2) ."/";
    }
    if ($i_len > 5){
      $s_return .= substr($s_tilepath,2,3) ."/";
    }
    
    $s_return .= "r${s_tilepath}.jpg";
    return ($s_return);
}





/** Populate the $a_camconfigs array based on information from the camconfig xml file.
*/
function setCamConfigObjects_FromXML($s_filename_xml){
	global $a_camconfigs;
	
	$xml = simplexml_load_file($s_filename_xml);

	if (!$xml){
		//could not load the file
		return -1;
	}
	
	$s_test =  $xml->getName() ;
	foreach($xml->children() as $config)
	{
		
		$s_name = xml_attribute($config,"name");
		
		$s_dat_start = xml_attribute($config,"date_start");

		$i_stitch_tiledepth = xml_attribute($config,"stitch_tiledepth");
		$s_tilemaster_default = xml_attribute($config,"tilemaster_default");
		$s_tilepaths = xml_attribute($config,"tilepaths");
		$a_tilepaths = explode(",",$s_tilepaths);
		
		$i_num_rows = xml_attribute($config,"num_rows");
		$i_num_cols = xml_attribute($config,"num_cols");
		
		$a_dat_tile_master = null;
        /* CLZ.2012.08.18 Disabling this - it was too complicated to work with hours.
		foreach($config->children() as $tilemaster)
		{
			$i_hour = intval(xml_attribute($tilemaster,"hour"));
			$s_keyframe = xml_attribute($tilemaster,"keyframe");
			$a_dat_tile_master[$i_hour] = $s_keyframe;

		}
        */
			
		$o_camconfig["s_dat_start"] = $s_dat_start;

		$o_camconfig["dat_start"] = strtotime($s_dat_start);



		$o_camconfig["i_stitch_tiledepth"] = $i_stitch_tiledepth;
		$o_camconfig["s_tilemaster_default"] = $s_tilemaster_default;
		
		$o_camconfig["i_num_rows"] = $i_num_rows;
		$o_camconfig["i_num_cols"] = $i_num_cols;
		if ($a_dat_tile_master){
			$o_camconfig["a_dat_tile_master"] = $a_dat_tile_master;
		}
		if ($a_tilepaths){
			$o_camconfig["a_tilepaths"] = $a_tilepaths;
		}
		
		//$a_camconfigs[]
		$i=3;

		//$a_camconfigs[strtotime($s_dat_start)] = $o_camconfig;
        $a_camconfigs[$s_name] = $o_camconfig;
	}
	
	return 0;
}

function xml_attribute($object, $attribute)
{
    if(isset($object[$attribute]))
        return (string) $object[$attribute];
}


/** Based on date value - load up the proper CameraConfig variables.
 * returns a 0 on success.
 * Assumes and requires that the CameraCollections are ordered by date.
 * */
function getCamConfigValues_WithDate($dat_find){






	global $a_camconfigs;
	
	$a_dat_tile_master = null;

    $reversed = array_reverse($a_camconfigs);

	foreach($reversed as $o_cc){
        $dat_start = $o_cc["dat_start"];
		if ($dat_find >= $dat_start){
            getCamConfigValues_FromCamConfigObject($o_cc);
			return 0;
		}
	}
	return -1;

}


function getCamConfigValues_FromCamConfigObject($o_cc){
    global $a_tilepaths;
    global $s_tilemaster_default;
    global $s_dat_start, $a_dat_tile_master;
    global $i_num_rows;
    global $i_num_cols;
    global $i_stitch_tiledepth;

    $s_dat_start = $o_cc["s_dat_start"];
    $i_stitch_tiledepth = $o_cc["i_stitch_tiledepth"];
    $i_num_rows = $o_cc["i_num_rows"];
    $i_num_cols = $o_cc["i_num_cols"];

    $a_tilepaths =$o_cc["a_tilepaths"];
    $s_tilemaster_default = $o_cc["s_tilemaster_default"];
    /* CLZ.2012.08.18 Disabling this - it was too complicated to work with hours.
    if (array_key_exists("a_dat_tile_master",$o_cc)){
        $a_dat_tile_master = $o_cc["a_dat_tile_master"];
    }
    */
}

function getCamConfigValues_FromXML($s_span, $s_filename_xml){
	global $a_tilepaths;
	global $s_dat_start;
	//, $a_dat_tile_master;
	global $i_stitch_tiledepth;
    global $s_tilemaster_default;
	
	$xml = simplexml_load_file($s_filename_xml);

	//$s_test =  $xml->getName() ;
	foreach($xml->children() as $config)
	{
		//$a_attributes = $child->attributes();
		$s_name = xml_attribute($config,"name");
		if ($s_name == $s_span){
			$s_dat_start = xml_attribute($config,"date_start");

			$i_stitch_tiledepth = xml_attribute($config,"stitch_tiledepth");
			$s_tilepaths = xml_attribute($config,"tilepaths");
			$a_tilepaths = explode(",",$s_tilepaths);
            $s_tilemaster_default = xml_attribute($config,"tilemaster_default");

            /*CLZ.2012.08.18 Disabling this - it was too complicated to work with hours.
			foreach($config->children() as $tilemaster)
			{
				$i_hour = intval(xml_attribute($tilemaster,"hour"));
				$s_keyframe = xml_attribute($tilemaster,"keyframe");
				$a_dat_tile_master[$i_hour] = $s_keyframe;

			}
            */
			
			break;
		}
		//echo $child->getName() . ": " . $child . "<br />";
	}
	
}


?>