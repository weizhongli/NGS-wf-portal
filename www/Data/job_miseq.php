<?php
  require("../includes/jcvi_miseq_header.php");
?>

<div id="middle_content_template">
<link rel="stylesheet" type="text/css" href="job.css">

<script type="text/javascript">
  function fold(me) {
    var x = document.getElementById('f' + me.id.substring(1));
    if (me.innerHTML == '+') {
      x.style.display = 'block';
      me.innerHTML = '-';
    } else {
      x.style.display = 'none';
      me.innerHTML = '+';
    }
  }
</script>

<?php

  function humanFileSize($size, $unit="") {
    // modified from: http://stackoverflow.com/questions/15188033/human-readable-file-size
    if ((!$unit && $size >= 1<<30) || $unit == "GB") {
      return number_format($size/(1<<30),2)." GB";
    } elseif ((!$unit && $size >= 1<<20) || $unit == "MB") {
      return number_format($size/(1<<20),2)." MB";
    } elseif ((!$unit && $size >= 1<<10) || $unit == "KB") {
return number_format($size/(1<<10),2)." KB";
} else {
return number_format($size)." bytes";
}
}

function process_this_dir($path) {
global $idir;
$files = scandir($path);
$sub_dirs = array();
$sub_files = array();
sort($files);
foreach ($files as $file) {
if (substr($file, 0, 1) === ".") continue;
if (substr($file, -5) === ".html") continue;
if (substr($file, -3) === ".pl") continue;
if (substr($file, -3) === ".sh") continue;
if (substr($file, 0, 2) === "WF") continue;
if (substr($file, 0, 3) === "NGS") continue;
if (is_dir("$path/$file")) {
array_push($sub_dirs, $file);
} else {
array_push($sub_files, $file);
}
}
if (empty($sub_dirs) && empty($sub_files)) return 0;
$dirname = "<span style='font-size:12px;'>".basename($path)."</span>";
if (substr_count($path, "/") === 1) {
$dirname = "Click to expand / collapse directories";
}
print "<p><button class='fold' id='b".$idir."' onclick='fold(this)'>+</button>".$dirname."</p>"."\n";
print "<div class='tree' id='f".$idir."'>"."\n";
$idir ++;
foreach ($sub_files as $file) {
print "<p style='font-size:12px;'><a href='".$path."/".$file."'>".$file." (".humanFileSize(filesize("$path/$file")).")</a></p>"."\n";
}
foreach ($sub_dirs as $dir) {
process_this_dir($path."/".$dir);
}
print '</div>'."\n";
return 0;
}

function process_WF_dir($path) {
global $idir;
$files = scandir($path);
$sub_dirs = array();
$sub_files = array();
sort($files);
foreach ($files as $file) {
if (substr($file, 0, 1) === ".") continue;
if (substr($file, -5) === ".pids") continue;
if (is_dir("$path/$file")) {
array_push($sub_dirs, $file);
} else {
array_push($sub_files, $file);
}
}
if (empty($sub_dirs) && empty($sub_files)) return 0;
$dirname = "Click to display workflow / program command line parameters and standard output";
print "<p><button class='fold' id='b".$idir."' onclick='fold(this)'>+</button>".$dirname."</p>"."\n";
print "<div class='tree' id='f".$idir."'>"."\n";
$idir ++;
foreach ($sub_files as $file) {
print "<p style='font-size:12px;'><a href='".$path."/".$file."'>".$file." (".humanFileSize(filesize("$path/$file")).")</a></p>"."\n";
}
foreach ($sub_dirs as $dir) {
process_this_dir($path."/".$dir);
}
print '</div>'."\n";
return 0;
}


// global variables
$idir = 1;  // current subdirectory level for tree structure visualization
$jobid = $_GET['jobid'];

// render page contents
if (file_exists("user-data/miseq/$jobid/readme.html")) {
print "<p>Congratulations! Your job <b>".$jobid."</b> is completed.</p>"."\n";
print "<p>This server is getting popular, we can not store big files for long time, files older than 90 days will be deleted!";
print "<hr>"."\n";

// job summary
$samples = array();  // (indexed => associative): name, left/right, group
    $f = fopen("user-data/miseq/$jobid/NGS-samples", "r");
    while (!feof($f)) {
      $line = trim(fgets($f));
      if ($line === "") continue;
      $a = explode(" ", $line);
      if (substr($a[0], 0, 6) === "Sample") {
        $sample = array(
          "name" => $a[0]
        );
        array_push($samples, $sample);
      }
    }
    fclose($f);
    
    // result summary
    if (file_exists("note.html")) {
      require("note.html");
    }
    if (file_exists("user-data/miseq/$jobid/note.html")) {
      require("user-data/miseq/$jobid/note.html");
    }
    
    print "<p class='header3'>Result summary, OTU Table</p>"."\n";
    require("job_report/miseq.php");
    print "<hr>"."\n";

    // output files
    $www_file_url = "/RNA-seq/Data/user-data/miseq";
    $file = "$www_file_url/$jobid/$jobid.tar.gz";

    $size = 0;
    if ($job_file = fopen("user-data/miseq/$jobid/NGS-size", "r")) {
      $size = trim(fgets($job_file));
    }
    #$size = humanFileSize($size);
    print "<p class='header3'>Output files</p>"."\n";
    print "<p>You may download <a href=\"$file\">this gzipped tar file (.tar.gz, $size) </a> that contains all the results.</p>"."\n";
    print "<p>You'd better also check the description of the output files below.</p>"."\n";
    print "<p>Alternatively, you may Browse the directory and files to view or download individual files.</p>"."\n";
    process_this_dir("user-data/miseq/$jobid");
    process_WF_dir("user-data/miseq/$jobid/WF-sh");
    print "<p><button class='fold' onclick=\"if(this.innerHTML=='+'){document.getElementById('readme').style.display='block';this.innerHTML='-';}else{document.getElementById('readme').style.display='none';this.innerHTML='+';}\">+</button>Click to see the description of the output files.</p>"."\n";
    print "<div id='readme' class='sub' style='display:none'>"."\n";
    print "<pre style='font-size: 10pt'>";
    require("job_readme/miseq.html");
    print "</pre>"."\n";
    print '</div>'."\n";
  } else {
    print "<p>Job $jobid doesn't exist, please submit a valid job ID below.</p>";
    print '<form id="jobform" name="jobform" action="job.php" method="GET"><p>Job ID: <input type="text" id="jobid" name="jobid" size="30"> <button type="submit">Submit</button></p></form>'."\n";
  }
?>

</p>

<?php
  require("../includes/jcvi_footer.php");
?>

