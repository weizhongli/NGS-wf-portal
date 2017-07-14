#!/usr/bin/perl
################################################################################
# NGS workflow by Weizhong Li, http://weizhongli-lab.org
################################################################################

########## local variables etc. Please edit
$NGS_root     = "/home/oasis/gordon-data/NGS-ann-project-new";

########## more local variables, do not edit next three lines
$NGS_tool_dir = "$NGS_root/NGS-tools";
$NGS_prog_dir = "$NGS_root/apps";
$NGS_bin_dir  = "$NGS_root/apps/bin";
$NGS_ref_dir  = "$NGS_root/refs";

########## computation resources for execution of jobs
%NGS_executions = ();
$NGS_executions{"qsub_1"} = {
  "type"                => "qsub-pe",
  "cores_per_node"      => 8,
  "number_nodes"        => 64,
  "user"                => "weizhong", #### I will use command such as qstat -u weizhong to query submitted jobs
  "command"             => "qsub",
  "command_name_opt"    => "-N",
  "command_err_opt"     => "-e",
  "command_out_opt"     => "-o",
  "template"            => <<EOD,
#!/bin/sh
#PBS -v PATH
#PBS -M liwz\@sdsc.edu
#PBS -q normal
#PBS -V
#PBS -l nodes=1:ppn=16,walltime=48:00:00,mem=60000mb
#\$ -q RNA.q
#\$ -v PATH
#\$ -V

EOD
};


$NGS_executions{"sh_1"} = {
  "type"                => "sh",
  "cores_per_node"      => 32,
  "number_nodes"        => 1,
};



########## batch jobs description 
########## jobs will be run for each @NGS_samples
%NGS_batch_jobs = ();

################################################################################
################################################################################
######  Tophat  Section ########################################################
################################################################################
################################################################################
$NGS_batch_jobs{"qc-tophat-cufflink-se"} = {
  "execution"         => "qsub_1",               # where to execute
  "cores_per_cmd"     => 4,                     # number of threads used by command below
  "no_parallel"       => 1,                     # number of total jobs to run using command below
  "command"           => <<EOD,
java -jar $NGS_prog_dir/Trimmomatic/trimmomatic-0.32.jar SE -threads 4 -phred33 \\DATA.0 \\SELF/R1.fq \\
    SLIDINGWINDOW:4:15 LEADING:3 TRAILING:3 MINLEN:50 MAXINFO:80:0.5 1>\\SELF/qc.stdout 2>\\SELF/qc.stderr

#$NGS_bin_dir/tophat -p 16 -G $NGS_ref_dir/human/Homo_sapiens.GRCh37.70.gtf -o \\SELF/tophat $NGS_ref_dir/human/human  \\SELF/R1.fq
$NGS_bin_dir/tophat -p 4 -G \\CMDOPTS.0                                    -o \\SELF/tophat \\CMDOPTS.1               \\SELF/R1.fq
$NGS_bin_dir/samtools index \\SELF/tophat/accepted_hits.bam
$NGS_bin_dir/cufflinks -p 4 -o \\SELF/cufflink \\SELF/tophat/accepted_hits.bam
rm -f \\SELF/R1.fq
EOD
};

$NGS_batch_jobs{"qc-tophat-cufflink-pe"} = {
  "execution"         => "qsub_1",               # where to execute
  "cores_per_cmd"     => 4,                     # number of threads used by command below
  "no_parallel"       => 1,                     # number of total jobs to run using command below
  "command"           => <<EOD,
java -jar $NGS_prog_dir/Trimmomatic/trimmomatic-0.32.jar PE -threads 4 -phred33 \\DATA.0 \\DATA.1 \\SELF/R1.fq \\SELF/R1-s.fq \\SELF/R2.fq \\SELF/R2-s.fq \\
    SLIDINGWINDOW:4:15 LEADING:3 TRAILING:3 MINLEN:50 MAXINFO:80:0.5 1>\\SELF/qc.stdout 2>\\SELF/qc.stderr

$NGS_bin_dir/tophat -p 4 -G \\CMDOPTS.0                                    -o \\SELF/tophat \\CMDOPTS.1               \\SELF/R1.fq \\SELF/R2.fq
$NGS_bin_dir/samtools index \\SELF/tophat/accepted_hits.bam
$NGS_bin_dir/cufflinks -p 4 -o \\SELF/cufflink \\SELF/tophat/accepted_hits.bam
rm -f \\SELF/R1.fq \\SELF/R1-s.fq \\SELF/R2.fq \\SELF/R2-s.fq
EOD
};


