<?php

  // DE genes and transcripts
  $dir = "user-data/RNAseq/$jobid/Sample-all-transcript-matrix-group/post-RSEM-group";
  if (is_dir($dir)) {
    $file = $dir."/trans-diff/trans-diff.matrix";
    if (file_exists($file)) {
      $sams = array();
      $trans = array();
      $f = fopen($file, "r");
      while (!feof($f)) {
        $line = rtrim(fgets($f));
        if ($line === "") continue;
        $a = preg_split('/\s+/', $line);
        if ($a[0] === "") {
          foreach (array_slice($a, 1) as $x) {
            if (substr($x, 0, 7) === "Sample_") {
              $x = substr($x, 7);
            }
            array_push($sams, $x);
          }
        } else {
          array_push($trans, $a);
        }
      }
      fclose($f);
      
      // FDR
      $vss = array();
      $files = scandir($dir."/trans-diff");
      sort($files);
      foreach ($files as $file) {
        if ((substr($file, 0, 20) === "trans.counts.matrix.") && (substr($file, -11) === ".DE_results")) {
          $a = explode(".", $file);
          $a = explode("_", $a[3]);
          array_push($vss, substr($a[0], 5)."-".substr($a[2], 5));
          $c = count($trans[0]);
          $f = fopen($dir."/trans-diff/".$file, "r");
          while (!feof($f)) {
            $line = trim(fgets($f));
            if ($line === "") continue;
            $a = explode("\t", $line);
            if ($a[0] === "logFC") continue;
            for ($i=0; $i<count($trans); $i++) {
              if ($trans[$i][0] === $a[0]) {
                array_push($trans[$i], end($a));
              }
            }
          }
          fclose($f);
          for ($i=0; $i<count($trans); $i++) {
            if (count($trans[$i]) === $c) {
              array_push($trans[$i], "NA");
            }
          }
        }
      }
      
      print "<p><span style='cursor:help' title='Cutoffs: FDR <= 0.001, log2 fold-change >= 2'>Significant differential expressions</span></p>"."\n";
      if (count($trans) > 10) {
        print "<div style='overflow:auto;height:240px;margin-right:10px;'>"."\n";
      } else {
        print "<div style='overflow-x:auto;margin-right:10px;'>"."\n";
      }
      print "<table id='significant_results'>"."\n";
      print "<tr><th width='120px' rowspan=2>Transcript</th>";
      print "<th colspan=".strval(count($sams))." style='text-align:center;cursor:help' title='Fragments Per Kilobase of transcript per Million mapped reads'>FPKM</th>";
      print "<th colspan=".strval(count($vss))." style='text-align:center;cursor:help' title='False Discovery Rate'>FDR</th>";
      print "</tr>"."\n";
      print "<tr>";
      foreach ($sams as $sam) {
        print "<th width='80px'>".$sam."</th>";
      }
      foreach ($vss as $vs) {
        $g = explode("-", $vs);
        print "<th width='75px'>".$g[0]." vs ".$g[1]."</th>";
      }
      print "</tr>"."\n";
      foreach ($trans as $tran) {
        print "<tr>";
        $i = 0;
        foreach ($tran as $x) {
          if ($i === 0 || $x === "NA") {
            print "<td>".$x."</td>";
          } elseif ($i <= count($sams)) {
            print "<td>".sprintf("%.3g", $x)."</td>";
          } else {
            $red = intval(175*(1-$x/0.001))+80;
            print "<td";
            if ($x <= 0.001) {
              print " style='color:rgb($red,85,89)'";
            }
            print ">".sprintf("%.3g", $x)."</td>";
          }
          $i ++;
        }
        print "</tr>"."\n";
      }
      print "</table>"."\n";
      print "</div>"."\n";
    } else {
      print "<p>No significant differential expression is found.</p>"."\n";
    }
  } else {
    print "<p>No differential expression detection result is available.</p>"."\n";
  }
?>
