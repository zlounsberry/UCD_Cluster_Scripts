#!/usr/bin/env bash
#SBATCH --job-name=Combine_VCF
#SBATCH --nodes 1
#SBATCH --ntasks 1
#SBATCH --time 06:00:00
#SBATCH --mem=16GB
#SBATCH -p production

set -x

cat <(grep "#" chr1/freebayes/chr1.100001-200001.vcf) <(for number in $(seq 1 1 31); do grep -v "#" chr${number}/chr${number}.freebayes.WithIDs.vcf; done) <(grep -v "#" chrX/chrX.freebayes.WithIDs.vcf) > All_Combined.freebayes.WithIDs.vcf
cat <(grep "#" chr1/samtools/chr1.100001-200001.vcf) \
	<(for number in $(seq 1 1 31); do grep -v "#" chr${number}/chr${number}.samtools.WithIDs.vcf | awk '$5!="." {print}'; done) \
	<(grep -v "#" chrX/chrX.samtools.WithIDs.vcf | awk '$5!="." {print}') > All_Combined.samtools.WithIDs.vcf
