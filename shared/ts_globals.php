<?php

$s_rootdir = "/Gigavision";
$s_gigavision_dir=$s_rootdir;

$s_autopan_exe="/Gigavision/scripts/offset/autopano-sift-c";

$s_project_dir="/Volumes/Drobo/gigavision_projects";
//$s_project_dir="/Users/topher/Documents/gigavision_website/projects";

$s_stitcher_url = "/Applications/GigaPan\ 2.0.0500/GigaPan\ Stitch\ 2.0.0500.app/Contents/MacOS/GigaPan\ Stitch\ 2.0.0500";
//$s_stitcher_url = "/Applications/GigaPan\ 1.4.0001/GigaPan\ Stitch\ 1.4.0001.app/Contents/MacOS/GigaPan\ Stitch\ 1.4.0001";

$s_web_root_projects = "http://gigavision.anu.edu.au/gv/projects";

// Used for offset generation.
$PROJECTFLDR_URL="http://localhost/gv/projects";

//Should a control point be included in the offsts file - even if there is no match?
$b_include_failed_control_points=false;
?>