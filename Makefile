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
	wget -N -P $(REFS)/ https://mothur.s3.us-east-2.amazonaws.com/wiki/silva.seed_v138.tgz
	tar xvzf $(REFS)/silva.seed_v138.tgz -C $(REFS)/
	mothur "#get.lineage(fasta=$(REFS)/silva.seed_v138.align, taxonomy=$(REFS)/silva.seed_v138.tax, taxon=Bacteria);pcr.seqs(start=13862, end=23445, keepdots=F, processors=8);degap.seqs();unique.seqs()"
	cut -f 1 $(REFS)/silva.seed_v138.pick.pcr.ng.names > $(REFS)/silva.seed_v138.pick.pcr.ng.accnos
	mothur "#get.seqs(fasta=$(REFS)/silva.seed_v138.pick.pcr.align, accnos=$(REFS)/silva.seed_v138.pick.pcr.ng.accnos);screen.seqs(minlength=240, maxlength=275, maxambig=0, maxhomop=8, processors=8)"
	mv $(REFS)/silva.seed_v138.pick.pcr.pick.good.align $(REFS)/silva.v4.align
	grep "^>" $(REFS)/silva.v4.align | cut -c 2- > $(REFS)/silva.v4.accnos
	mothur "#get.seqs(taxonomy=$(REFS)/silva.seed_v138.pick.tax, accnos=$(REFS)/silva.v4.accnos)"
	mv $(REFS)/silva.seed_v138.pick.pick.tax  $(REFS)/silva.v4.tax
	rm $(REFS)/?ilva.seed_v138* $(REFS)/silva.v4.accnos

$(REFS)/trainset16_022016.pds.% :
	mkdir -p $(REFS)/rdp
	wget -N -P $(REFS)/ https://mothur.s3.us-east-2.amazonaws.com/wiki/trainset16_022016.pds.tgz; \
	tar xvzf $(REFS)/trainset16_022016.pds.tgz -C $(REFS)/rdp;\
	mv $(REFS)/rdp/trainset16_022016.pds/trainset16_022016.* $(REFS);\
	rm -rf $(REFS)/rdp $(REFS)/trainset*.tgz


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


################################################################################
#
# Part 3: Generate the shared files
#
#	Generate shared files for ASVs, OTUs, and various taxonomic levels
#
################################################################################

# Generate ASV shared and taxonomy files
data/asv/crc.shared : code/get_asv_shared.sh\
			data/mothur/crc.fasta\
			data/mothur/crc.count_table\
			data/mothur/crc.taxonomy
	bash code/get_asv_shared.sh

# Generate OTU shared and taxonomy files
data/otu/crc.shared : data/mothur/crc.fasta\
			data/mothur/crc.taxonomy\
			data/mothur/crc.count_table\
			code/get_otu_shared.sh
	bash code/get_otu_shared.sh

# Generate genus shared and taxonomy files
data/genus/crc.shared data/genus/crc.taxonomy : code/get_phylotype_shared.R\
			data/otu/crc.taxonomy\
			data/otu/crc.shared
	Rscript code/get_phylotype_shared.R genus

# Generate family shared and taxonomy files
data/family/crc.shared data/family/crc.taxonomy : code/get_phylotype_shared.R\
			data/otu/crc.taxonomy\
			data/otu/crc.shared
	Rscript code/get_phylotype_shared.R family

# Generate order shared and taxonomy files
data/order/crc.shared data/order/crc.taxonomy : code/get_phylotype_shared.R\
			data/otu/crc.taxonomy\
			data/otu/crc.shared
	Rscript code/get_phylotype_shared.R order

# Generate class shared and taxonomy files
data/class/crc.shared data/class/crc.taxonomy : code/get_phylotype_shared.R\
			data/otu/crc.taxonomy\
			data/otu/crc.shared
	Rscript code/get_phylotype_shared.R class

# Generate phylum shared and taxonomy files
data/phylum/crc.shared data/phylum/crc.taxonomy : code/get_phylotype_shared.R\
			data/otu/crc.taxonomy\
			data/otu/crc.shared
	Rscript code/get_phylotype_shared.R phylum

# Generate kingdom shared and taxonomy files
data/kingdom/crc.shared data/kingdom/crc.taxonomy : code/get_phylotype_shared.R\
			data/otu/crc.taxonomy\
			data/otu/crc.shared
	Rscript code/get_phylotype_shared.R kingdom


