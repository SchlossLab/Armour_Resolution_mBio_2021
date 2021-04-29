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
	wget -N -P $(REFS)/ https://mothur.s3.us-east-2.amazonaws.com/wiki/silva.seed_v132.tgz
	tar xvzf $(REFS)/silva.seed_v132.tgz -C $(REFS)/
	bin/mothur/mothur "#get.lineage(fasta=$(REFS)/silva.seed_v132.align, taxonomy=$(REFS)/silva.seed_v132.tax, taxon=Bacteria);pcr.seqs(start=13862, end=23445, keepdots=F, processors=8);degap.seqs();unique.seqs()"
	cut -f 1 $(REFS)/silva.seed_v132.pick.pcr.ng.names > $(REFS)/silva.seed_v132.pick.pcr.ng.accnos
	bin/mothur/mothur "#get.seqs(fasta=$(REFS)/silva.seed_v132.pick.pcr.align, accnos=$(REFS)/silva.seed_v132.pick.pcr.ng.accnos);screen.seqs(minlength=240, maxlength=275, maxambig=0, maxhomop=8, processors=8)"
	mv $(REFS)/silva.seed_v132.pick.pcr.pick.good.align $(REFS)/silva.v4.align
	grep "^>" $(REFS)/silva.v4.align | cut -c 2- > $(REFS)/silva.v4.accnos
	bin/mothur/mothur "#get.seqs(taxonomy=$(REFS)/silva.seed_v132.pick.tax, accnos=$(REFS)/silva.v4.accnos)"
	mv $(REFS)/silva.seed_v132.pick.pick.tax  $(REFS)/silva.v4.tax
	rm $(REFS)/?ilva.seed_v132* $(REFS)/silva.v4.accnos

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
# Part 4: Preprocess data
#
#	Generate the preprocessed input data file (saves time to only do once)
#	currently runs mikRopML default preprocessing method (zscore)
#
################################################################################

# Generate ASV preprocessed input file
data/asv/input_data_preproc.csv : code/R/preprocess_data.R\
			data/asv/input_data.csv
	Rscript --max-ppsize=500000 code/R/preprocess_data.R --data=data/asv/input_data.csv --taxonomy=asv

# Generate OTU preprocessed input file
data/otu/input_data_preproc.csv	: code/R/preprocess_data.R\
			data/otu/input_data.csv
	Rscript	--max-ppsize=500000 code/R/preprocess_data.R --data=data/otu/input_data.csv --taxonomy=otu

# Generate Genus preprocessed input file
data/genus/input_data_preproc.csv : code/R/preprocess_data.R\
			data/genus/input_data.csv
	Rscript code/R/preprocess_data.R --data=data/genus/input_data.csv --taxonomy=genus

# Generate Family preprocessed input file
data/family/input_data_preproc.csv : code/R/preprocess_data.R\
			data/family/input_data.csv
	Rscript code/R/preprocess_data.R --data=data/family/input_data.csv --taxonomy=family

# Generate Order preprocessed input file
data/order/input_data_preproc.csv : code/R/preprocess_data.R\
			data/order/input_data.csv
	Rscript	code/R/preprocess_data.R --data=data/order/input_data.csv --taxonomy=order

# Generate class  preprocessed input file
data/class/input_data_preproc.csv : code/R/preprocess_data.R\
			data/class/input_data.csv
	Rscript code/R/preprocess_data.R --data=data/class/input_data.csv --taxonomy=class

# Generate phylum preprocessed input file
data/phylum/input_data_preproc.csv : code/R/preprocess_data.R\
			data/phylum/input_data.csv
	Rscript	code/R/preprocess_data.R --data=data/phylum/input_data.csv --taxonomy=phylum

################################################################################
#
# Part 5: Generate the models
#
#	Generate the various ML models for each of the shared files
#
################################################################################

LEVEL=phylum class order family genus otu asv
METHOD=rpart2 rf glmnet svmRadial xgbTree
SEED:=$(shell seq 100)
BEST_RESULTS=$(foreach L,$(LEVEL),$(foreach M,$(METHOD),$(foreach S,$(SEED), data/$L/temp/$M.$S.csv)))

.SECONDEXPANSION:
$(BEST_RESULTS) : code/R/run_model.R \
			data/hyperparameters/hyperparameters.csv \
			data/$$(word 2,$$(subst /, ,$$(dir $$@)))/input_data_preproc.csv
	$(eval S=$(subst .,,$(suffix $(basename $@))))
	$(eval M=$(notdir $(basename $(basename $@))))
	$(eval L=$(subst temp,,$(subst /,,$(subst data/,,$(dir $@)))))
	Rscript --max-ppsize=500000 code/R/run_model.R --data=data/$L/input_data_preproc.csv --method=$M --taxonomy=$L --outcome_colname=dx --outcome_value=cancer --seed=$S --hyperparams=data/hyperparameters/$(M)_hyperparameters.csv


################################################################################
#
# Part 6: Merge the Results
#
#	Generate a concatenated version of the results for each method
#       and taxonomic level
#
################################################################################

