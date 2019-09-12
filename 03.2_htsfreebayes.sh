#!/usr/bin/env bash

#SBATCH --job-name=execute_snp_calling
#SBATCH --array=1-NUMBER
#SBATCH --nodes 1
#SBATCH --ntasks 1
#SBATCH --time 00:10:00
#SBATCH --mem=1GB
#SBATCH -o arrayJob_%A_%a.out
#SBATCH -p production

# Change NUMBER in line 4 to the total number of chromosomes in your organism (also the result of `wc -l < chromosome_lengths.txt`)

echo "My SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
number=$(sed "${SLURM_ARRAY_TASK_ID}q;d" chromosome_lengths.txt | cut -f1)

cd ${number}
sbatch ${number}.freebayes.sh