$NGS_batch_jobs{"cuffmerge"} = {
  "execution"         => "qsub_1",               # where to execute
  "cores_per_cmd"     => 4,                     # number of threads used by command below
  "no_parallel"       => 1,                     # number of total jobs to run using command below
  "command"           => <<EOD,
$NGS_bin_dir/cuffmerge -g \\CMDOPTS.0 -s \\CMDOPTS.1 -p 4 -o \\SELF \\CMDOPTS.2
EOD
};


$NGS_batch_jobs{"cuffdiff"} = {
  "execution"         => "qsub_1",               # where to execute
  "cores_per_cmd"     => 4,                     # number of threads used by command below
  "no_parallel"       => 1,                     # number of total jobs to run using command below
  "command"           => <<EOD,
#$NGS_bin_dir/cuffdiff -o Sample_diff_group1_n_group2 -b  $ref_genome.fa -p 4 -L group1,group2 -u $assembly_gtf $group1_bams $group2_bams
$NGS_bin_dir/cuffdiff -o \\SELF -b \\CMDOPTS.0 -p 4 -L group1,group2 -u \\CMDOPTS.1 \\CMDOPTS.2 \\CMDOPTS.3
EOD
};

################################################################################
################################################################################
######  Trinity Section ########################################################
################################################################################
################################################################################
$NGS_batch_jobs{"trinity-pe"} = {
  "non_zero_files"    => ["Trinity.fasta"],
  "execution"         => "qsub_1",               # where to execute
  "cores_per_cmd"     => 8,                     # number of threads used by command below
  "no_parallel"       => 1,                     # number of total jobs to run using command below
  "command"           => <<EOD,
#$NGS_prog_dir/trinityrnaseq/Trinity --seqType fq --max_memory 24G --left   $R1_group --right $R2_group --SS_lib_type RF --CPU 6 --full_cleanup --trimmomatic
$NGS_prog_dir/trinityrnaseq/Trinity --seqType fq --max_memory 54G --left \\CMDOPTS.0 --right \\CMDOPTS.1 --SS_lib_type RF --CPU 6 --full_cleanup --trimmomatic

mv trinity_out_dir.Trinity.fasta \\SELF/Trinity.fasta
$NGS_tool_dir/fasta_sort_by_len.pl  -r 1    \\SELF/Trinity.fasta
$NGS_prog_dir/trinityrnaseq/util/TrinityStats.pl \\SELF/Trinity.fasta > \\SELF/Trinity-stat.txt
$NGS_bin_dir/samtools faidx \\SELF/Trinity.fasta

#### just prepare the index etc
$NGS_prog_dir/trinityrnaseq/util/align_and_estimate_abundance.pl --transcripts \\SELF/Trinity.fasta \\
    --est_method RSEM --aln_method bowtie --trinity_mode --prep_reference --thread_count 6
EOD
};

$NGS_batch_jobs{"trinity-se"} = {
  "non_zero_files"    => ["Trinity.fasta"],
  "execution"         => "qsub_1",               # where to execute
  "cores_per_cmd"     => 8,                     # number of threads used by command below
  "no_parallel"       => 1,                     # number of total jobs to run using command below
  "command"           => <<EOD,
#$NGS_prog_dir/trinityrnaseq/Trinity --seqType fq --max_memory 24G --single $R1_group                   --CPU 6 --full_cleanup --trimmomatic
$NGS_prog_dir/trinityrnaseq/Trinity --seqType fq --max_memory 54G --single \\CMDOPTS.0                  --CPU 6 --full_cleanup --trimmomatic

mv trinity_out_dir.Trinity.fasta \\SELF/Trinity.fasta
$NGS_tool_dir/fasta_sort_by_len.pl  -r 1    \\SELF/Trinity.fasta
$NGS_prog_dir/trinityrnaseq/util/TrinityStats.pl \\SELF/Trinity.fasta > \\SELF/Trinity-stat.txt
$NGS_bin_dir/samtools faidx \\SELF/Trinity.fasta

#### just prepare the index etc
$NGS_prog_dir/trinityrnaseq/util/align_and_estimate_abundance.pl --transcripts \\SELF/Trinity.fasta \\
    --est_method RSEM --aln_method bowtie --trinity_mode --prep_reference --thread_count 6
EOD
};


