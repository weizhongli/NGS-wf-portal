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
getopts("i:o:x:y:a:c:r:U:",\%opts);
die usage() unless ($opts{i} and $opts{o});

my $sample_file   = $opts{i};
my $galaxy_output = $opts{o};
my $R1_len        = $opts{x}; $R1_len = 150 unless ($R1_len > 50);
my $R2_len        = $opts{y}; $R2_len = 100 unless ($R2_len > 50);
my $abs           = $opts{a}; $abs = 0.0001 unless ($abs >= 0);
my $cutoff        = $opts{c}; $cutoff = 0.97 unless ($cutoff > 0.9);
my $refdb         = $opts{r}; $refdb = "Greengene" unless ($refdb);
my $fetch_data    = $opts{U}; 

my $job_work_dir  = `pwd`; chop($job_work_dir);
my ($i, $j, $k, $ll, $cmd);
my $qsub_no = 0;

my $ref_genome = "";

########## ENV 
$ENV{"PATH"} = "/data5/data/NGS-ann-project/apps/bin:". $ENV{"PATH"};

my $job_file     = "NGS-job";
my $size_file    = "NGS-size";
my $job_id       = random_ID();
my $sratool_path = "/data5/data/NGS-ann-project/apps/sratoolkit/bin";
my $cdhit_path   = "/data5/data/NGS-ann-project/apps/cd-hit";
my $gg_path      = "/data5/data/NGS-ann-project/refs/greengene/Greengene-13-8-99.fasta";
my $www_dir      = "/data5/data/galaxy-user-data/miseq";
my $www_web_url  = "http://weizhong-lab.ucsd.edu/RNA-seq/Data/job_miseq.php";
my $www_file_url = "http://weizhong-lab.ucsd.edu/RNA-seq/Data/user-data/miseq";
my $s3_web_url   = "http://weizhong-lab.ucsd.edu/RNA-seq/Data/download";
my $job_output   = "working/job.html";
my $readme_file  = "readme.html";
my $file_list_file = "file-list.html";
my $files_to_save = "NGS* $refdb* Sample* WF-sh *html"; #### a list of files to tar or to store

if ($refdb eq "SILVA") {
  $gg_path = "/data5/data/NGS-ann-project/refs/silva/SILVA_132_SSURef_processed.fasta";
}
$cmd = `env > NGS-env`;
$cmd = `grep -P "\\w" $sample_file > $sample_file.1`;
$cmd = `mv -f $sample_file.1 $sample_file`;
$cmd = `sed -i "s/__cn__/\\n/g" $sample_file`; #### for text area input, galaxy changed \n to __cn__, change it back
$cmd = `sed -i "s/^/Sample_/" $sample_file`;

#################### copy to www
$cmd = `mkdir -p $www_dir/$job_id`;
$cmd = `rsync -av NGS* $www_dir/$job_id`;

################### move to www_dir, working directory
chdir("$www_dir/$job_id");
open(LOG, "> NGS-log") || die "can not write to NGS-log";

if ($fetch_data) {
  fetch_data($sample_file);
}

#################### submit jobs
if (1) {
  $cmd = `head -n 1 $sample_file`; $cmd =~ s/\n//g;
  my ($t_sample, $t_R1, $t_R2) = split(/\s+/, $cmd);

  #### prepare sliced ref
  my $gg_name = "$refdb-spliced";
  qsub_n_wait("$cdhit_path/usecases/Miseq-16S/16S-ref-db-PE-splice.pl -i $t_R1 -j $t_R2  -d $gg_path -o $gg_name -p $R1_len -q $R2_len -c 0.99", 4);
  my $pwd = `pwd`; $pwd =~ s/\n//g;
  my $gg_R1 = "$pwd/$gg_name-R1";
  my $gg_R2 = "$pwd/$gg_name-R2";

  nice_run("$cdhit_path/usecases/Miseq-16S/NG-Omics-WF.py -i $cdhit_path/usecases/Miseq-16S/NG-Omics-Miseq-16S.py -s $sample_file -j otu -T otu:$R1_len:$R2_len:$cutoff:$abs:$gg_R1:$gg_R2:75");
  nice_run("$cdhit_path/usecases/Miseq-16S/pool_samples.pl -s $sample_file -o Sample_pooled"); 
  nice_run("$cdhit_path/usecases/Miseq-16S/NG-Omics-WF.py -i $cdhit_path/usecases/Miseq-16S/NG-Omics-Miseq-16S.py -S Sample_pooled -j otu-pooled -T otu-pooled:$R1_len:$R2_len:$cutoff:$abs:$gg_R1:$gg_R2:75");

}
else {
  exit;
}
close(LOG);


