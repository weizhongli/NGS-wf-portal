#!/usr/bin/perl
## =========================== NGS tools ==========================================
### NGS tools for metagenomic sequence analysis
### May also be used for other type NGS data analysis
###
###                                      Weizhong Li, UCSD
###                                      liwz@sdsc.edu
### http://weizhongli-lab.org/
### ================================================================================

my $script_name = $0;
my $script_dir = $0;
   $script_dir =~ s/[^\/]+$//;
   $script_dir = "./" unless ($script_dir);
   $script_dir =~ s/\/$//; #### remove last "/"

use Getopt::Std;
use POSIX;

my $sample_file = shift;
my $galaxy_output = shift;
my $R1_len = shift; $R1_len = 150 unless ($R1_len > 50);
my $R2_len = shift; $R2_len = 100 unless ($R2_len > 50);
my $abs = shift;    $abs = 0.0001 unless ($abs >= 0);
my $cutoff = shift; $cutoff = 0.97 unless ($cutoff > 0.9);

my $job_work_dir  = `pwd`; chop($job_work_dir);
my ($i, $j, $k, $ll, $cmd);
my $qsub_no = 0;

my $ref_genome = "";

########## ENV 
$ENV{"PATH"} = "/home/oasis/gordon-data/NGS-ann-project-new/apps/bin:". $ENV{"PATH"};

my $job_file     = "NGS-job";
my $size_file    = "NGS-size";
my $job_id       = random_ID();
my $cdhit_path   = "/home/oasis/gordon-data/NGS-ann-project-new/apps/cd-hit-v4.6.8-2017-0621";
my $gg_path      = "/home/oasis/gordon-data/NGS-ann-project-new/refs/gg_13_5_otus/Greengene-13-5-99.fasta";
my $s3_web_url   = "http://weizhong-lab.ucsd.edu/RNA-seq/Data/download";
my $www_dir      = "/home/oasis/gordon-data/galaxy-user-data/miseq";
my $www_web_url  = "http://weizhong-lab.ucsd.edu/RNA-seq/Data/job_miseq.php";
my $www_file_url = "http://weizhong-lab.ucsd.edu/RNA-seq/Data/user-data/miseq";
my $job_output   = "working/job.html";
my $readme_file  = "readme.html";
my $file_list_file = "file-list.html";
my $files_to_save = "NGS* Sample* WF-sh"; #### a list of files to tar or to store
my $pwd = `pwd`; $pwd =~ s/\n//g;

$cmd = `env > NGS-env`;
$cmd = `grep -P "\\w" $sample_file > $sample_file.1`;
$cmd = `mv -f $sample_file.1 $sample_file`;
$cmd = `sed -i "s/^/Sample_/" $sample_file`;

#################### submit jobs
if (1) {
  $cmd = `head -n 1 $sample_file`; $cmd =~ s/\n//g;
  my ($t_sample, $t_R1, $t_R2) = split(/\s+/, $cmd);

  #### prepare sliced ref
  my $gg_name = "Green-Gene-spliced-ref";
  qsub_n_wait("$cdhit_path/usecases/Miseq-16S/16S-ref-db-PE-splice.pl -i $t_R1 -j $t_R2  -d $gg_path -o $gg_name -p $R1_len -q $R2_len -c 0.99", 4);
  my $gg_R1 = "$pwd/$gg_name-R1";
  my $gg_R2 = "$pwd/$gg_name-R2";

  $cmd = `$cdhit_path/usecases/Miseq-16S/NG-Omics-WF.py -i $cdhit_path/usecases/Miseq-16S/NG-Omics-Miseq-16S.py -s $sample_file -j otu -T otu:$R1_len:$R2_len:$cutoff:$abs:$gg_R1:$gg_R2:75`;
  $cmd = `$cdhit_path/usecases/Miseq-16S/pool_samples.pl -s $sample_file -o Sample_pooled`; 
  $cmd = `$cdhit_path/usecases/Miseq-16S/NG-Omics-WF.py -i $cdhit_path/usecases/Miseq-16S/NG-Omics-Miseq-16S.py -S Sample_pooled -j otu-pooled -T otu-pooled:$R1_len:$R2_len:$cutoff:$abs:$gg_R1:$gg_R2:75`;

  $files_to_save = "NGS* Green* Sample* WF-sh";
}
else {
  exit;
}