METHOD=rpart2 rf glmnet svmRadial xgbTree
LEVEL=phylum class order family genus otu asv
CONCAT=$(foreach L,$(LEVEL),$(foreach M,$(METHOD), data/process/combined-$(L)-$(M).csv))
SEED:=$(shell seq 100)

.SECONDEXPANSION:
$(CONCAT) : \
			code/concat_pipeline_auc_output.py \
			$(foreach S,$(SEED), data/$$(word 2,$$(subst -, ,$$(notdir $$(basename $$@))))/temp/$$(word 3,$$(subst -, ,$$(notdir $$(basename $$@)))).$(S).csv)
	$(eval M=$(word 3,$(subst -, ,$(notdir $(basename $@)))))
	$(eval L=$(word 2,$(subst -, ,$(notdir $(basename $@)))))
	python code/concat_pipeline_auc_output.py --taxonomy $(L) --model $(M)


################################################################################
#
# Part 7: Quantify statistics make summary tables
#
#	Calculate p-values using a permutaiton based method from Begum to compare
#	difference in mean AUC values between models/taxonomic levels.
#
################################################################################

METHOD=rpart2 rf glmnet svmRadial xgbTree
LEVEL=phylum class order family genus otu asv

#produce files of pvalues comparing tax levels within model and between models
analysis/pvalues_by_level.csv analysis/pvalues_by_model.csv: \
			code/R/calculate_pvalues.R \
			$(foreach L,$(LEVEL),$(foreach M,$(METHOD),data/process/combined-$L-$M.csv))
	Rscript code/R/calculate_pvalues.R

# produce summary table of number of samples and features by level
analysis/input_values.csv : code/R/quantify_input_values.R \
			$(foreach L,$(LEVEL),data/$L/input_data.csv) \
			$(foreach L,$(LEVEL),data/$L/input_data_preproc.csv)
	Rscript code/R/quantify_input_values.R

# summary of prevalence values
analysis/prevalence_by_level.csv: \
			code/R/summarize_prevalence.R
			$(foreach L,$(LEVEL),data/$L/input_data.csv) \
			$(foreach L,$(LEVEL),data/$L/input_data_preproc.csv)
	Rscript code/R/summarize_prevalence.R

################################################################################
#
# Part 8: Merge Importance
#
#	Generate concatenated importance tables for each level and method
#
################################################################################

MERGE=$(foreach L,$(LEVEL),$(foreach M,$(METHOD), data/process/importance-$(L)-$(M).csv))
SEED:=$(shell seq 100)

.SECONDEXPANSION:
$(MERGE) : \
			code/R/merge_importance.R \
			$(foreach S,$(SEED), data/$$(word 2,$$(subst -, ,$$(notdir $$(basename $$@))))/temp/importance_$$(word 3,$$(subst -, ,$$(notdir $$(basename $$@)))).$(S).csv)
	$(eval M=$(word 3,$(subst -, ,$(notdir $(basename $@)))))
	$(eval L=$(word 2,$(subst -, ,$(notdir $(basename $@)))))
	Rscript code/R/merge_importance.R --level=$(L) --method=$(M)

################################################################################
#
# Part 9: Merge Hyperparamter Performance
#
#	Generate concatenated hyperparameter tables for each level and method
#
################################################################################

MERGE=$(foreach L,$(LEVEL),$(foreach M,$(METHOD), data/process/hp-$(L)-$(M).csv))
SEED:=$(shell seq 100)

.SECONDEXPANSION:
$(MERGE) : \
			code/R/merge_hyperparameters.R \
			$(foreach S,$(SEED), data/$$(word 2,$$(subst -, ,$$(notdir $$(basename $$@))))/temp/hp_$$(word 3,$$(subst -, ,$$(notdir $$(basename $$@)))).$(S).csv)
	$(eval M=$(word 3,$(subst -, ,$(notdir $(basename $@)))))
	$(eval L=$(word 2,$(subst -, ,$(notdir $(basename $@)))))
	Rscript code/R/merge_hyperparameters.R --level=$(L) --method=$(M)

################################################################################
#
# Part 10: Plot Hyperparamter Performance
#
#	Generate plots of hyperparameter performance for each level and method
#
################################################################################

HPPLOT=$(foreach M,$(METHOD), analysis/hp-$(M).png)

.SECONDEXPANSION:
$(HPPLOT) : \
			code/R/plot_hp_performance.R \
			$(foreach L,$(LEVEL), data/process/hp-$(L)-$$(word 2,$$(subst -, ,$$(notdir $$(basename $$@)))).csv)
	$(eval M=$(word 2,$(subst -, ,$(notdir $(basename $@)))))
	Rscript code/R/plot_hp_performance.R --method=$(M)


################################################################################
#
# Part X: Plot model performance
#
#	Generate boxplots comparing model performace
#
################################################################################

auc_by_model.png : \
			analysis/pvalues_by_level.csv \
			analysis/pvalues_by_model.csv
	Rscript plot_auc.R


