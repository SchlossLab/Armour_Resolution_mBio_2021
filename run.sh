#!/bin/bash
###############################
#                             #
#  1) Job Submission Options  #
#                             #
###############################
# Name
#SBATCH --job-name=DT8_logit
# Resources
# For MPI, increase ntasks-per-node
# For multithreading, increase cpus-per-task
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=8GB
#SBATCH --time=150:00:00
# Account
#SBATCH --account=pschloss1
#SBATCH --partition=standard
# Logs
#SBATCH --mail-user=agarret@med.umich.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=%x-%j.out
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
###################### Making output dir for snakemake cluster logs
mkdir -p logs/slurm/
Rscript code/R/main.R --seed $seed --model Decision_Tree --taxonomy asv --data data/asv/input_data.csv --hyperparams data/default_hyperparameters.csv --outcome dx
