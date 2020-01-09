PROCESSORSSPLIT=8
PROCESSORSCLUSTER=1

mkdir -p data/otu

mothur "#set.seed(seed=19760620);
	set.dir(input=data/mothur, output=data/otu);
	cluster.split(fasta=crc.fasta, count=crc.count_table, taxonomy=crc.taxonomy, taxlevel=4, processors=$PROCESSORSSPLIT, runsensspec=FALSE, cluster=FALSE);
	cluster.split(file=current, processors=$PROCESSORSCLUSTER, runsensspec=FALSE);
	classify.otu(list=current, taxonomy=current, count=current);
	make.shared();
	sub.sample(shared=current, size=10500)"

mv data/otu/crc.opti_mcc.0.03.subsample.shared data/otu/crc.shared
mv data/otu/crc.opti_mcc.0.03.cons.taxonomy data/otu/crc.taxonomy
rm data/otu/*opti_mcc* data/otu/*file