################################################################################
#
# Part X: DADA2 ASV Comparison
#
#	Generate ASV table with DADA2 and quantify performance
#
################################################################################

# merge fastqfiles by sample
data/raw/merged : \
			data/raw/data.files \
			code/merge_fastq.pl
	perl code/merge_fastq.pl data/raw/data.files

#download reference files for dada2
OUTPATH = data/dada2/
data/dada2/silva_% :
	mkdir -p $(OUTPATH)
	wget -N -P $(OUTPATH) https://zenodo.org/record/1172783/files/silva_nr_v132_train_set.fa.gz
	wget -N -P $(OUTPATH) https://zenodo.org/record/1172783/files/silva_species_assignment_v132.fa.gz

#run dada2 pipeline to generate asv table
data/dada2/asv_table.tsv : \
			code/R/dada2.R \
			data/dada2/silva_nr_v132_train_set.fa.gz  \
			data/dada2/silva_species_assignment_v132.fa.gz
	Rscript code/R/dada2.R

#format dada2 asv table as .shared file
data/dada2/asv_table.shared : \
			code/R/make_dada2_shared.R \
			data/dada2/asv_table.tsv
	Rscript code/R/make_dada2_shared.R

#subsample to be consistent with Mothur
data/dada2/asv_table.dada2.subsample.shared : \
			code/bash/dada2_subsample.sh \
			data/dada2/asv_table.shared
	bash code/bash/dada2_subsample.sh

#merge with metadata and format for mikropml
data/dada2/input_data.csv : \
			data/dada2/asv_table.dada2.subsample.shared \
			data/metadata/metadata.csv \
			code/R/merge_metadata_dada2.R
	Rscript code/R/merge_metadata_dada2.R

#preprocess input data
data/dada2/input_data_preproc.csv: \
				code/R/preprocess_data.R \
				data/dada2/input_data.csv
	Rscript code/R/preprocess_data.R --data=data/dada2/input_data.csv --taxonomy=dada2

#run the models
LEVEL=dada2
METHOD=rpart2 rf glmnet svmRadial xgbTree
SEED:=$(shell seq 100)
BEST_RESULTS=$(foreach L,$(LEVEL),$(foreach M,$(METHOD),$(foreach S,$(SEED), data/$L/temp/$M.$S.csv)))

.SECONDEXPANSION:
$(BEST_RESULTS) : code/R/run_model_dada2.R \
			data/$$(word 2,$$(subst /, ,$$(dir $$@)))/input_data_preproc.csv
	$(eval S=$(subst .,,$(suffix $(basename $@))))
	$(eval M=$(notdir $(basename $(basename $@))))
	$(eval L=$(subst temp,,$(subst /,,$(subst data/,,$(dir $@)))))
	Rscript --max-ppsize=500000 code/R/run_model_dada2.R --data=data/$L/input_data_preproc.csv --method=$M --taxonomy=$L --outcome_colname=dx --outcome_value=cancer --seed=$S

# merge the data
METHOD=rpart2 rf glmnet svmRadial xgbTree
LEVEL=dada2
CONCAT=$(foreach L,$(LEVEL),$(foreach M,$(METHOD), data/dada2/process/combined-$(L)-$(M).csv))
SEED:=$(shell seq 100)

.SECONDEXPANSION:
$(CONCAT) : \
			code/concat_pipeline_auc_output_dada2.py \
			$(foreach S,$(SEED), data/$$(word 2,$$(subst -, ,$$(notdir $$(basename $$@))))/temp/$$(word 3,$$(subst -, ,$$(notdir $$(basename $$@)))).$(S).csv)
	$(eval M=$(word 3,$(subst -, ,$(notdir $(basename $@)))))
	$(eval L=$(word 2,$(subst -, ,$(notdir $(basename $@)))))
	mkdir -p data/dada2/process/
	python code/concat_pipeline_auc_output_dada2.py --taxonomy $(L) --model $(M)

#summarize input input_values
data/dada2/process/summary_input_values.csv : code/R/quantify_input_values_dada2.R \
			data/dada2/input_data.csv \
			data/dada2/input_data_preproc.csv
	Rscript code/R/quantify_input_values_dada2.R

# calculate statistics
METHOD=rpart2 rf glmnet svmRadial xgbTree
data/dada2/analysis/dada2_pvalues_by_level.csv data/dada2/analysis/dada2_pvalues_by_model.csv : \
			code/R/calculate_pvalues_dada2.R \
			$(foreach M,$(METHOD),data/process/combined-asv-$M.csv)
			$(foreach M,$(METHOD),data/dada2/process/combined-dada2-$M.csv)
	Rscript code/R/calculate_pvalues_dada2.R

################################################################################
#
# Make manuscript and exploratory document
#
################################################################################

docs/exploratory.html :
	R -e 'rmarkdown::render("exploratory/exploratory.Rmd",output_dir="docs")'

paper/manuscript.pdf paper/manuscript.docx : paper/manuscript.Rmd
	R -e 'library(rmarkdown);render("paper/manuscript.Rmd",output_format="all")'
