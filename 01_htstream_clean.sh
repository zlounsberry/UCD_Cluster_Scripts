#!/usr/bin/env bash

#SBATCH --job-name=HTStream
#SBATCH --array=1
#SBATCH --nodes 1
#SBATCH --ntasks 9
#SBATCH --time=1-00:00:00
#SBATCH --mem=200GB
#SBATCH -o arrayJob_%A_%a.out
#SBATCH -p production

# This script assumes paired-end data
# samples.txt is a 2-column txt file. Column 1 is the path to the data. Column 2 is the sample ID (should match fastq file label). Check out R1 and R2 below and make sure they have the correct suffixes.

# load the htstream module
module load htstream/1.0.0

# Print the array number, define variables, and print the full path to the file you requested.
echo "My SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
datapath=$(sed "${SLURM_ARRAY_TASK_ID}q;d" samples.txt | cut -f1)
sample=$(sed "${SLURM_ARRAY_TASK_ID}q;d" samples.txt | cut -f2)
echo "Running HTStream on ${datapath}${sample}"

# Run HTStream on each fastq file (following Matt's instructions, need to go back and make sure these are best parameters for our data...
hts_Stats -O -L ${sample}_htsStats.log -1 ${datapath}${sample}_R1_001.fastq.gz -2 ${datapath}${sample}_R2_001.fastq.gz | \
hts_SeqScreener -S -O -A -L ${sample}_htsStats.log | \
hts_SuperDeduper -e 2500000 -S -O -A -L ${sample}_htsStats.log | \
hts_Overlapper -n -S -O -A -L ${sample}_htsStats.log | \
hts_NTrimmer -n -S -O -A -L ${sample}_htsStats.log | \
hts_QWindowTrim -n -S -O -A -L ${sample}_htsStats.log | \
hts_CutTrim -n -m 50 -S -O -A -L ${sample}_htsStats.log | \
hts_Stats -S -A -L ${sample}_htsStats.log -g -p ${sample}.htstream
