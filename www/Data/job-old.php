<?php
$title = 'Results';
// require("../includes/header.php");
// add header
?>
<div id="maininner">
<div style="width:60%;border:1px solid #777;padding:8px;margin-bottom:20px;color:#555;" class="centered">
<?php
  $jobid = $_GET['jobid'];
  if ( file_exists( "user-data/$jobid/readme.html" ) ) {
    //get job specfic readme file
    $my_job = "default";
    if ($job_file = fopen("user-data/$jobid/NGS-job", "r")) {
      $my_job = trim(fgets($job_file));
    }
    $header = "Your job $my_job (job id: $jobid) is completed. There are a few ways to access the results. But before download, please read the results summary. <HR>";
    print $header;
    require("job_readme/$my_job.html");
    require("user-data/$jobid/readme.html");
  }
  else {
    echo "Job $jobid doesn't exist, please submit the job id below <BR>";
    $jobform = '<form id="jobform" name="jobform" action="job.php" method="GET">Job ID: <input type="text" id="jobid" name="jobid" size="30"><button type="submit">Submit</button></form>'."\n";
    print $jobform;

  }
?>

</div>
</div>
<?php
// require("../includes/footer.php");
?>
