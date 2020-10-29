#!/bin/bash
###############################
#                             #
#  1) Job Submission Options  #
#                             #
###############################
# Name
#SBATCH --job-name=prepdata
# Resources
# For MPI, increase ntasks-per-node
# For multithreading, increase cpus-per-task
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=100GB
#SBATCH --time=200:00:00
# Account
#SBATCH --account=pschloss99
#SBATCH --partition=standard
# Logs
#SBATCH --mail-user=armourc@med.umich.edu
#SBATCH --mail-type=END,FAIL
#SBATCH --output=slurm_logs/%x-%a-%j.out
# Environment
#SBATCH --export=ALL

#####################
#                   #
#  2) Job Commands  #
#                   #
#####################

source /etc/profile.d/http_proxy.sh  # required for internet on the Great Lakes cluster
make data/references/silva.v4.%
make data/trainset16_022016.pds.%
make data/mothur/crc.fasta

make data/phylum/crc.shared
make data/phylum/input_data.csv
make data/phylum/input_data_preproc.csv

make data/class/crc.shared
make data/class/input_data.csv
make data/class/input_data_preproc.csv

make data/order/crc.shared
make data/order/input_data.csv
make data/order/input_data_preproc.csv

make data/family/crc.shared
make data/family/input_data.csv
make data/family/input_data_preproc.csv

make data/genus/crc.shared
make data/genus/input_data.csv
make data/genus/input_data_preproc.csv

make data/otu/crc.shared
make data/otu/input_data.csv
make data/otu/input_data_preproc.csv

make data/asv/crc.shared
make data/asv/input_data.csv
#make data/asv/input_data_preproc.csv
