WORKDIR=data/asv
mkdir -p $WORKDIR

#dependencies
FASTA=data/mothur/crc.fasta
COUNT=data/mothur/crc.count_table
TAXONOMY=data/mothur/crc.taxonomy

mothur "#set.seed(seed=19760620);
	make.shared(count=$COUNT, label=ASV, outputdir=$WORKDIR);
	classify.otu(list=current, count=current, taxonomy=$TAXONOMY);
	sub.sample(shared=current, size=10500)"

mv $WORKDIR/crc.ASV.ASV.subsample.shared $WORKDIR/crc.shared
mv $WORKDIR/crc.ASV.ASV.cons.taxonomy $WORKDIR/crc.taxonomy
