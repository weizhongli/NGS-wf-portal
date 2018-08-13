#!/usr/bin/perl

# for human, do not use ftp://ftp.ensembl.org/pub/current_fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.toplevel.fa.gz, too big     1,021,422 KB 40   GB
#                   use ftp://ftp.ensembl.org/pub/current_fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz        860,561 KB  3.1 GB
# for mouse, do not use ftp://ftp.ensembl.org/pub/current_fasta/mus_musculus/dna/Mus_musculus.GRCm38.dna.toplevel.fa.gz
#                   use ftp://ftp.ensembl.org/pub/current_fasta/mus_musculus/dna/Mus_musculus.GRCm38.dna.primary_assembly.fa.gz
# for zebrafish do not use ftp://ftp.ensembl.org/pub/current_fasta/danio_rerio/dna/Danio_rerio.GRCz11.dna.toplevel.fa.gz
#                      use ftp://ftp.ensembl.org/pub/current_fasta/danio_rerio/dna/Danio_rerio.GRCz11.dna.primary_assembly.fa.gz
my $data = <<EOD;
cow bos_taurus
  ftp://ftp.ensembl.org/pub/current_fasta/bos_taurus/cdna/Bos_taurus.UMD3.1.cdna.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/bos_taurus/cds/Bos_taurus.UMD3.1.cds.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/bos_taurus/dna/Bos_taurus.UMD3.1.dna.toplevel.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/bos_taurus/ncrna/Bos_taurus.UMD3.1.ncrna.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/bos_taurus/pep/Bos_taurus.UMD3.1.pep.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_gtf/bos_taurus/Bos_taurus.UMD3.1.93.gtf.gz
----c.elegan caenorhabditis_elegans
  ftp://ftp.ensembl.org/pub/current_fasta/caenorhabditis_elegans/cdna/Caenorhabditis_elegans.WBcel235.cdna.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/caenorhabditis_elegans/cds/Caenorhabditis_elegans.WBcel235.cds.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/caenorhabditis_elegans/dna/Caenorhabditis_elegans.WBcel235.dna.toplevel.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/caenorhabditis_elegans/ncrna/Caenorhabditis_elegans.WBcel235.ncrna.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/caenorhabditis_elegans/pep/Caenorhabditis_elegans.WBcel235.pep.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_gtf/caenorhabditis_elegans/Caenorhabditis_elegans.WBcel235.93.gtf.gz
----zebrafish Danio_rerio
  ftp://ftp.ensembl.org/pub/current_fasta/danio_rerio/cdna/Danio_rerio.GRCz11.cdna.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/danio_rerio/cds/Danio_rerio.GRCz11.cds.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/danio_rerio/dna/Danio_rerio.GRCz11.dna.primary_assembly.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/danio_rerio/ncrna/Danio_rerio.GRCz11.ncrna.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/danio_rerio/pep/Danio_rerio.GRCz11.pep.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_gtf/danio_rerio/Danio_rerio.GRCz11.93.gtf.gz
----fruitfly drosophila_melanogaster
  ftp://ftp.ensembl.org/pub/current_fasta/drosophila_melanogaster/cdna/Drosophila_melanogaster.BDGP6.cdna.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/drosophila_melanogaster/cds/Drosophila_melanogaster.BDGP6.cds.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/drosophila_melanogaster/dna/Drosophila_melanogaster.BDGP6.dna.toplevel.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/drosophila_melanogaster/ncrna/Drosophila_melanogaster.BDGP6.ncrna.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/drosophila_melanogaster/pep/Drosophila_melanogaster.BDGP6.pep.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_gtf/drosophila_melanogaster/Drosophila_melanogaster.BDGP6.93.gtf.gz
----human homo_sapiens
  ftp://ftp.ensembl.org/pub/current_fasta/homo_sapiens/cdna/Homo_sapiens.GRCh38.cdna.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/homo_sapiens/cds/Homo_sapiens.GRCh38.cds.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/homo_sapiens/ncrna/Homo_sapiens.GRCh38.ncrna.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/homo_sapiens/pep/Homo_sapiens.GRCh38.pep.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_gtf/homo_sapiens/Homo_sapiens.GRCh38.93.gtf.gz
----mouse mus_musculus
  ftp://ftp.ensembl.org/pub/current_fasta/mus_musculus/cdna/Mus_musculus.GRCm38.cdna.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/mus_musculus/cds/Mus_musculus.GRCm38.cds.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/mus_musculus/dna/Mus_musculus.GRCm38.dna.primary_assembly.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/mus_musculus/ncrna/Mus_musculus.GRCm38.ncrna.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/mus_musculus/pep/Mus_musculus.GRCm38.pep.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_gtf/mus_musculus/Mus_musculus.GRCm38.93.gtf.gz
----sheep ovis_aries
  ftp://ftp.ensembl.org/pub/current_fasta/ovis_aries/cdna/Ovis_aries.Oar_v3.1.cdna.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/ovis_aries/cds/Ovis_aries.Oar_v3.1.cds.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/ovis_aries/dna/Ovis_aries.Oar_v3.1.dna.toplevel.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/ovis_aries/ncrna/Ovis_aries.Oar_v3.1.ncrna.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/ovis_aries/pep/Ovis_aries.Oar_v3.1.pep.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_gtf/ovis_aries/Ovis_aries.Oar_v3.1.93.gtf.gz
