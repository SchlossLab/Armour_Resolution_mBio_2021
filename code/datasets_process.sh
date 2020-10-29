#!/bin/bash

# Should come in as a directory to dataset like data/marine
RAW=data/raw
MOTHUR=data/mothur

# Download, split, and compress the sequence read files listed in $DATA/sra_info.tsv. This file is described
# in the script's header comment
bash code/datasets_download.sh $RAW


# Generate $DATA/data.files from downloaded file names and information in $DATA/sra_info.tsv
Rscript code/datasets_make_files.R $RAW


# Run data through standard mothur pipeline through the steps prior to clustering
bin/mothur/mothur "#set.seed(seed=19760620);
	set.dir(output=$MOTHUR);
	make.contigs(inputdir=$RAW, file=data.files, processors=8);
	screen.seqs(fasta=current, group=current, maxambig=0, maxlength=275, maxhomop=8);
	unique.seqs();
	count.seqs(name=current, group=current);
	align.seqs(fasta=current, reference=data/references/silva.v4.align);
	screen.seqs(fasta=current, count=current, start=8, end=9582);
	filter.seqs(fasta=current, vertical=T, trump=.);
	unique.seqs(fasta=current, count=current);
	pre.cluster(fasta=current, count=current, diffs=2);
	chimera.uchime(fasta=current, count=current, dereplicate=T);
	remove.seqs(fasta=current, accnos=current);
	classify.seqs(fasta=current, count=current, reference=data/references/trainset16_022016.pds.fasta, taxonomy=data/references/trainset16_022016.pds.tax, cutoff=80);
	remove.lineage(fasta=current, count=current, taxonomy=current, taxon=Chloroplast-Mitochondria-unknown-Archaea-Eukaryota);"


# Clean up the output data files

# We want to keep $DATA/data.fasta, $DATA/data.count_table, $DATA/data.taxonomy for future steps
mv $MOTHUR/data.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.fasta $MOTHUR/crc.fasta
mv $MOTHUR/data.trim.contigs.good.unique.good.filter.unique.precluster.denovo.uchime.pick.pick.count_table $MOTHUR/crc.count_table
mv $MOTHUR/data.trim.contigs.good.unique.good.filter.unique.precluster.pick.pds.wang.pick.taxonomy $MOTHUR/crc.taxonomy

# Remove fastq files and all intermediate mothur files to keep things organized
rm $MOTHUR/data.*
rm $RAW/data.* #$RAW/*fastq.gz
