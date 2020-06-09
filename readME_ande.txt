### Running the pipeline in the XXXX_Resolution GL repo ####
	run.sh file
		edit command within file based on model and taxonomy level
	model options:
		L2_Logistic_Regression
		RBF_SVM
		Random_Forest
		XGBoost
		Decision_Tree
		L1_Linear_SVM (could not be run due to caret file issues - contact begum)
		L2_Linear_SVM (could not be run due to caret file issues - contact begum) 
	tax level options:
		phylum
		order
		class
		family
		genus
		otu
		asv		
	Rscript command in run.sh
		Rscript code/R/main.R --seed $seed --model [insert model name] --data data/[insert tax level]/input_data.csv --hyperparams data/default_hyperparameters.csv --taxonomy [insert tax level] --outcome dx
	Run the pipeline
		>module load R
		>module load Bioinformatics
		>sbatch run.sh

### Location of results ###
	Logit files
		logit files are for the runs are located in logit_files/[model]/[tax level]_logit
	traintime files
		data/temp/traintime_files/[model]/[tax level]_traintime
	best_hp files
		data/temp/[tax level]

### What has been completed & still needs to be finished ###
	L2_Logistic_regression: all tax levels completed
	RBF_SVM: all tax levels completed
	Decision_Tree: all tax levels completed
	Random_Forest: asv still needs to be completed
		the last run hit the maxwall time at 200hrs - upped mem to 10GB and 300hrs and rerunning
	XGBoost: asv still needs to be completed
		seeds 73 and 74 didn't work on the last run
		unsure why this is
		upped the mem to 10GB (from 8GB) and upped the walltime to 200hr (not sure if this will fix the issue or not)
		logit files will now be able to be identified by seed so this next run may tell us what is going on by looking at the specific logit files)
	L1_Linear_SVM: none
		contact begum
	L2_Linear_SVM: none
		contact begum

### Concatenating auc values for all seeds ###
	python script was written to concatenate all the 100 seed results 
	to run script:
		>python code/concat_pipeline_auc_output.py --model [insert model] --taxonomy [insert tax level]
	files are saved in data/process and designated in the file name by the model and tax levels they associate with

### Plot the auc values to get a box and whisker plot of the data by model ####
	Rscript was written to produce a .png file
	to run script:
		>module load R
		>Rscript code/plot_auc_by_taxonomy.R [insert model]
	.png files will be saved in the folder 'figures' and named based on the model 
