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

my $config_file = shift;
my $galaxy_job  = shift; 
my $galaxy_output = shift;

my $job_work_dir  = `pwd`; chop($job_work_dir);
my ($i, $j, $k, $ll, $cmd);
my $qsub_no = 0;

my $ref_genome = "";

########## ENV 
$ENV{"PATH"} = "/home/oasis/gordon-data/NGS-ann-project-new/apps/bin:". $ENV{"PATH"};

my $sample_file = "NGS-samples";
my $sh_file     = "NGS-sh";
my $job_file    = "NGS-job";
my $size_file   = "NGS-size";
my $job_id      = random_ID();
my $s3_path     = "/home/oasis/gordon-data/www/home/RNA-seq/Data/download";
my $s3_web_url  = "http://weizhong-lab.ucsd.edu/RNA-seq/Data/download";
my $www_dir     = "/home/oasis/gordon-data/galaxy-user-data/RNA-seq";
my $www_web_url = "http://weizhong-lab.ucsd.edu/RNA-seq/Data/job.php";
my $www_file_url = "http://weizhong-lab.ucsd.edu/RNA-seq/Data/user-data";
my $job_output  = "working/job.html";
my $readme_file  = "readme.html";
my $file_list_file = "file-list.html";
my $files_to_save = "NGS* Sample* WF-sh"; #### a list of files to tar or to store
my $PE_read       = 0;