$NGS_batch_jobs{"compare-trinity-to-ref"} = {
  "execution"         => "qsub_1",               # where to execute
  "cores_per_cmd"     => 4,                     # number of threads used by command below
  "no_parallel"       => 1,                     # number of total jobs to run using command below
  "command"           => <<EOD,

$NGS_bin_dir/blastn -query \\CMDOPTS.0 -db \\CMDOPTS.1 -out \\SELF/Trinity_vs_S_pombe_refTrans.blastn \\
  -evalue 1e-20 -dust no -task megablast -num_threads 4 -max_target_seqs 1 -outfmt 6

EOD
};




$NGS_batch_jobs{"post-trinity-pe"} = {
  "execution"         => "qsub_1",               # where to execute
  "cores_per_cmd"     => 4,                     # number of threads used by command below
  "no_parallel"       => 1,                     # number of total jobs to run using command below
  "command"           => <<EOD,
java -jar $NGS_prog_dir/Trimmomatic/trimmomatic-0.32.jar PE -threads 4 -phred33 \\DATA.0 \\DATA.1 \\SELF/R1.fq \\SELF/R1-s.fq \\SELF/R2.fq \\SELF/R2-s.fq \\
    SLIDINGWINDOW:4:15 LEADING:3 TRAILING:3 MINLEN:50 MAXINFO:80:0.5 1>\\SELF/qc.stdout 2>\\SELF/qc.stderr
#$NGS_prog_dir/trinityrnaseq/util/align_and_estimate_abundance.pl --transcripts ../Sample_all_trinity/Trinity.fasta --seqType fq \\
#    --left \\SELF/R1.fq --right \\SELF/R2.fq --est_method RSEM --aln_method bowtie --trinity_mode --prep_reference --thread_count 4
# process the database before running this step
# other wise multiple sample may format bowtie db at same time

$NGS_prog_dir/trinityrnaseq/util/align_and_estimate_abundance.pl --transcripts \\CMDOPTS.0 --seqType fq \\
    --left \\SELF/R1.fq --right \\SELF/R2.fq --est_method RSEM --aln_method bowtie --trinity_mode --thread_count 4

$NGS_bin_dir/samtools sort bowtie.bam bowtie-sorted
mv bowtie-sorted.bam bowtie.bam
$NGS_bin_dir/samtools index bowtie.bam
rm -f \\SELF/R1.fq \\SELF/R1-s.fq \\SELF/R2.fq \\SELF/R2-s.fq
EOD
};


$NGS_batch_jobs{"post-trinity-se"} = {
  "execution"         => "qsub_1",               # where to execute
  "cores_per_cmd"     => 4,                     # number of threads used by command below
  "no_parallel"       => 1,                     # number of total jobs to run using command below
  "command"           => <<EOD,
java -jar $NGS_prog_dir/Trimmomatic/trimmomatic-0.32.jar SE -threads 4 -phred33 \\DATA.0 \\SELF/R1.fq \\
    SLIDINGWINDOW:4:15 LEADING:3 TRAILING:3 MINLEN:50 MAXINFO:80:0.5 1>\\SELF/qc.stdout 2>\\SELF/qc.stderr
$NGS_prog_dir/trinityrnaseq/util/align_and_estimate_abundance.pl --transcripts  \\CMDOPTS.0 --seqType fq \\
    --single \\SELF/R1.fq --est_method RSEM --aln_method bowtie --trinity_mode --thread_count 4
$NGS_bin_dir/samtools sort bowtie.bam bowtie-sorted
mv bowtie-sorted.bam bowtie.bam
$NGS_bin_dir/samtools index bowtie.bam
rm -f \\SELF/R1.fq
EOD
};


