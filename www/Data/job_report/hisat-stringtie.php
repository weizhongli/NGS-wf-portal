<?php
  $vss = array();  // comparisons between groups
  $files = scandir("user-data/RNAseq/$jobid");
  sort($files);
  foreach ($files as $file) {
    if (substr($file, 0, 5) === "Group") {
      $a = explode("_", $file);
      array_push($vss, substr($a[0], 5)."-".substr($a[2], 5));
    }
  }
  
  $fts = array();  // features (cds, gene, promoter, splicing, etc)
  foreach ($vss as $vs) {
    $g = explode("-", $vs);
    $files = scandir("user-data/RNAseq/$jobid/Group".$g[0]."_vs_Group".$g[1]."");
    foreach ($files as $file) {
      if (substr($file, -17) === "genes_results.txt") { // only shows gene_exp.diff by Yuan
        $fttype = substr($file, 0, strlen($file)-13);
        $f = fopen("user-data/RNAseq/$jobid/Group".$g[0]."_vs_Group".$g[1]."/".$file, "r");
        $read_in = 0;
        while (!feof($f)) {
          $line = trim(fgets($f));
          if ($line === "") continue;
          $a = explode("\t", $line);
          if ($a[0] === "\"feature\"") continue;
          if ($a[4] <0.05) {  // significant
            $found = 0;
            for ($i = 0; $i < count($fts); $i++) {
              if ($fts[$i]["gene"] === $a[1] && $fts[$i]["type"] === $fttype) {
#                if ($fts[$i][$vs] === "NA") {
                  $fts[$i][$vs] = $a[4];
#                  $fts[$i]["g".$g[0]] = $a[2];
#                  $fts[$i]["g".$g[1]] = $a[3];
#                }
                $found = 1;
                break;
              }
            }
            if (!$found) {
              $ft = array("gene" => $a[1], "type" => $fttype, $vs => $a[4]);
#              foreach ($groups as $group => $x) {
#                if ($group == $g[0]) {
#                  $ft["g".$g[0]] = $a[2];
#                } elseif ($group == $g[1]) {
#                  $ft["g".$g[1]] = $a[3];
#                } else {
#                  $ft["g".$group] = "NA";
#                }
#              }
              foreach ($vss as $vs0) {
                if ($vs !== $vs0) {
                  $ft[$vs0] = "NA";
                }
              }
              array_push($fts, $ft);
            }
            // liwz 
            $read_in++;
            if ($read_in > 1000) {break;}
          }
        }
      }
    }
    fclose($f);
  }
  
  if (empty($fts)) {
    print "<p>No significant differential expression is found.</p>"."\n";
    return;
  }
  
  // sort by most significant q-value
  for ($i = 0; $i < count($fts); $i++) {
    $a = array();
    foreach ($vss as $vs) {
      if ($fts[$i][$vs] !== "NA") {
        array_push($a, $fts[$i][$vs]);
      }
    }
    $fts[$i]["most"] = min($a);
  }
  foreach ($fts as $key => $row) {
    $most[$key]  = $row["most"];
  }
  array_multisort($most, SORT_ASC, $fts);

  // liwz
  // $fts = array_slice($fts, 0, 500);

  print "<p><span style='cursor:help' title='Cutoff: Q-value <= 0.05. Sorted by lowest Q-value.'>Significant genes with differential expressions, up to 1000 hits shown. </span></p>"."\n";
  if (count($fts) > 10) {
    print "<div style='overflow:auto;height:240px;margin-right:10px;'>"."\n";
  } else {
    print "<div style='overflow-x:auto;margin-right:10px;'>"."\n";
  }
  print "<table id='significant_results'>"."\n";
  print "<tr><th width='120px' rowspan=2>Gene</th><th width='80px' rowspan=2>Type</th>";
#  print "<th colspan=".strval(count($groups))." style='text-align:center;cursor:help' title='Fragments Per Kilobase of transcript per Million mapped reads'>FPKM</th>";
  print "<th colspan=".strval(count($vss))." style='text-align:center'>Q-value</th></tr>"."\n";
  print "<tr>";
#  foreach ($groups as $group => $x) {
#    print "<th width='75px'>Group ".$group."</th>";
#  }
  foreach ($vss as $vs) {
    $g = explode("-", $vs);
    print "<th width='75px'>".$g[0]." vs ".$g[1]."</th>";
  }
  print "</tr>"."\n";
  foreach ($fts as $ft) {
    print "<tr><td>".$ft["gene"]."</td><td>".$ft["type"]."</td>";
#    foreach ($groups as $group => $x) {
#      print "<td>".$ft["g".$group]."</td>";
#    }
    foreach ($vss as $vs) {
      if ($ft[$vs] === "NA") {
        print "<td>NA</td>";
      } else {
        $red = intval(175*(1-$ft[$vs]/0.05))+80;
        print "<td style='color:rgb($red,85,89)'>".sprintf("%.3g", $ft[$vs])."</td>";
        // rgb(80, 85, 89) #505559 is the default JCVI color.
     }
    }
    print "</tr>"."\n";
  }
  print "</table>"."\n";
  print "</div>"."\n";
?>
