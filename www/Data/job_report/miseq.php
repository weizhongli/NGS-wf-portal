<?php
// $jobid = $_GET['jobid'];

  $dir = "user-data/miseq/$jobid/Sample_pooled";
  $file = $dir."/OTU.txt";
  if (file_exists($file)) {
    print "<div style='overflow:auto;height:240px;margin-right:10px;'>"."\n";
    print "<table id='OTU_table'>"."\n";

    $sams = array();
    $trans = array();

    $line_no = 0;
    $f = fopen($file, "r");

    while (!feof($f)) {
      $line = rtrim(fgets($f));
      if ($line === "") continue;

      $a = preg_split('/\t/', $line);
      print "<tr>";

      foreach ($a as $ele) {
        if ($line_no == 0) {
          print "<th>$ele</th>";
        }
        else {
          print "<td>$ele</td>";
        }
      }
      print "</tr>\n";
      $line_no++;
    }
    fclose($f);
    print "</table>"."\n";
    print "</div>"."\n";
    
  }
?>
