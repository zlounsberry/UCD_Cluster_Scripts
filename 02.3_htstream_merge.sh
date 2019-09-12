#!/usr/bin/env bash

#SBATCH --job-name=HTS_Merge
#SBATCH --array=1-NUMBER
#SBATCH --nodes=1
#SBATCH --ntasks=2
#SBATCH --time=1-12:00:00
#SBATCH --mem-per-cpu=16GB
#SBATCH -o arrayJob_%A_%a.out
#SBATCH -p production

# Here, samples_merge.txt just comes from `cut -f4 samples_align.txt | sort -u | grep -v SE > samples_merge.txt`
# Number of arrays is `wc -l < samples_merge.txt`

# Once this is done, NUMBER in the array line above needs to be changed to the result of `wc -l < samples_merge.txt`

echo "My SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
sample=$(sed "${SLURM_ARRAY_TASK_ID}q;d" samples_merge.txt | cut -f1)
echo ${sample}

#load samtools module
module load samtools
mkdir merged
mkdir sorted
samtools merge merged/${sample}.bam ${sample}_*.bam
samtools sort merged/${sample}.bam -o sorted/${sample}.htstream.merged.bam
samtools index sorted/${sample}.htstream.merged.bam
rm ${sample}*.bam merged/${sample}*.bam