open(TMP, $config_file)     || die "can not open $config_file";
open(SMP, ">$sample_file")  || die "can not write to $sample_file";
while($ll=<TMP>){
  next if ($ll =~ /^#/);
  chop($ll);
  if ($ll =~ /^Read\s+PE/        ) { $PE_read = 1;}
  if ($ll =~ /^Read\s+SE/        ) { $PE_read = 0;}
  if ($ll =~ /^Reference\s+(\S+)/) { $ref_genome = $1; }
  last if ($ll =~ /^Samples/);
}

my %sample_2_R1   = ();
my %sample_2_R2   = ();
my %sample_2_group = ();
my @groups = ();
my %group_2_samples = ();
my $num_groups = 0;
my @samples       = ();
my %sample_des    = ();
my $num_samples = 0;

my $sample_id = 1;
while($ll=<TMP>){
  next if ($ll =~ /^#/);
  chop($ll);
  if ($ll =~ /^(Group\d+)/) {
    my $group = $1;
    my $sample_name = "Sample_$sample_id";
    my ($t, $R1, $R2, $sample_des);
    if ($PE_read) {
       ($t, $R1, $R2, $sample_des) = split(/\s+/, $ll, 4); #### in case if $name has spaces
    }
    else {
       ($t, $R1,      $sample_des) = split(/\s+/, $ll, 3); #### in case if $name has spaces
    }
    $sample_des =~ s/\s+//g; $sample_des =~ s/\W/_/g;
    if ( ($sample_des =~ /\w+/) and (not defined($sample_des{$sample_des}))) {
      $sample_des{$sample_des} = 1;
      $sample_name = "Sample_$sample_des";
    }
    if    ($PE_read   ) { print SMP "$sample_name $R1 $R2\n"; $sample_2_R1{$sample_name} = $R1; $sample_2_R2{$sample_name} = $R2;}
    else                { print SMP "$sample_name $R1\n";     $sample_2_R1{$sample_name} = $R1; }

    if (not defined( $group_2_samples{$group} )) { $group_2_samples{$group} = []; }
    push(@{ $group_2_samples{$group}}, $sample_name);
    $sample_2_group{$sample_name} = $group;
    push(@samples, $sample_name);
    $cmd = `mkdir $sample_name`;
    $sample_id++;
  }
}
close(TMP);
close(SMP);
@groups = sort keys %group_2_samples;
$num_groups = $#groups+1;
$num_samples = $#samples+1;

$cmd = `env > NGS-env`;
$cmd = `echo "$galaxy_job" > $job_file`;



################### copy to www_dir
#################### copy to www
$cmd = `mkdir -p $www_dir/$job_id`;
$cmd = `rsync -av NGS* $www_dir/$job_id`;
chdir("$www_dir/$job_id");


#################### submit jobs
if (($galaxy_job eq "qc-tophat-cufflink-se") or ($galaxy_job eq "qc-tophat-cufflink-pe")   ) {
  my $assembly_f = "assembly.txt";
  my $assembly_dir = "Merged_transcripts_from_all_samples";
  my $assembly_gtf = "$job_work_dir/$assembly_dir/cuffmerge/merged.gtf";

 #$cmd = `$script_dir/NGS-wf-galaxy.pl -s NGS-samples -i $script_dir/NGS-wf-galaxy-RNAseq-config.pl -j $galaxy_job -t $opt_file;`;
  $cmd = `$script_dir/NGS-wf-galaxy.pl -s NGS-samples -i $script_dir/NGS-wf-galaxy-RNAseq-config.pl -j $galaxy_job -T $ref_genome.gtf:$ref_genome`;
  $cmd = `mkdir -p $assembly_dir`;
  $cmd = `find $job_work_dir -name transcripts.gtf > $assembly_dir/$assembly_f`; #### with $job_work_dir to use full path
  $cmd = `$script_dir/NGS-wf-galaxy.pl -S $assembly_dir -i $script_dir/NGS-wf-galaxy-RNAseq-config.pl -j cuffmerge -T $ref_genome.gtf:$ref_genome.fa:$assembly_f`;

  #### pairwise diff
  my @pairs = ();
  for ($i=0; $i<$num_groups-1; $i++) {
    my $gi = $groups[$i];
    my $bami = join(",", map{ "$job_work_dir/$_/$galaxy_job/tophat/accepted_hits.bam" } @{ $group_2_samples{$gi} });
    for ($j=$i+1; $j<$num_groups; $j++) {
      my $gj = $groups[$j];
      my $bamj = join(",", map{ "$job_work_dir/$_/$galaxy_job/tophat/accepted_hits.bam" } @{ $group_2_samples{$gj} });
      my $pair = $gi . "_vs_" . $gj;
      $cmd = `$script_dir/NGS-wf-galaxy.pl -S $pair -i $script_dir/NGS-wf-galaxy-RNAseq-config.pl -j cuffdiff -T $ref_genome.fa:$assembly_gtf:$bami:$bamj`;
      push(@pairs, $pair);
    }
  }

  my $group_str = join(" ", @pairs);
  $files_to_save = "NGS* Sample* $group_str WF-sh $assembly_dir";
} ########### END if (($galaxy_job eq "qc-tophat-cufflink-se") or ($galaxy_job eq "qc-tophat-cufflink-pe")   )

elsif (($galaxy_job eq "qc-trinity-se") or ($galaxy_job eq "qc-trinity-pe") ) {
  my $pool_asm_dir = "Trinity_assembly_from_pooled_samples";
  my $R1_group = join(",", map{$sample_2_R1{$_}} @samples);
  my $R2_group = join(",", map{$sample_2_R2{$_}} @samples);
  my $ipe      = ($PE_read) ? "trinity-pe" : "trinity-se";

  #### subset to max 100 000 000 reads
  if (1) {
    my %seq_count = ();
    my $total_seq = 0;
    my $idx;
    for ($idx=0; $idx<$num_samples; $idx++) {
      my $tf = $sample_2_R1{ $samples[$idx] };
      my $c = `grep -c . $tf`; $c =~ s/\D//g; $c = $c / 4;
      $seq_count[$idx] = $c;
      $total_seq += $c;
    }
    if ($total_seq > 10000000) {
      my $r = 100000000 / $total_seq;
      my @new_f1s = ();
      my @new_f2s = ();
      for ($idx=0; $idx<$num_samples; $idx++) {
        my $tf1 = $sample_2_R1{ $samples[$idx] };
        my $tf2 = $sample_2_R1{ $samples[$idx] };
        my $c = $seq_count[$idx];
           $c = int( $c * $r) * 4;
        my $new_f1 = "file.$idx-R1";
        my $new_f2 = "file.$idx-R2";
        my $cmd = `head -n $c $tf1 > $new_f1`;
           $cmd = `head -n $c $tf2 > $new_f2` if ($PE_read);
        push(@new_f1s, $new_f1);
        push(@new_f2s, $new_f2);
      }
      $R1_group = join(",", @new_f1s);
      $R2_group = join(",", @new_f2s);
    }
  }

  #### run Trinity on pooled reads, and prepare index for RESM
  if ($PE_read) { $cmd = `$script_dir/NGS-wf-galaxy.pl -S $pool_asm_dir -i $script_dir/NGS-wf-galaxy-RNAseq-config.pl -j $ipe -T $R1_group:$R2_group`; }
  else          { $cmd = `$script_dir/NGS-wf-galaxy.pl -S $pool_asm_dir -i $script_dir/NGS-wf-galaxy-RNAseq-config.pl -j $ipe -T $R1_group`; }

  #### transcript annotation by blast against ref
  if ($ref_genome ne "/home/oasis/gordon-data/NGS-ann-project-new/refs/ensembl-genomes/noref") { $cmd = `$script_dir/NGS-wf-galaxy.pl -S $pool_asm_dir -i $script_dir/NGS-wf-galaxy-RNAseq-config.pl -j compare-trinity-to-ref -T $ipe/Trinity.fasta:$ref_genome.cdna`; } 

  #### run post trinity RSEM
  $cmd = `$script_dir/NGS-wf-galaxy.pl -s NGS-samples -i $script_dir/NGS-wf-galaxy-RNAseq-config.pl -j post-$ipe -T ../$pool_asm_dir/$ipe/Trinity.fasta`; 

  #### remove index files for RSEM
  $cmd = `rm -f $pool_asm_dir/*/Trinity.fasta.bowtie*`;
  $cmd = `rm -f $pool_asm_dir/*/Trinity.fasta.RSEM*`;

  #### run Identification and Analysis of Differentially Expressed Trinity Genes and Transcripts
  #### run sample pairwise
  my $RSEM_transcripts = join(" ", map{ "$job_work_dir/$_/RSEM.isoforms.results" } @samples);
  my $RSEM_genes       = join(" ", map{ "$job_work_dir/$_/RSEM.genes.results" } @samples);
  $cmd = `$script_dir/NGS-wf-galaxy.pl -S Sample-all-transcript-matrix -i $script_dir/NGS-wf-galaxy-RNAseq-config.pl -j post-RSEM -T "$RSEM_transcripts":"$RSEM_genes"`; #### NOTE with space

  #### run group pairwise
  if ($num_groups > 1) {
    my $sample_txt = "$job_work_dir/Sample_group.txt";
    open(GRP, "> $sample_txt") || die "can not open $sample_txt";
    for ($i=0; $i<$num_groups; $i++) {
      my $gi = $groups[$i];
      foreach my $t_sample (  @{ $group_2_samples{$gi} } ) {
        print GRP "$gi\t$t_sample\n";
      }
    }
    close(GRP);
    $cmd = `$script_dir/NGS-wf-galaxy.pl -S Sample-all-transcript-matrix-group -i $script_dir/NGS-wf-galaxy-RNAseq-config.pl -j post-RSEM-group -T "$RSEM_transcripts":"$RSEM_genes":$sample_txt`; #### NOTE with space
  }

  $files_to_save = "NGS* Sample* WF-sh $pool_asm_dir";
}
elsif (($galaxy_job eq "qc-star-se") or ($galaxy_job eq "qc-star-pe")   ) {
  #first pass
  $cmd = `$script_dir/NGS-wf-galaxy.pl -s NGS-samples -i $script_dir/NGS-wf-galaxy-RNAseq-config.pl -j $galaxy_job -T $ref_genome-STAR`;

  #multiple sample second pass
  $cmd = `find $job_work_dir -name starSJ.out.tab`; $cmd =~ s/\n/ /g; $cmd =~ s/\s+$//; $cmd =~ s/^\s+//;
  my $SJ_str = $cmd;
  $cmd = `$script_dir/NGS-wf-galaxy.pl -s NGS-samples -i $script_dir/NGS-wf-galaxy-RNAseq-config.pl -j $galaxy_job-2nd-pass -T $ref_genome-STAR:"$SJ_str":$ref_genome-RSEM`;

  my $RSEM_transcripts = join(" ", map{ "$job_work_dir/$_/RSEM.isoforms.results" } @samples);
  my $RSEM_genes       = join(" ", map{ "$job_work_dir/$_/RSEM.genes.results" } @samples);
  #### run group pairwise
  if ($num_groups > 1) {
    my $sample_txt = "$job_work_dir/Sample_group.txt";
    open(GRP, "> $sample_txt") || die "can not open $sample_txt";
    for ($i=0; $i<$num_groups; $i++) {
      my $gi = $groups[$i];
      foreach my $t_sample (  @{ $group_2_samples{$gi} } ) {
        print GRP "$gi\t$t_sample\n";
      }
    }
    close(GRP);
    $cmd = `$script_dir/NGS-wf-galaxy.pl -S Sample-all-transcript-matrix-group -i $script_dir/NGS-wf-galaxy-RNAseq-config.pl -j post-RSEM-group -T "$RSEM_transcripts":"$RSEM_genes":$sample_txt`; #### NOTE with space
  }

  $files_to_save = "NGS* Sample* WF-sh";
} ########### END elsif (($galaxy_job eq "qc-star-se") or ($galaxy_job eq "qc-star-pe")   )

else {
  exit;
}


chdir($job_work_dir);
open(OUT, "> $job_output") || die "can not write to $job_output";
print OUT <<EOD;
<HTML>
<BODY>
Your job $galaxy_job (#$job_id) is completed. <BR>
You can view the results from
<A href="$www_web_url?jobid=$job_id" target="_RNAseq">here, (it opens a new window or a new tab)</A>.
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
  <!-- <LI>Download a gzipped file that contains all the results from <A href="$s3_web_url/$job_id/$job_id.tar.gz">our cloud storage</A>. -->
  <LI>Browse the directory and files from <A href="$www_file_url/$job_id/$file_list_file">file list page</A> to view or download individual files.
  <LI>If you are Linux / MacOS user, you can batch download the job directory with command such as "wget -r $www_file_url/$job_id".
</OL>

<!-- 
<h2>Directly use the results on our server</h2>
You can directly use the results from our server without download to your desktop in many applications, for example, many genome browsers (e.g. IGV)
can load alignment files (BAM) from a web URL, you can find the URL from <A href="$www_file_url/$job_id/$file_list_file">file list page</A> of a
BAM file and give to genome browser.
<P>
-->

EOD
close(OUT);

$cmd = `$script_dir/NGS-wf-galaxy-html-ls.pl . > $file_list_file`;
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

########## END qsub_n_wait