$NGS_batch_jobs{"post-RSEM"} = {
  "execution"         => "qsub_1",               # where to execute
  "cores_per_cmd"     => 4,                     # number of threads used by command below
  "no_parallel"       => 1,                     # number of total jobs to run using command below
  "command"           => <<EOD,
$NGS_prog_dir/trinityrnaseq/util/abundance_estimates_to_matrix.pl --est_method RSEM  --out_prefix \\SELF/Trinity_trans  \\CMDOPTS.0 --name_sample_by_basedir
$NGS_prog_dir/trinityrnaseq/util/abundance_estimates_to_matrix.pl --est_method RSEM  --out_prefix \\SELF/Trinity_genes  \\CMDOPTS.1 --name_sample_by_basedir
$NGS_prog_dir/trinityrnaseq/Analysis/DifferentialExpression/run_DE_analysis.pl --matrix \\SELF/Trinity_genes.counts.matrix --method edgeR --output \\SELF/genes-diff
$NGS_prog_dir/trinityrnaseq/Analysis/DifferentialExpression/run_DE_analysis.pl --matrix \\SELF/Trinity_trans.counts.matrix --method edgeR --output \\SELF/trans-diff
EOD
};

$NGS_batch_jobs{"post-RSEM-group"} = {
  "execution"         => "qsub_1",               # where to execute
  "cores_per_cmd"     => 4,                     # number of threads used by command below
  "no_parallel"       => 1,                     # number of total jobs to run using command below
  "command"           => <<EOD,
$NGS_prog_dir/trinityrnaseq/util/abundance_estimates_to_matrix.pl --est_method RSEM  --out_prefix \\SELF/trans  \\CMDOPTS.0 --name_sample_by_basedir
$NGS_prog_dir/trinityrnaseq/util/abundance_estimates_to_matrix.pl --est_method RSEM  --out_prefix \\SELF/genes  \\CMDOPTS.1 --name_sample_by_basedir
$NGS_prog_dir/trinityrnaseq/Analysis/DifferentialExpression/run_DE_analysis.pl --matrix \\SELF/genes.counts.matrix --method edgeR --output \\SELF/genes-diff --samples_file \\CMDOPTS.2
$NGS_prog_dir/trinityrnaseq/Analysis/DifferentialExpression/run_DE_analysis.pl --matrix \\SELF/trans.counts.matrix --method edgeR --output \\SELF/trans-diff --samples_file \\CMDOPTS.2

cd \\SELF/genes-diff
$NGS_prog_dir/trinityrnaseq/Analysis/DifferentialExpression/analyze_diff_expr.pl --matrix ../genes.TMM.fpkm.matrix -P 1e-3 -C 2 --output genes-diff --samples \\CMDOPTS.2
$NGS_prog_dir/trinityrnaseq/Analysis/DifferentialExpression/define_clusters_by_cutting_tree.pl --Ptree 50 -R genes-diff.matrix.RData
cd ../..
cd \\SELF/trans-diff
$NGS_prog_dir/trinityrnaseq/Analysis/DifferentialExpression/analyze_diff_expr.pl --matrix ../trans.TMM.fpkm.matrix -P 1e-3 -C 2 --output trans-diff --samples \\CMDOPTS.2
$NGS_prog_dir/trinityrnaseq/Analysis/DifferentialExpression/define_clusters_by_cutting_tree.pl --Ptree 50 -R trans-diff.matrix.RData
EOD
};


