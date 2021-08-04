#!/bin/bash
###############################
#                             #
#  1) Job Submission Options  #
#                             #
###############################
# Name
#SBATCH --job-name=rf_merge
# Resources
# For MPI, increase ntasks-per-node
# For multithreading, increase cpus-per-task
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=12
#SBATCH --mem-per-cpu=5GB
#SBATCH --time=20:00:00
# Account
#SBATCH --account=pschloss1
#SBATCH --partition=standard
# Logs
#SBATCH --mail-user=armourc@umich.edu
#SBATCH --mail-type=FAIL
#SBATCH --output=slurm_logs/%x-%a-%j.out
# Environment
#SBATCH --export=ALL

#####################
#                   #
#  2) Job Commands  #
#                   #
#####################

make data/process/combined-phylum-rf.csv
make data/process/combined-class-rf.csv
make data/process/combined-order-rf.csv
make data/process/combined-family-rf.csv
make data/process/combined-genus-rf.csv
make data/process/combined-otu-rf.csv
make data/process/combined-asv-rf.csv

make data/process/hp-phylum-rf.csv
make data/process/hp-class-rf.csv
make data/process/hp-order-rf.csv
make data/process/hp-family-rf.csv
make data/process/hp-genus-rf.csv
make data/process/hp-otu-rf.csv
make data/process/hp-asv-rf.csv

make data/process/importance-phylum-rf.csv
make data/process/importance-class-rf.csv
make data/process/importance-order-rf.csv
make data/process/importance-family-rf.csv
make data/process/importance-genus-rf.csv
make data/process/importance-otu-rf.csv
make data/process/importance-asv-rf.csv

make data/process/importance90-phylum-rf.csv
make data/process/importance90-class-rf.csv
make data/process/importance90-order-rf.csv
make data/process/importance90-family-rf.csv
make data/process/importance90-genus-rf.csv
make data/process/importance90-otu-rf.csv
make data/process/importance90-asv-rf.csv

make data/process/probability-phylum-rf.csv
make data/process/probability-class-rf.csv
make data/process/probability-order-rf.csv
make data/process/probability-family-rf.csv
make data/process/probability-genus-rf.csv
make data/process/probability-otu-rf.csv
make data/process/probability-asv-rf.csv

make data/process/senspec-phylum-rf.csv
make data/process/senspec-class-rf.csv
make data/process/senspec-order-rf.csv
make data/process/senspec-family-rf.csv
make data/process/senspec-genus-rf.csv
make data/process/senspec-otu-rf.csv
make data/process/senspec-asv-rf.csv
