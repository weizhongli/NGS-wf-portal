#!/usr/bin/perl

use Getopt::Std;

getopts("X:",\%opts);
#die usage() unless ($opts{X});

my $exclude_patterns = $opts{X}; #### patterns to be excluded 
my @exclude_patterns = split(/,/, $exclude_patterns);

#### to print a single page of HTML page list all files, directories recursively, only files are clickable


my $total_html = "";

$level = 1;
process_this_dir(".", $level);

print $total_html;


sub process_this_dir {
  my $dir = shift;
  my $level = shift;
  my ($i, $j, $k, $ll, $cmd);

  print STDERR "processing $dir, level - $level\n";


  opendir(DIR, $dir) || die "can not open $dir";
  my @files = sort grep {/\w/} readdir(DIR);
  closedir(DIR);

  my @sub_dirs = ();
  my @sub_files = ();

  foreach $i (@files) {
    next if ($i =~ /\.html$/);
    next if ($i =~ /\.pl$/);
    next if ($i =~ /\.sh$/);
    next if ($i =~ /^WF/);
    next if ($i =~ /^NGS/);

    if (-d "$dir/$i") {
      push(@sub_dirs, $i);
      print OUT "<A href=\"$i/index.html\">$i</A>\n";
    }
    else {
      push(@sub_files, $i);

      $cmd = `du -h $dir/$i`;
      my $s = (split(/\s+/,$cmd))[0];
      print OUT "<A href=\"$i\">$i ($s)</A>\n";

    }
  }

  my $tail_tag = "\n";
  if (@sub_dirs or @sub_files) {
    $total_html .= "<UL>\n";
    $tail_tag = "</UL>\n";
  }
  foreach $i (@sub_files) {
    $cmd = `du -h $dir/$i`;
    my $s = (split(/\s+/,$cmd))[0];
    $total_html .=  "<LI><A href=\"$dir/$i\">$i ($s)</A>\n";
  }

  foreach $i (@sub_dirs) {
    $total_html .= "<LI>Directory: $i\n";
    process_this_dir("$dir/$i", $level+1);
  }

  $total_html .= $tail_tag;
}