----yeast saccharomyces_cerevisiae
  ftp://ftp.ensembl.org/pub/current_fasta/saccharomyces_cerevisiae/cdna/Saccharomyces_cerevisiae.R64-1-1.cdna.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/saccharomyces_cerevisiae/cds/Saccharomyces_cerevisiae.R64-1-1.cds.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/saccharomyces_cerevisiae/dna/Saccharomyces_cerevisiae.R64-1-1.dna.toplevel.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/saccharomyces_cerevisiae/ncrna/Saccharomyces_cerevisiae.R64-1-1.ncrna.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/saccharomyces_cerevisiae/pep/Saccharomyces_cerevisiae.R64-1-1.pep.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_gtf/saccharomyces_cerevisiae/Saccharomyces_cerevisiae.R64-1-1.93.gtf.gz  
----pig sus_scrofa
  ftp://ftp.ensembl.org/pub/current_fasta/sus_scrofa/cdna/Sus_scrofa.Sscrofa11.1.cdna.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/sus_scrofa/cds/Sus_scrofa.Sscrofa11.1.cds.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/sus_scrofa/dna/Sus_scrofa.Sscrofa11.1.dna.toplevel.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/sus_scrofa/ncrna/Sus_scrofa.Sscrofa11.1.ncrna.fa.gz
  ftp://ftp.ensembl.org/pub/current_fasta/sus_scrofa/pep/Sus_scrofa.Sscrofa11.1.pep.all.fa.gz
  ftp://ftp.ensembl.org/pub/current_gtf/sus_scrofa/Sus_scrofa.Sscrofa11.1.93.gtf.gz
EOD
$data =~ s/\s+/ /g;

my $pwd = `pwd`; $pwd =~ s/\s//g;
my @data = split(/----/,$data);
foreach $i (@data) {
  #my ($key, $genome, $gtf, $cdna, $cds, $pep, $ncrna) = split(/\s+/,$i);
  my ($key, $name, $cdna, $cds, $genome, $ncrna, $pep, $gtf) = split(/\s+/,$i);
  my $genome_f = (split(/\//, $genome))[-1]; $genome_f =~ s/.gz$//;
  my $gtf_f    = (split(/\//, $gtf))[-1];    $gtf_f    =~ s/.gz$//;
  my $cdna_f   = (split(/\//, $cdna))[-1];   $cdna_f   =~ s/.gz$//;
  my $pep_f    = (split(/\//, $pep))[-1];    $pep_f    =~ s/.gz$//;
  my $cds_f    = (split(/\//, $cds))[-1];    $cds_f    =~ s/.gz$//;
  my $ncrna_f  = (split(/\//, $ncrna))[-1];  $ncrna_f  =~ s/.gz$//;

  my $star_opt = 14;
  if    ($key eq "yeast"    ) {$star_opt = 11; }
  elsif ($key eq "fruitfly" ) {$star_opt = 13; }

  my $no_seq = <<EOD;
      7      35     181 c.elegan.fa.fai
  15932   79660  583544 chicken.fa.fai
   3317   16585  109272 cow.fa.fai
  78487  392435 2521826 duck.fa.fai
   1870    9350   69484 fruitfly.fa.fai
   9637   48185  280595 horse.fa.fai
    194     970    6406 human.fa.fai
   4583   22915  154207 pig.fa.fai
   3242   16210  110721 rabbit.fa.fai
   5698   28490  197857 sheep.fa.fai
   5891   29455  194507 turkey.fa.fai
     17      85     415 yeast.fa.fai
EOD

  $star_opt_str2 = "";
  if ( ($key eq "chicken") or ($key eq "duck")  or ($key eq "horse") or  ($key eq "sheep") or  ($key eq "turkey")) {
    $star_opt_str2 = " --genomeChrBinNbits 15";
  }
  my $cmd = <<EOD;
#!/bin/sh
#\$ -v PATH
#\$ -V
#\$ -pe orte 4

cd $pwd

#### $key
wget $genome
wget $gtf
wget $cdna
wget $cds
wget $pep
wget $ncrna
gunzip $genome_f.gz
gunzip $gtf_f.gz
gunzip $cdna_f.gz
gunzip $pep_f.gz
gunzip $cds_f.gz
gunzip $ncrna_f.gz
ln -s $genome_f $key.fa
ln -s $gtf_f    $key.gtf
ln -s $cdna_f   $key.cdna
ln -s $cds_f    $key.cds
ln -s $pep_f    $key.pep
ln -s $ncrna_f  $key.ncrna
# /home/oasis/data/NGS-ann-project/apps/bwa/bwa index -a bwtsw -p $key $key.fa
# /home/oasis/data/NGS-ann-project/apps/bowtie2/bowtie2-build -f  $key.fa $key
# /home/oasis/data/NGS-ann-project/apps/bin/makeblastdb -in $key.cdna -dbtype nucl
# /home/oasis/data/NGS-ann-project/apps/bin/makeblastdb -in $key.pep -dbtype prot
mkdir $key-STAR
/home/oasis/data/NGS-ann-project/apps/bin/STAR --runThreadN 4 --runMode genomeGenerate --genomeDir $key-STAR --genomeFastaFiles $key.fa --sjdbGTFfile $key.gtf  --genomeSAindexNbases $star_opt$star_opt_str2
/home/oasis/data/NGS-ann-project/apps/trinityrnaseq/trinity-plugins/rsem/rsem-prepare-reference -gtf $key.gtf  $key.fa $key-RSEM
EOD

  open(TSH, "> $key.sh") || die;
  print TSH $cmd;
  close(TSH);
}

