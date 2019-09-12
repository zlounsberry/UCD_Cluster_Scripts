#!/usr/bin/env bash

#SBATCH --job-name=split_align
#SBATCH --array=1-NUMBER
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=2-12:00:00
#SBATCH --mem-per-cpu=8GB
#SBATCH -o arrayJob_%A_%a.out
#SBATCH -p production

# This script assumes 01_htstream_clean.sh has been run and you're in the 02_Align directory.

# samples_split.txt is a 1-column txt file with sample IDs.
# You can make this by `awk '{print $2}' ../01_HTStream/samples.txt > samples_split.txt`

# the NUMBER in the array line above needs to be changed to the result of `wc -l < samples_split.txt`

echo "My SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID

sample=$(sed "${SLURM_ARRAY_TASK_ID}q;d" samples_split.txt)
echo ${sample}

# Split the file into 4-million-sequence files and move into its respective directory
zcat ../01_HTStream/${sample}.htstream_R1.fastq.gz | split -a 4 -l 8000000 -d --additional-suffix=".fastq" - ${sample}.R1
zcat ../01_HTStream/${sample}.htstream_R2.fastq.gz | split -a 4 -l 8000000 -d --additional-suffix=".fastq" - ${sample}.R2
zcat ../01_HTStream/${sample}.htstream_SE.fastq.gz | split -a 4 -l 8000000 -d --additional-suffix=".fastq" - ${sample}.SE

# gzip each fq file
gzip ${sample}*fastq
