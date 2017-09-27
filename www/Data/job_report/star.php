<?php
  // assembly statistics
  $asstats = array();
  $key2value = array(
    "input" => "Number of input reads",
    "unique" => "Uniquely mapped reads number",
    "multiple" => "Number of reads mapped to multiple loci",
    "toomany" => "Number of reads mapped to too many loci",
    "splices" => "Number of splices: Total",
    "annotated" => "Number of splices: Annotated (sjdb)",
    "mismatch" => "Mismatch rate per base, %",
    "deletion" => "Deletion rate per base",
    "insertion" => "Insertion rate per base"
  );
  foreach ($samples as $sample) {
    $stats = array("name" => $sample["name"]);
    $filename = str_replace("-", "_", $sample["name"]);
    $f = fopen("user-data/RNAseq/$jobid/Sample_".$filename."/qc-star-".$readtype."-2nd-pass/starLog.final.out", "r");
    while (!feof($f)) {
      $line = trim(fgets($f));
      if ($line === "") continue;
      $a = explode("|", $line);
      if (count($a) != 2) continue;
      $a[0] = trim($a[0]);
      $a[1] = trim($a[1]);
      // print "<p>".$sample["name"].": ".$a[1]."</p>"."\n";
      foreach ($key2value as $key => $value) {
        if ($a[0] === $value) {
          $stats[$key] = $a[1];
          break;
        }
      }
    }
    fclose($f);
    array_push($asstats, $stats);
  }
  print "<p>Statistics of mapped reads</p>"."\n";
  print "<table id='assembly_stats'>"."\n";
  $columns = array("unique", "multiple", "splices", "annotated");
  print "<tr><th width='100px'>Sample</th>";
  foreach ($columns as $x) {
    print "<th width='100px'>".ucfirst($x)."</th>";
  }
  print "</tr>"."\n";
  foreach ($asstats as $sample) {
    print "<tr><td>".$sample["name"]."</td>";
    foreach ($columns as $x) {
      print "<td>".$sample[$x]."</td>";
    }
    print "</tr>"."\n";
  }
  print "</table>"."\n";
  print "<p></p>"."\n";

  require("job_report/edger.php");
?>
