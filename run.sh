#!/bin/bash
###############################
#                             #
#  1) Job Submission Options  #
#                             #
###############################
# Name
#SBATCH --job-name=L2_Logistic_Regression
# Resources
# For MPI, increase ntasks-per-node
# For multithreading, increase cpus-per-task
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=10GB
#SBATCH --time=200:00:00
# Account
#SBATCH --account=pschloss99
#SBATCH --partition=standard
# Logs
#SBATCH --mail-user=armourc@med.umich.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=slurm_logs/%x-%a-%j.out
# Environment
#SBATCH --export=ALL
# Array
#SBATCH --array=1-100
# vector index starts at 0 so shift array by one
seed=$(($SLURM_ARRAY_TASK_ID - 1))
#####################
#                   #
#  2) Job Commands  #
#                   #
#####################

#mkdir -p logs/slurm/
#Rscript code/R/main.R --seed $seed --model Random_Forest --taxonomy asv --data data/asv/input_data.csv --hyperparams data/default_hyperparameters.csv --outcome dx

#make data/phylum/L2_Logistic_Regression.${seed}.csv

for method in L2_Logistic_Regression Decision_Tree L1_Linear_SVM L2_Linear_SVM Random_Forest RBF_SVM XGBoost
do 
	for level in kingdom phylum class order family genus otu asv
	do 
		echo make -n data/${level}/${method}.${seed}.csv
	done
done 