chdir($job_work_dir);

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
chdir("$www_dir/$job_id");
open(OUT, "> $readme_file") || die "can not write to $readme_file";
print OUT <<EOD;
<h2>Download results</h2>
<OL>
  <LI>Browse the directory and files from <A href="$www_file_url/$job_id/$file_list_file">file list page</A> to view or download individual files.
  <LI>If you are Linux / MacOS user, you can batch download the job directory with command such as "wget -r $www_file_url/$job_id".
</OL>
EOD
close(OUT);

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
sub nice_run {
  my $command  = shift;
  print STDERR "running $command\n";
  print LOG "$command\n";
  my $cmd = `$command`;
}

sub qsub_n_wait {
  my ($i, $j, $k, $ll, $cmd);
  my ($command, $pe_no) = @_;
  my $pwd = `pwd`; chop($pwd);

  print STDERR "qsub following command on $pe_no cores\n$command\n";
  print LOG    "qsub following command on $pe_no cores\n$command\n";

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
#\$ -q all.q
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

sub fetch_data {
  my $sample_file = shift;
  my $sample_file_tmp = "$sample_file.$$";
  my $fq_dump_exe = "$sratool_path/fastq-dump";

  my ($i, $j, $k, $ll, $cmd, $p);
  my $down_dir = "URL";
  $cmd = `mkdir $down_dir`;
  $p = `pwd -P $down_dir`; chop($p);

  open(OUT, "> $sample_file_tmp") || die "can not write to $sample_file_tmp";
  open(SAM, $sample_file) || die "can not open $sample_file";
  while($ll = <SAM>) {
    chop($ll);
    next unless ($ll =~ /^\S/);
    my @lls = split(/\s+/, $ll);
    if ($lls[1] =~ /^SRR/) { #### SRA download

      my $acc = $lls[1];
      $cmd = `$fq_dump_exe --accession $acc --split-files --outdir $down_dir`;
      my $r1 = "$p/$acc". "_1.fastq";      
      my $r2 = "$p/$acc". "_2.fastq";      
      ((-e $r1) and (-e $r2)) || die "can not download $acc";
      print OUT "$lls[0]\t$r1\t$r2\n";
    }
    elsif ((($lls[1] =~ /^ftp:/  ) and ($lls[2] =~ /^ftp:/  )) or 
           (($lls[1] =~ /^http:/ ) and ($lls[2] =~ /^http:/ )) or 
           (($lls[1] =~ /^https:/) and ($lls[2] =~ /^https:/)) ) {
      my $r1 = "$p/$lls[0]-R1.fastq";      
      my $r2 = "$p/$lls[0]-R2.fastq";      
      $cmd = `wget -O $r1 $lls[1]`;
      $cmd = `wget -O $r2 $lls[2]`;
      ((-e $r1) and (-e $r2)) || die "can not download $lls[1] and $lls[2]";
      print OUT "$lls[0]\t$r1\t$r2\n";
    }
    else {
      die "error, sample download url format error\n";
    }
  }
  close(SAM);
  close(OUT);

  $cmd = `mv -f $sample_file $sample_file.url`;
  $cmd = `mv -f $sample_file_tmp $sample_file`;
}


sub usage {
<<EOD
NGS portal Miseq 16S run script

usage:
  $script_name -i NGS-sample -o output -x R1_trim_len -y R2_trim_len -a abundance_cutoff -c clustering_cutoff -r refdb

  options
    -i NGS-sample file
    -o output
    -x length to trim R1 reads, default 150
    -y length to trim R2 reads, default 100
    -a abundance cutoff, default 0.0001
    -c OTU clustering cutoff, default 0.97
    -r reference DB, default Greengene
    -U fetch fastq from SRA, or from URL, default 0
EOD
}
########## END qsub_n_wait
