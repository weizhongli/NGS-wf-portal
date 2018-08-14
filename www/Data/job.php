<?php
  require("../includes/jcvi_header.php");
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
  if (file_exists("user-data/RNAseq/$jobid/readme.html")) {
    print "<p>Congratulations! Your job <b>".$jobid."</b> is completed.</p>"."\n";
    print "<p>You may download all workflow results by wget -r http://weizhong-lab.ucsd.edu/RNA-seq/Data/user-data/RNAseq/$jobid. <br>\n";
    print "You can also browse the individual files, at bottom of the page. <br>\n";
    print "If this page takes long time to load, you can view the results with <A href=\"http://weizhong-lab.ucsd.edu/RNA-seq/Data/user-data/RNAseq/$jobid/file-list.html\">this link. </A> <br>";
    print "This server is getting popular, so we can not store big files for long time, old files older than 90 days will be deleted. </p>";
    print "<hr>"."\n";
    
    // job summary
    $jobtype = "default";  // three types by far: tophat-cufflink, trinity, star
    $readtype = "NA";  // pe or se
    $reference = "NA";
    $samples = array();  // (indexed => associative): name, left/right, group
    $groups = array();  // (associative) group ID => sample names
    if ($job_file = fopen("user-data/RNAseq/$jobid/NGS-job", "r")) {
      $line = trim(fgets($job_file));
      $readtype = substr($line, -2);
      $jobtype = substr($line, 3, strlen($line)-6);
    }
  
    $f = fopen("user-data/RNAseq/$jobid/NGS-config", "r");
    while (!feof($f)) {
      $line = trim(fgets($f));
      if ($line === "") continue;
      $a = explode(" ", $line);
      if ($a[0] === "Reference") {
        $reference = basename($a[1]);
      } elseif (substr($a[0], 0, 5) === "Group") {
        $sample = array(
          "left" => basename($a[1]),
          "right" => basename($a[2]),
          "group" => substr($a[0], 5),
          "name" => end($a)
        );
        array_push($samples, $sample);
        if (array_key_exists($sample["group"], $groups)) {
          array_push($groups[$sample["group"]], $sample["name"]);
        } else {
          $groups[$sample["group"]] = array($sample["name"]);
        }
      }
    }
    fclose($f);
    
    print "<p class='header3'>Job summary</p>"."\n";
    print "<table id='job_parameters'>"."\n";
    print "<tr><td><b>Job type</b></td><td style='padding-right:30px'>".$jobtype."</td>";
    print "<td><b>Read type</b></td><td style='padding-right:30px'>".$readtype."</td>";
    print "<td><b>Reference</b></td><td style='padding-right:30px'>".$reference."</td></tr>";
    print "</table>"."\n";
    print "<p></p>"."\n";
    
    // qc reports
    $dirname = "NA";
    if ($jobtype === "tophat-cufflink") {
      $dirname = "qc-".$jobtype."-".$readtype;
      for ($i = 0; $i < count($samples); $i ++) {
        $filepath = "user-data/RNAseq/$jobid/Sample_".str_replace("-", "_", $samples[$i]["name"])."/".$dirname."/qc.stderr";
        if (!file_exists($filepath)) continue;
        $f = fopen($filepath, "r");
        while (!feof($f)) {
          $line = trim(fgets($f));
          if ($line === "") continue;
          if (substr($line, 0, 5) === "Input") {
            $samples[$i]["qc"] = array();
            $a = explode(":", $line);
            array_shift($a);
            foreach ($a as $s) {
              $b = explode(" ", trim($s));
              array_push($samples[$i]["qc"], $b[0]);
            }
          } elseif (substr($line, -22) === "Completed successfully") {
            $samples[$i]["qc_success"] = 1;
          }
        }
        fclose($f);
      }
    } elseif ($jobtype === "trinity") {
      $dirname = "post-".$jobtype."-".$readtype;
      for ($i = 0; $i < count($samples); $i ++) {
        $filepath = "user-data/RNAseq/$jobid/Sample_".str_replace("-", "_", $samples[$i]["name"])."/".$dirname."/qc.stderr";
        if (!file_exists($filepath)) continue;
        $f = fopen($filepath, "r");
        while (!feof($f)) {
          $line = trim(fgets($f));
          if ($line === "") continue;
          if (substr($line, 0, 5) === "Input") {
            $samples[$i]["qc"] = array();
            $a = explode(":", $line);
            array_shift($a);
            foreach ($a as $s) {
              $b = explode(" ", trim($s));
              array_push($samples[$i]["qc"], $b[0]);
            }
          } elseif (substr($line, -22) === "Completed successfully") {
            $samples[$i]["qc_success"] = 1;
          }
        }
        fclose($f);
      }
    } elseif ($jobtype === "star") {
      $dirname = "qc-".$readtype;
      for ($i = 0; $i < count($samples); $i ++) {
        $filepath = "user-data/RNAseq/$jobid/Sample_".str_replace("-", "_", $samples[$i]["name"])."/".$dirname."/qc.stderr";
        if (!file_exists($filepath)) continue;
        $f = fopen($filepath, "r");
        while (!feof($f)) {
          $line = trim(fgets($f));
          if ($line === "") continue;
          if (substr($line, 0, 5) === "Input") {
            $samples[$i]["qc"] = array();
            $a = explode(":", $line);
            array_shift($a);
            foreach ($a as $s) {
              $b = explode(" ", trim($s));
              array_push($samples[$i]["qc"], $b[0]);
            }
          } elseif (substr($line, -22) === "Completed successfully") {
            $samples[$i]["qc_success"] = 1;
          }
        }
        fclose($f);
      }
    } elseif ($jobtype === "hisat-stringtie") {
      $dirname = "qc-".$jobtype."-".$readtype;
      for ($i = 0; $i < count($samples); $i ++) {
        $filepath_1 = "user-data/RNAseq/$jobid/Sample_1_".str_replace("-", "_", $samples[$i]["name"])."/".$dirname."/qc.stderr";
        if (!file_exists($filepath_1)) continue;
          $f = fopen($filepath_1, "r");
          while (!feof($f)) {
          $line = trim(fgets($f));
          if ($line === "") continue;
          if (substr($line, 0, 5) === "Input") {
            $samples[$i]["qc"] = array();
            $a = explode(":", $line);
            array_shift($a);
            foreach ($a as $s) {
              $b = explode(" ", trim($s));
              array_push($samples[$i]["qc"], $b[0]);
            }
          } elseif (substr($line, -22) === "Completed successfully") {
            $samples[$i]["qc_success"] = 1;
          }
        }
        fclose($f);
      }
      for ($i = 0; $i < count($samples); $i ++) {
        $filepath_2 = "user-data/RNAseq/$jobid/Sample_2_".str_replace("-", "_", $samples[$i]["name"])."/".$dirname."/qc.stderr";
        if (!file_exists($filepath_2)) continue;
          $f = fopen($filepath_2, "r");
          while (!feof($f)) {
          $line = trim(fgets($f));
          if ($line === "") continue;
          if (substr($line, 0, 5) === "Input") {
            $samples[$i]["qc"] = array();
            $a = explode(":", $line);
            array_shift($a);
            foreach ($a as $s) {
              $b = explode(" ", trim($s));
              array_push($samples[$i]["qc"], $b[0]);
            }
          } elseif (substr($line, -22) === "Completed successfully") {
            $samples[$i]["qc_success"] = 1;
          }
        }
        fclose($f);
      }
      for ($i = 0; $i < count($samples); $i ++) {
        $filepath_3 = "user-data/RNAseq/$jobid/Sample_3_".str_replace("-", "_", $samples[$i]["name"])."/".$dirname."/qc.stderr";
        if (!file_exists($filepath_3)) continue;
          $f = fopen($filepath_3, "r");
          while (!feof($f)) {
          $line = trim(fgets($f));
          if ($line === "") continue;
          if (substr($line, 0, 5) === "Input") {
            $samples[$i]["qc"] = array();
            $a = explode(":", $line);
            array_shift($a);
            foreach ($a as $s) {
              $b = explode(" ", trim($s));
              array_push($samples[$i]["qc"], $b[0]);
            }
          } elseif (substr($line, -22) === "Completed successfully") {
            $samples[$i]["qc_success"] = 1;
          }
        }
        fclose($f);
      }
      for ($i = 0; $i < count($samples); $i ++) {
        $filepath_4 = "user-data/RNAseq/$jobid/Sample_4_".str_replace("-", "_", $samples[$i]["name"])."/".$dirname."/qc.stderr";
        if (!file_exists($filepath_4)) continue;
          $f = fopen($filepath_4, "r");
          while (!feof($f)) {
          $line = trim(fgets($f));
          if ($line === "") continue;
          if (substr($line, 0, 5) === "Input") {
            $samples[$i]["qc"] = array();
            $a = explode(":", $line);
            array_shift($a);
            foreach ($a as $s) {
              $b = explode(" ", trim($s));
              array_push($samples[$i]["qc"], $b[0]);
            }
          } elseif (substr($line, -22) === "Completed successfully") {
            $samples[$i]["qc_success"] = 1;
          }
        }
        fclose($f);
      }
    }
  
    print "<table id='input_files'>"."\n";
    print "<tr><th width='60px'>Group</th><th width='100px'>Sample</th>";
    if ($readtype === "se") {
      print "<th width='200px'>Input file</th><th width='100px'>Reads</th>";
    } elseif ($readtype === "pe") {
      print "<th width='200px'>Input file (left)</th><th width='200px'>Input file (right)</th><th width='100px'>Read pairs</th>";
    }
    print "<th width='100px'>QC passed</th></tr>"."\n";
    foreach ($samples as $sample) {
      print "<tr><td>".$sample["group"]."</td><td>".$sample["name"]."</td>";
      if ($readtype === "se") {
        print "<td>".$sample["left"]."</td>";
      } elseif ($readtype === "pe") {
        print "<td>".$sample["left"]."</td><td>".$sample["right"]."</td>";
      }
      if (array_key_exists("qc_success", $sample)) {
        print "<td>".$sample["qc"][0]."</td><td>".$sample["qc"][1]."</td>";
      } else {
        print "<td colspan=2>QC failed</td>";
      }
      print "</tr>"."\n";
    }
    print "</table>"."\n";
    print "<hr>"."\n";
  
    // result summary
    if (file_exists("note.html")) {
      require("note.html");
    }
    if (file_exists("user-data/RNAseq/$jobid/note.html")) {
      require("user-data/RNAseq/$jobid/note.html");
    } else {
      $has_results = 1;
      foreach ($samples as $sample) {
        if (!array_key_exists("qc_success", $sample)) $has_results = 0;
      }
      if ($has_results) {
        if (file_exists("job_report/$jobtype.php")) {
          print "<p class='header3'>Result summary</p>"."\n";
          require("job_report/$jobtype.php");
          print "<hr>"."\n";
        }
      }
    }
    
    print "<p class='header3'>Browse files</p>"."\n";
    print "<p>Here, you may Browse the directory and files to view or download individual files.</p>"."\n";
    process_this_dir("user-data/RNAseq/$jobid");
    process_WF_dir("user-data/RNAseq/$jobid/WF-sh");
    print "<p><button class='fold' onclick=\"if(this.innerHTML=='+'){document.getElementById('readme').style.display='block';this.innerHTML='-';}else{document.getElementById('readme').style.display='none';this.innerHTML='+';}\">+</button>Click to see the description of the output files.</p>"."\n";
    print "<div id='readme' class='sub' style='display:none'>"."\n";
    print "<pre style='font-size: 10pt'>";
    require("job_readme/$jobtype.html");
    print "</pre>"."\n";
    print '</div>'."\n";
  } else {
    print "<p>Job $jobid doesn't exist, please submit a valid job ID below.</p>";
    print '<form id="jobform" name="jobform" action="job.php" method="GET"><p>Job ID: <input type="text" id="jobid" name="jobid" size="30"> <button type="submit">Submit</button></p></form>'."\n";
  }
?>

<?php
  require("../includes/jcvi_footer.php");
?>

