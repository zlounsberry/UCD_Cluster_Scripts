#!/usr/bin/env bash
#SBATCH --job-name=Combine_VCF
#SBATCH --array=1-NUMBER
#SBATCH --nodes 1
#SBATCH --ntasks 1
#SBATCH --time 02:00:00
#SBATCH --mem=8GB
#SBATCH -o arrayJob_%A_%a.out
#SBATCH -p production

# Change NUMBER in line 4 to the total number of chromosomes in your organism (also the result of `wc -l < chromosome_lengths.txt`)

echo "My SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
number=$(sed "${SLURM_ARRAY_TASK_ID}q;d" chromosome_lengths.txt | cut -f1)

#Used the second of two commands below, which has SNP ID's, here. freebayes commented out so I could re-run samtools and fix the monomorphic calls.

cat <(grep "#" ${number}/freebayes/${number}.1-100001.vcf) <(grep --no-filename -v "#" ${number}/freebayes/*vcf | sort -n -k2) > ${number}/freebayes/${number}.vcf
cat <(grep "#" ${number}/freebayes/${number}.vcf) <(paste <(grep -v "#" ${number}/freebayes/${number}.vcf | cut -f1,2) <(grep -v "#" ${number}/freebayes/${number}.vcf | awk '{print $1"_"$2}') <(grep -v "#" ${number}/freebayes/${number}.vcf | cut -f4-)) > ${number}/${number}.freebayes.WithIDs.vcf

cat <(grep "#" ${number}/samtools/${number}.1-100001.vcf) <(grep --no-filename -v "#" ${number}/samtools/*vcf | sort -n -k2) > ${number}/samtools/${number}.vcf
cat <(grep "#" ${number}/samtools/${number}.vcf) <(paste <(grep -v "#" ${number}/samtools/${number}.vcf | cut -f1,2) <(grep -v "#" ${number}/samtools/${number}.vcf | awk '{print $1"_"$2}') <(grep -v "#" ${number}/samtools/${number}.vcf | cut -f4-)) | awk '$5!="." {print}' > ${number}/${number}.samtools.WithIDs.vcf
