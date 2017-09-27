<?php
  // assembly statistics
  $assembly = array("genes" => 0, "transcripts" => 0, "GC" => 0, "N50" => 0);
  foreach (array(0, 1) as $i) {
    foreach (array("N50", "median", "mean", "total") as $j) {
      $assembly[$j.$i] = 0;
    }
  }
  $str2key = array(
    "Total trinity 'genes'" => "genes",
    "Total trinity transcripts" => "transcripts",
    "Percent GC" => "GC",
    "Contig N50" => "N50",
    "Median contig length" => "median",
    "Average contig" => "mean",
    "Total assembled bases" => "total"
  );
  $file = "user-data/RNAseq/$jobid/Trinity_assembly_from_pooled_samples/trinity-pe/Trinity-stat.txt";
  $f = fopen($file, "r") or die ("<p>Cannot read " + basename($file) + ".</p>\n");
  $section = 0;
  while (!feof($f)) {
    $line = trim(fgets($f));
    if ($line === "") continue;
    $a = preg_split('/\s+/', $line);
    if (strpos($line, "Stats based on ALL transcript contigs:") !== false) {
      $section = 1;
    } elseif (strpos($line, "Stats based on ONLY LONGEST ISOFORM per 'GENE':") !== false) {
      $section = 2;
    }
    foreach ($str2key as $key => $value) {
      if (strpos($line, $key) !== false) {
        $x = $value;
        if ($section > 0) {
          $x .= ($section-1);
        }
        $assembly[$x] = end($a);
        break;
      }
    }
  }
  fclose($f);

  print "<p><i>De novo</i> assembly statistics</p>"."\n";
  print "<table><tr>"."\n";
  foreach (array("genes", "transcripts", "GC") as $key) {
    print "<td><b>".ucfirst($key)."</b></td><td style='padding-right:30px'>".strval($assembly[$key])."</td>"."\n";
  }
  print "</tr></table>"."\n";
  print "<p></p>"."\n";
  print "<table>"."\n";
  print "<tr><th width=100px>Transcript</th><th width=100px>All</th><th width=100px>Longest</th></tr>"."\n";
  foreach (array("total", "N50", "median", "mean") as $key) {
    print "<tr><td><b>".ucfirst($key)."</b></td><td>".strval($assembly[$key."0"])."</td><td>".strval($assembly[$key."1"])."</td></tr>"."\n";
  }
  print "</table>"."\n";
  print "<p></p>"."\n";

  require("job_report/edger.php");
?>
