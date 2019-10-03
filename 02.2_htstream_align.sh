#!/usr/bin/env bash

#SBATCH --job-name=HTS_Align_Split
#SBATCH --array=1-NUMBER
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=12:00:00
#SBATCH --mem-per-cpu=8GB
#SBATCH -o arrayJob_%A_%a.out
#SBATCH -p production

# To create samples_align.txt, once the previous set of jobs in finished, do:
# cat <(paste <(ls *R10*.fastq.gz) <(ls *R20*.fastq.gz) <(ls *R10*.fastq.gz | sed 's/.fastq.gz//g') <(ls *R10*.fastq.gz | sed 's/_S.*//g')) <(paste <(ls *SE0*.fastq.gz) \
#	<(ls *SE0*.fastq.gz | sed 's/.*.//g') <(ls *SE0*.fastq.gz | sed 's/.fastq.gz//g') <(ls *SE0*.fastq.gz | sed 's/_S.*//g')) > samples_align.txt

# Once this is done, change NUMBER in line 4 above to be the result of `wc -l < samples_align.txt`

echo "My SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
R1=$(sed "${SLURM_ARRAY_TASK_ID}q;d" samples_align.txt | awk -F"	" '{print $1}')
R2=$(sed "${SLURM_ARRAY_TASK_ID}q;d" samples_align.txt | awk -F"	" '{print $2}')
sample=$(sed "${SLURM_ARRAY_TASK_ID}q;d" samples_align.txt | awk -F"	" '{print $3}')
ID=$(sed "${SLURM_ARRAY_TASK_ID}q;d" samples_align.txt | awk -F"	" '{print $4}')
echo ${sample}

# load the bwa module
module load bwa

# Align R1 and R2 (for SE, because ${R2} returns a tab, it will simply run the R1, which will be the SE data)
# Swap out [REFERENCE FASTA] for the path to your indexed reference sequence
# If it's not yet indexed, use `bwa index [REFERENCE FASTA]` to solve that.
bwa mem -R "@RG\tID:${ID}\tSM:${ID}" [REFERENCE FASTA] ${R1} ${R2} > ${sample}.sam

# load samtools module
module load samtools
samtools view -q 10 -h -bS ${sample}.sam -o ${sample}.bam
rm ${sample}.sam ${R1} ${R2}
