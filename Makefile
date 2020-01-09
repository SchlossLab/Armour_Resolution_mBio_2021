REFS = data/references
FIGS = results/figures
TABLES = data/process/tables
PROC = data/process
FINAL = submission/
RAW = data/raw
MOTHUR = data/mothur

# utility function to print various variables. For example, running the
# following at the command line:
#
#	make print-BAM
#
# will generate:
#	BAM=data/raw_june/V1V3_0001.bam data/raw_june/V1V3_0002.bam ...
print-%:
	@echo '$*=$($*)'



################################################################################
#
# Part 1: Get the references
#
# We will need several reference files to complete the analyses including the
# SILVA reference alignment and RDP reference taxonomy.
#
################################################################################

REFS = data/references

$(REFS)/silva.v4.% :
	wget -N -P $(REFS)/ https://mothur.org/w/images/7/71/Silva.seed_v132.tgz
	tar xvzf $(REFS)/Silva.seed_v132.tgz -C $(REFS)/
	mothur "#get.lineage(fasta=$(REFS)/silva.seed_v132.align, taxonomy=$(REFS)/silva.seed_v132.tax, taxon=Bacteria);pcr.seqs(start=13862, end=23445, keepdots=F, processors=8);degap.seqs();unique.seqs()"
	cut -f 1 $(REFS)/silva.seed_v132.pick.pcr.ng.names > $(REFS)/silva.seed_v132.pick.pcr.ng.accnos
	mothur "#get.seqs(fasta=$(REFS)/silva.seed_v132.pick.pcr.align, accnos=$(REFS)/silva.seed_v132.pick.pcr.ng.accnos);screen.seqs(minlength=240, maxlength=275, maxambig=0, maxhomop=8, processors=8)"
	mv $(REFS)/silva.seed_v132.pick.pcr.pick.good.align $(REFS)/silva.v4.align
	grep "^>" $(REFS)/silva.v4.align | cut -c 2- > $(REFS)/silva.v4.accnos
	mothur "#get.seqs(taxonomy=$(REFS)/silva.seed_v132.pick.tax, accnos=$(REFS)/silva.v4.accnos)"
	mv $(REFS)/silva.seed_v132.pick.pick.tax  $(REFS)/silva.v4.tax
	rm $(REFS)/?ilva.seed_v132* $(REFS)/silva.v4.accnos

$(REFS)/trainset16_022016.pds.% :
	mkdir -p $(REFS)/rdp
	wget -N -P $(REFS)/ https://mothur.org/w/images/c/c3/Trainset16_022016.pds.tgz; \
	tar xvzf $(REFS)/Trainset16_022016.pds.tgz -C $(REFS)/rdp;\
	mv $(REFS)/rdp/trainset16_022016.pds/trainset16_022016.* $(REFS);\
	rm -rf $(REFS)/rdp $(REFS)/Trainset*


################################################################################
#
# Part 2: Get raw data and curate
#
#	Process data through the generation of files that will be used in the overall
# analyses.
#
################################################################################


# Run crc dataset through mothur pipeline through remove.lineage
data/mothur/crc.fasta data/mothur/crc.count_table data/mothur/crc.taxonomy : code/datasets_process.sh\
			code/datasets_download.sh\
			code/datasets_make_files.R\
			$(REFS)/silva.v4.align\
			$(REFS)/trainset16_022016.pds.fasta\
			$(REFS)/trainset16_022016.pds.tax
	bash $<

data/mothur/crc.asv.% : $(MOTHUR)/crc.trim.contigs.good.unique.good.filter.unique.precluster.denovo.uchime.pick.pick.pick.count_table\
			$(MOTHUR)/crc.trim.contigs.good.unique.good.filter.unique.precluster.pick.pds.wang.pick.pick.taxonomy\
			code/asv.sh
	bash code/asv.sh

data/mothur/crc.otu.taxonomy data/mothur/crc.otu.shared : data/mothur/crc.fasta\
			data/mothur/crc.count_table\
			data/mothur/crc.remove_accnos\
			code/get_original_otu_shared.sh
	bash code/get_original_otu_shared.sh $(dir $<)



# Pool OTUs into phylotypes
data/phylotype/crc.%.shared data/phylotype/crc.%.taxonomy :\
		$(MOTHUR)/crc.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.opti_mcc.0.03.cons_rdp.taxonomy\
		$(MOTHUR)/crc.trim.contigs.good.unique.good.filter.unique.precluster.pick.pick.pick.opti_mcc.0.03.subsample.shared
	Rscript code/phylotype.R $*


# Output crc.asv.shared and crc.asv.taxonomy, and crc.asv.fasta file based on screened preclustered
#	sequences in mothur pipeline
data/asv/crc.asv.% : $(MOTHUR)/crc.trim.contigs.good.unique.good.filter.unique.precluster.denovo.uchime.pick.pick.pick.count_table\
			$(MOTHUR)/crc.trim.contigs.good.unique.good.filter.unique.precluster.pick.pds.wang.pick.pick.taxonomy\
			code/asv.sh
	bash code/asv.sh
