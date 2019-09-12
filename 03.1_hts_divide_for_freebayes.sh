#!/usr/bin/env bash

#SBATCH --job-name=hts_snps
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
length=$(sed "${SLURM_ARRAY_TASK_ID}q;d" chromosome_lengths.txt | cut -f2)

mkdir ${number}
mkdir ${number}/freebayes
mkdir ${number}/samtools

# Split into 100kb chunks
for count in $(seq 1 100000 ${length}); do
	upper=$(echo "${count} + 100000" | bc)
	echo -e "${number}\t${count}\t${upper}"
done > ${number}/ranges.txt

lines=$(wc -l < ${number}/ranges.txt)

echo "#!/usr/bin/env bash

#SBATCH --job-name=hts_snps
#SBATCH --array=1-${lines}
#SBATCH --nodes 1
#SBATCH --ntasks 1
#SBATCH --time 03:00:00
#SBATCH --mem=2GB
#SBATCH -o arrayJob_%A_%a.out
#SBATCH -p production

# load the modules
module load freebayes

echo \"My SLURM_ARRAY_TASK_ID: \" $SLURM_ARRAY_TASK_ID
start=\$(sed \"\${SLURM_ARRAY_TASK_ID}q;d\" ranges.txt | cut -f2)
end=\$(sed \"\${SLURM_ARRAY_TASK_ID}q;d\" ranges.txt | cut -f3)
echo \"Processing ${number} at \${start}-\${end}\"

freebayes -f [REFERENCE FASTA] --min-alternate-fraction 0.3 --region ${number}:\${start}-\${end} sorted/*.bam > freebayes/${number}.\${start}-\${end}.vcf
samtools mpileup -uf [REFERENCE FASTA] -r ${number}:\${start}-\${end} sorted/*.bam | bcftools view -cg - > samtools/${number}.\${start}-\${end}.vcf
" > ${number}/${number}.freebayes.sh
