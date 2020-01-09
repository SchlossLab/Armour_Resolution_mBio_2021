WORKDIR=data/asv
mkdir -p $WORKDIR

#dependencies
FASTA=data/mothur/crc.fasta
COUNT=data/mothur/crc.count_table
TAXONOMY=data/mothur/crc.taxonomy

mothur "#set.seed(seed=19760620);
	make.shared(count=$COUNT, label=ASV, outputdir=$WORKDIR);
	rename.seqs(fasta=$FASTA, taxonomy=$TAXONOMY, map=$WORKDIR/crc.map);
	sub.sample(shared=current, size=10500)"

mv $WORKDIR/crc.renamed.taxonomy $WORKDIR/crc.taxonomy
mv $WORKDIR/crc.ASV.subsample.shared $WORKDIR/crc.shared

rm $WORKDIR/crc.*map $WORKDIR/crc.renamed.fasta
