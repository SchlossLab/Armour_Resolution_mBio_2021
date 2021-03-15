#!/usr/bin/perl

use strict;
use warnings;
#use IO::Zlib;

# Author: Courtney R Armour
# Date: March 11, 2021

################################################################
# This script will take the data.files file that maps sample ID
# to fastq files and outputs one forward and one reverse fastq
# file per sample named sample_1.fastq.gz and sample_2.fastq.gz
################################################################

# Arguments
my $map = $ARGV[0];

if (not defined $map) {
  die "Need mapping\n";
}

# Variables
my $datadir = "data/raw/";
my $outdir = "data/raw/merged/";

# this script appends to the end of files so
# we need to start with a blank slate
# if directory exists, delete and recreate
if(-e $outdir){
  print "output directory ",$outdir," already exists.","\n";
  print "removing the directory to remove old files\n";
  my $rmcmd = "rm -r ".$outdir;
  print $rmcmd,"\n";
  system($rmcmd);
  print "creating output directory: ",$outdir,"\n";
  mkdir $outdir;
}else{
  print "creating output directory: ",$outdir,"\n";
  mkdir $outdir;
}

# open the mapping file
open(MAP,"<",$map) || die("cannot open $map\n");

# create hash of samples to file names
my %hash = ();
while(my $line = <MAP>){
  chomp($line);
  my ($sampleID,$forward,$reverse)=split(/\t/,$line);
  my $accession = (split /_/,$forward)[0];
  #print $accession,"\n";
  push @{$hash{$sampleID}}, $accession;

}
close(MAP);

# run commands to produce per sample files
for my $key ( keys %hash ){

  # create forward and reverse filenames
  my $outfileF = $key."_1.fastq";
  my $outfileR = $key."_2.fastq";
  #print $outfileF,"\t",$outfileR,"\n";

  my @ids = @{$hash{$key}};
  for my $id (@ids){
    #zcat forward files to new output
    my $commandF = "zcat ".$datadir.$id."_1.fastq.gz >> ".$outdir.$outfileF;
    print $commandF,"\n";
    system($commandF);

    #zcat reverse files to new output
    my $commandR = "zcat ".$datadir.$id."_2.fastq.gz >> ".$outdir.$outfileR;
    print $commandR,"\n";
    system($commandR);
  }
}

#commpress all filenames
my $compress_cmd = "gzip ".$outdir."*.fastq";
print "compressing new fastq files\n";
print $compress_cmd,"\n";
system($compress_cmd);