################################################################################
#
# Part 3: Generate the metadata files
#
#	Generate the input file for each taxonomic level
#
################################################################################

# Generate asv input file
data/asv/input_data.csv : code/merge_metadata_shared.R\
			data/metadata/metadata.csv\
			data/asv/crc.shared
	Rscript code/merge_metadata_shared.R asv

# Generate otu input file
data/otu/input_data.csv : code/merge_metadata_shared.R\
			data/metadata/metadata.csv\
			data/otu/crc.shared
	Rscript code/merge_metadata_shared.R otu

# Generate genus input file
data/genus/input_data.csv : code/merge_metadata_shared.R\
                        data/metadata/metadata.csv\
                        data/genus/crc.shared
	Rscript code/merge_metadata_shared.R genus

# Generate family input file     
data/family/input_data.csv : code/merge_metadata_shared.R\
			data/metadata/metadata.csv\
			data/family/crc.shared
	Rscript code/merge_metadata_shared.R family

# Generate order input file
data/order/input_data.csv : code/merge_metadata_shared.R\
			data/metadata/metadata.csv\
			data/order/crc.shared
	Rscript code/merge_metadata_shared.R order

# Generate class input file
data/class/input_data.csv : code/merge_metadata_shared.R\
			data/metadata/metadata.csv\
			data/class/crc.shared
	Rscript code/merge_metadata_shared.R class

# Generate phylum input file
data/phylum/input_data.csv : code/merge_metadata_shared.R\
			data/metadata/metadata.csv\
			data/phylum/crc.shared
	Rscript code/merge_metadata_shared.R phylum

# Generate kingdom input file
data/kingdom/input_data.csv : code/merge_metadata_shared.R\
			data/metadata/metadata.csv\
			data/kingdom/crc.shared
	Rscript code/merge_metadata_shared.R kingdom


################################################################################
#
# Part 4: Generate the models
#
#	Generate the various ML models for each of the shared files
#
################################################################################

LEVEL=kingdom phylum class order family genus otu asv
METHOD=L2_Logistic_Regression Random_Forest Decision_Tree L1_Linear_SVM L2_Linear_SVM RBF_SVM XGBoost
SEED:=$(shell seq 100)
BEST_RESULTS=$(foreach L,$(LEVEL),$(foreach M,$(METHOD),$(foreach S,$(SEED), data/$L/$M.$S.csv)))

.SECONDEXPANSION:
$(BEST_RESULTS) : \
			$$(dir $$@)input_data.csv\
			data/default_hyperparameters/$$(basename $$(basename $$(notdir $$@))).csv
	$(eval S=$(subst .,,$(suffix $(basename $@))))
	$(eval M=$(notdir $(basename $(basename $@))))
	$(eval L=$(subst /,,$(subst data/,,$(dir $@))))
	Rscript code/R/main.R --seed=$(S) --model=$(M) --taxonomy=$(L) --data=data/$(L)/input_data.csv --hyperparams=data/default_hyperparameters/$(M).csv --outcome=dx


################################################################################
#
# Part 5: Merge the Results
#
#	Generate a concatenated version of the results for each method 
#       and taxonomic level
#
################################################################################

METHOD=L2_Logistic_Regression Random_Forest Decision_Tree L1_Linear_SVM L2_Linear_SVM RBF_SVM XGBoost
LEVEL=kingdom phylum class order family genus otu asv
CONCAT=$(foreach L,$(LEVEL),$(foreach M,$(METHOD), data/process/combined-$(L)-$(M).csv))
SEED:=$(shell seq 100)

.SECONDEXPANSION:
$(CONCAT) : \
			code/concat_pipeline_auc_output.py \
			$(foreach S,$(SEED), data/temp/$$(word 2,$$(subst -, ,$$(notdir $$(basename $$@))))/$$(word 3,$$(subst -, ,$$(notdir $$(basename $$@)))).$(S).csv)
	$(eval M=$(word 3,$(subst -, ,$(notdir $(basename $@)))))
	$(eval L=$(word 2,$(subst -, ,$(notdir $(basename $@)))))
	python code/concat_pipeline_auc_output.py --taxonomy $(L) --model $(M)

