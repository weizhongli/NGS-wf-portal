#!/usr/bin/perl

my $data_tbl = <<EOD;
human	g38	Human (hg38)	/home/oasis/data/NGS-ann-project/refs/ensembl-genomes/human
cow	cow	Cow (UMD3.1)	/home/oasis/data/NGS-ann-project/refs/ensembl-genomes/cow
chicken	chicken	Chicken (Galgal4)	/home/oasis/data/NGS-ann-project/refs/ensembl-genomes/chicken
duck	duck	Duck (BGI_duck_1.0)	/home/oasis/data/NGS-ann-project/refs/ensembl-genomes/duck
horse	horse	Horse (EquCab2)	/home/oasis/data/NGS-ann-project/refs/ensembl-genomes/horse
guinea_pig	guinea_pig	Guinea_pig (cavPor3)	/home/oasis/data/NGS-ann-project/refs/ensembl-genomes/guinea_pig
pig	pig	Pig (Sscrofa10.2)	/home/oasis/data/NGS-ann-project/refs/ensembl-genomes/pig
rabbit	rabbit	Rabbit (OryCun2.0)	/home/oasis/data/NGS-ann-project/refs/ensembl-genomes/rabbit
sheep	sheep	Sheep (Oar_v3.1)	/home/oasis/data/NGS-ann-project/refs/ensembl-genomes/sheep
turkey	turkey	Turkey (UMD2)	/home/oasis/data/NGS-ann-project/refs/ensembl-genomes/turkey
c.elegan	c.elegan	C.elegan (WBcel235)	/home/oasis/data/NGS-ann-project/refs/ensembl-genomes/c.elegan
yeast	yeast	Yeast (R64-1-1)	/home/oasis/data/NGS-ann-project/refs/ensembl-genomes/yeast
fruitfly	fruitfly	Drosophila_melanogaster (BDGP6.79)	/home/oasis/data/NGS-ann-project/refs/ensembl-genomes/fruitfly
EOD
#goat fasta files has different line length, samtool faidx goat.fa failed
#goat	goat	Goat (FG_V1.1)	/home/oasis/data/NGS-ann-project/refs/goat.kiz.ac.cn/goat

my @genomes = split(/\n/, $data_tbl);

my ($i, $j, $k, $ll, $cmd);
print "<Server-Side Genome List>\n";

foreach my $t_genome (@genomes) {
  my ($id, $id1, $name, $loc) = split(/\t/,$t_genome);
  # $cmd = `samtools faidx $id.fa`;
  my $t_dir = "$id-dir";
  $cmd = `mkdir $t_dir`;
  $cmd = `cp -p $id.gtf $t_dir`;

  open(OUT, "> $t_dir/property.txt") || die "can not write to $t_dir/property.txt";
  print OUT <<EOD;
fasta=true
fastaDirectory=false
ordered=true
id=$id
name=$name
geneFile=$id.gtf
sequenceLocation=http://weizhongli-lab.org/RNA-seq/Data/reference-genomes/$id.fa
EOD
  close(OUT);

  print "$name\thttp://weizhongli-lab.org/RNA-seq/Data/reference-genomes/$id.genome\t$id\n";
  if (chdir($t_dir)) {
    $cmd = `zip ../$id.genome *`;
    chdir("..");
  }
}

die;
foreach my $t_genome (@genomes) {
  my ($id, $id1, $name, $loc) = split(/\t/,$t_genome);
  $cmd = `samtools faidx $id.fa`;
}