open(OUT, "> $job_output") || die "can not write to $job_output";
print OUT <<EOD;
<HTML>
<BODY>
Your job #$job_id is completed. <BR>
You can view the results from
<A href="$www_web_url?jobid=$job_id" target="_OTU_MiSeq">here, (it opens a new window or a new tab)</A>.
<P>
</BODY>
</HTML>
EOD
close(OUT);


#################### create index file
open(OUT, "> $readme_file") || die "can not write to $readme_file";
print OUT <<EOD;
<h2>Download results</h2>
<OL>
  <LI>Browse the directory and files from <A href="$www_file_url/$job_id/$file_list_file">file list page</A> to view or download individual files.
  <LI>If you are Linux / MacOS user, you can batch download the job directory with command such as "wget -r $www_file_url/$job_id".
</OL>
EOD
close(OUT);

#################### copy to www
$cmd = `mkdir -p $www_dir/$job_id`;
$cmd = `rsync -av $readme_file $files_to_save $www_dir/$job_id`;
chdir("$www_dir/$job_id");
$cmd = `$script_dir/NGS-wf-galaxy-html-ls.pl . > $file_list_file`;
$cmd = `tar czf $job_id.tar.gz $files_to_save`;
$cmd = `du -h $job_id.tar.gz`; 
my $size = (split(/\s+/,$cmd))[0];
$cmd = `echo $size > $size_file`;
chdir($job_work_dir);

#################### END, after this Galaxy will clean up data

################################################################################
################################################################################
################################################################################
sub qsub_n_wait {
  my ($i, $j, $k, $ll, $cmd);
  my ($command, $pe_no) = @_;
  my $pwd = `pwd`; chop($pwd);
  $cmd = `mkdir WF-sh` unless (-e "WF-sh");

  my $sh_f       = "$pwd/WF-sh/$$.$qsub_no.sh"; $qsub_no++;
  my $f_start    = "$sh_f.WF.start.date";
  my $f_complete = "$sh_f.WF.complete.date";
  my $f_cpu      = "$sh_f.WF.cpu";

  open(TSH, "> $sh_f") || die "can not write to $sh_f";
  print TSH <<EOD;
#!/bin/sh
#\$ -v PATH
#\$ -V
#\$ -q RNA.q
#\$ -pe orte $pe_no
#\$ -e $sh_f.err
#\$ -o $sh_f.out
#\$ -N galaxy


cd $pwd
if ! [ -f $f_start ]; then date +\%s > $f_start;  fi

$command

date +\%s > $f_complete
times >> $f_cpu

EOD
  close(TSH);

  $cmd = `qsub $sh_f`;
  my $qsub_id = 0;
  if ($cmd =~ /(\d+)/) { $qsub_id = $1;} else {die "can not submit qsub job and return a id\n";}

  my $sleep_t = 30;
  while(1) {
    sleep($sleep_t);
    $cmd = `qstat -j $qsub_id | grep job_number`;
    last unless ($cmd =~ /$i/);
    $sleep_t *=2;
    $sleep_t = 120 if ($sleep_t > 120);
  }

  return;
}
########## END sub qsub_n_wait

sub random_ID{
   my $id0 = int(rand() * 1000000);
   my $id1 = `date +%C%y%m%d%H%M%S`; chop($id1);
   my $sid = $id1 . sprintf("%6s",$id0) . sprintf("%6s",$$); $sid =~ s/ /0/g;
   return $sid;
}
########## END random_ID

########## END qsub_n_wait