################################################################################
################################################################################
######  STAR    Section ########################################################
################################################################################
################################################################################
$NGS_batch_jobs{"qc-star-se"} = {
  "injobs"            => ["qc-se"],
  "execution"         => "qsub_1",               # where to execute
  "cores_per_cmd"     => 8,                     # number of threads used by command below
  "no_parallel"       => 1,                     # number of total jobs to run using command below
  "command"           => <<EOD,
$NGS_bin_dir/STAR --runThreadN 2 --genomeDir \\CMDOPTS.0 --readFilesIn \\INJOBS.0/R1.fq \\
    --outFilterType BySJout --outFilterMultimapNmax 20 --alignSJoverhangMin 8 --alignSJDBoverhangMin 1 --outFilterMismatchNmax 999 --alignIntronMin 20 --alignIntronMax 1000000 --alignMatesGapMax 1000000 \\
    --outFileNamePrefix \\SELF/star --outSAMtype BAM SortedByCoordinate --quantMode TranscriptomeSAM GeneCounts
#$NGS_bin_dir/samtools index \\SELF/starAligned.sortedByCoord.out.bam
rm -f \\SELF/*.bam

EOD
};

$NGS_batch_jobs{"qc-star-pe"} = {
  "injobs"            => ["qc-pe"],
  "execution"         => "qsub_1",               # where to execute
  "cores_per_cmd"     => 8,                     # number of threads used by command below
  "no_parallel"       => 1,                     # number of total jobs to run using command below
  "command"           => <<EOD,
$NGS_bin_dir/STAR --runThreadN 2 --genomeDir \\CMDOPTS.0 --readFilesIn \\INJOBS.0/R1.fq \\INJOBS.0/R2.fq \\
    --outFilterType BySJout --outFilterMultimapNmax 20 --alignSJoverhangMin 8 --alignSJDBoverhangMin 1 --outFilterMismatchNmax 999 --alignIntronMin 20 --alignIntronMax 1000000 --alignMatesGapMax 1000000 \\
    --outFileNamePrefix \\SELF/star --outSAMtype BAM SortedByCoordinate --quantMode TranscriptomeSAM GeneCounts
#$NGS_bin_dir/samtools index \\SELF/starAligned.sortedByCoord.out.bam
rm -f \\SELF/*.bam

EOD
};


$NGS_batch_jobs{"qc-star-se-2nd-pass"} = {
  "injobs"            => ["qc-se",'qc-star-se'],
  "execution"         => "qsub_1",               # where to execute
  "cores_per_cmd"     => 8,                     # number of threads used by command below
  "no_parallel"       => 1,                     # number of total jobs to run using command below
  "command"           => <<EOD,
$NGS_bin_dir/STAR --runThreadN 2 --genomeDir \\CMDOPTS.0 --readFilesIn \\INJOBS.0/R1.fq \\
    --outFilterType BySJout --outFilterMultimapNmax 20 --alignSJoverhangMin 8 --alignSJDBoverhangMin 1 --outFilterMismatchNmax 999 --alignIntronMin 20 --alignIntronMax 1000000 --alignMatesGapMax 1000000 \\
    --outFileNamePrefix \\SELF/star --outSAMtype BAM SortedByCoordinate --quantMode TranscriptomeSAM GeneCounts --chimSegmentMin 30 --outWigType bedGraph --sjdbFileChrStartEnd \\CMDOPTS.1
$NGS_bin_dir/samtools index \\SELF/starAligned.sortedByCoord.out.bam

$NGS_prog_dir/trinityrnaseq/trinity-plugins/rsem/rsem-calculate-expression              -p 4 --no-bam-output --bam \\SELF/starAligned.toTranscriptome.out.bam \\CMDOPTS.2 RSEM 
rm -f \\INJOBS.0/R1.fq
rm -f \\SELF/*.bam
EOD
};

$NGS_batch_jobs{"qc-star-pe-2nd-pass"} = {
  "injobs"            => ["qc-pe","qc-star-pe"],
  "execution"         => "qsub_1",               # where to execute
  "cores_per_cmd"     => 8,                     # number of threads used by command below
  "no_parallel"       => 1,                     # number of total jobs to run using command below
  "command"           => <<EOD,
$NGS_bin_dir/STAR --runThreadN 2 --genomeDir \\CMDOPTS.0 --readFilesIn \\INJOBS.0/R1.fq \\INJOBS.0/R2.fq \\
    --outFilterType BySJout --outFilterMultimapNmax 20 --alignSJoverhangMin 8 --alignSJDBoverhangMin 1 --outFilterMismatchNmax 999 --alignIntronMin 20 --alignIntronMax 1000000 --alignMatesGapMax 1000000 \\
    --outFileNamePrefix \\SELF/star --outSAMtype BAM SortedByCoordinate --quantMode TranscriptomeSAM GeneCounts  --chimSegmentMin 30 --outWigType bedGraph --sjdbFileChrStartEnd \\CMDOPTS.1
$NGS_bin_dir/samtools index \\SELF/starAligned.sortedByCoord.out.bam

$NGS_prog_dir/trinityrnaseq/trinity-plugins/rsem/rsem-calculate-expression --paired-end -p 4 --no-bam-output --bam \\SELF/starAligned.toTranscriptome.out.bam \\CMDOPTS.2 RSEM 
rm -f \\INJOBS.0/R1.fq \\INJOBS.0/R2.fq
rm -f \\SELF/*.bam
EOD
};


################################################################################
################################################################################
######  general Section ########################################################
################################################################################
################################################################################
$NGS_batch_jobs{"qc-se"} = {
  "execution"         => "qsub_1",               # where to execute
  "cores_per_cmd"     => 4,                     # number of threads used by command below
  "no_parallel"       => 1,                     # number of total jobs to run using command below
  "command"           => <<EOD,
java -jar $NGS_prog_dir/Trimmomatic/trimmomatic-0.32.jar SE -threads 1 -phred33 \\DATA.0 \\SELF/R1.fq \\
    SLIDINGWINDOW:4:15 LEADING:3 TRAILING:3 MINLEN:50 MAXINFO:80:0.5 1>\\SELF/qc.stdout 2>\\SELF/qc.stderr
EOD
};

$NGS_batch_jobs{"qc-pe"} = {
  "execution"         => "qsub_1",               # where to execute
  "cores_per_cmd"     => 4,                     # number of threads used by command below
  "no_parallel"       => 1,                     # number of total jobs to run using command below
  "command"           => <<EOD,
java -jar $NGS_prog_dir/Trimmomatic/trimmomatic-0.32.jar PE -threads 1 -phred33 \\DATA.0 \\DATA.1 \\SELF/R1.fq \\SELF/R1-s.fq \\SELF/R2.fq \\SELF/R2-s.fq \\
    SLIDINGWINDOW:4:15 LEADING:3 TRAILING:3 MINLEN:50 MAXINFO:80:0.5 1>\\SELF/qc.stdout 2>\\SELF/qc.stderr
rm -f \\SELF/R1-s.fq \\SELF/R2-s.fq
EOD
};


################################################################################
################################################################################

$NGS_batch_jobs{"qc"} = {
  "execution"         => "sh_1",               # where to execute
  "cores_per_cmd"     => 4,                     # number of threads used by command below
  "no_parallel"       => 1,                     # number of total jobs to run using command below
  "command"           => <<EOD,
java -jar $NGS_prog_dir/Trimmomatic/trimmomatic-0.32.jar SE -threads 1 \\DATA.0 \\SELF/R1.fq \\
    SLIDINGWINDOW:4:15 LEADING:3 TRAILING:3 MINLEN:50 MAXINFO:80:0.5 1>\\SELF/qc.stdout 2>\\SELF/qc.stderr
EOD
  "outfiles"          => <<EOD,
R1.fq   high quality reads for R1
EOD
};

$NGS_batch_jobs{"tophat"} = {
  "injobs"            => ["qc"],
  "execution"         => "sh_1",               # where to execute
  "cores_per_cmd"     => 4,                     # number of threads used by command below
  "no_parallel"       => 1,                     # number of total jobs to run using command below
  "command"           => <<EOD,
#$NGS_bin_dir/tophat -p 16 -G $NGS_ref_dir/human/Homo_sapiens.GRCh37.70.gtf -o \\SELF/tophat $NGS_ref_dir/human/human  \\INJOBS.0/R1.fq
$NGS_bin_dir/tophat -p 16 -G \\CMDOPTS.0                                    -o \\SELF/tophat \\CMDOPTS.1               \\INJOBS.0/R1.fq
EOD
};

$NGS_batch_jobs{"cufflink"} = {
  "injobs"            => ["tophat"],
  "execution"         => "sh_1",               # where to execute
  "cores_per_cmd"     => 4,                     # number of threads used by command below
  "no_parallel"       => 1,                     # number of total jobs to run using command below
  "command"           => <<EOD,
$NGS_bin_dir/cufflinks -p 16 -o \\SELF/cufflink \\INJOBS.0/tophat/accepted_hits.bam
EOD
};


$NGS_group_jobs{"novel-gtf"} = {
  "file_inputs"        => [["all","cufflink","cufflink/transcripts.gtf","\n"]],
  "execution"         => "sh_1",               # where to execute
  "cores_per_cmd"     => 16,                     # number of threads used by command below
  "no_parallel"       => 1,                     # number of total jobs to run using command below
  "command"           => <<EOD,
$NGS_bin_dir/cuffmerge -s $NGS_ref_dir/human/human.fa -o \\SELF -p 16 \\FILE_INPUTS.0
$NGS_bin_dir/cuffcompare -s $NGS_ref_dir/human/human.fa -r $NGS_ref_dir/human/Homo_sapiens.GRCh37.70.gtf \\SELF/merged.gtf -p \\SELF/TCONS
EOD
};


##############################################################################################
########## END
1;






