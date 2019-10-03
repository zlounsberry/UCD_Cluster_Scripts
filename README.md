Below, you would replace /PATH/DateCode_Project with your directory name on the cluster.<br />
For example, `sed -i 's/PATH/share\/[LabID]/g'` would change this README to a copy/pasta usable version that would make this project happen in your lab share.<br />
Note there is a bit of hard-coding in here (e.g., 03 scripts that call specific chromosome ID's that may not be present in your reference data...)<br />
This is primarily designed for the equine research unit at the VGL but can be adapted to your system if you know a little of BASH... Good luck!<br />

# Directory Structure:
```
mkdir /PATH/DateCode_Project
mkdir /PATH/DateCode_Project/01_HTStream
mkdir /PATH/DateCode_Project/02_Aligned
mkdir /PATH/DateCode_Project/03_Call_Variants
```
# Pipeline:

## Step 1 - HTStream
#### Directory = /PATH/DateCode_Project/01_HTStream
#### Fastq files in any directory you want (with `_R1_001.fastq.gz` and `_R2_001.fastq.gz` extensions!)
#### Files needed in working directory = `samples.txt` 
This is a file containing 2 columns (tab-delimited) containing the path to your fastq data and the sample IDs for those samples. 
_NOTE: Keep the suffix on the fastq file (e.g., the S50_L001 on `sample1_S50_L001` that comes typically with Illumina data just in case you have more than one barcode for the same sample ID)._

#### Example:
```
user@cluster:/PATH/DateCode_Project/01_HTStream$ cat samples.txt
/PATH_TO_FASTQ_DATA/     Only_Sample_S10_L002
```

#### Once you have samples.txt in /PATH/DateCode_Project/01_HTStream, you can run:
```
sbatch 01_htstream_clean.sh
```
while in the `/PATH/DateCode_Project/01_HTStream` directory to clean your data.

## Step 2.1 - Split cleaned fastq
#### Directory = /PATH/DateCode_Project/02_Aligned
#### Fastq files (cleaned with HTStream) in `/PATH/DateCode_Project/01_HTStream` (which here needs to be the same as `../01_HTStream`)
#### Files needed in working directory = `samples_split.txt` 
##### `samples_split.txt` is a 1-column file containing sample names
##### You can make `samples_split.txt` using `awk '{print $2}' /PATH/DateCode_Project/01_HTStream/samples.txt`.

To run, make sure you are in the `/PATH/DateCode_Project/02_Align` directory, change NUMBER in the array=1-NUMBER (line 4) in 02.1_htstream_split_fastq.sh to be the result of `wc -l < samples_split.txt`, and then execute:
```
sbatch 02.1_htstream_split_fastq.sh
```

## Step 2.2 - Align split fastq files
#### Directory = /PATH/DateCode_Project/02_Aligned
#### Fastq files (split in step 2.1) in /PATH/DateCode_Project/02_Aligned
#### Files needed in working directory = `samples_align.txt` 
##### `samples_align.txt` is a 4-column file containing various bits of information for each split fastq
###### `samples_align.txt` is created by running this in the current directory:
```
cat <(paste <(ls *.R10*.fastq.gz) \
	<(ls *.R20*.fastq.gz) \
	<(ls *.R10*.fastq.gz | sed 's/.fastq.gz//g') \
	<(ls *.R10*.fastq.gz | sed 's/_S.*//g')) \
	<(paste <(ls *.SE0*.fastq.gz) \
	<(ls *.SE0*.fastq.gz | sed 's/.*.//g') \
	<(ls *.SE0*.fastq.gz | sed 's/.fastq.gz//g') \
	<(ls *.SE0*.fastq.gz | sed 's/_S.*//g')) > samples_align.txt
```
_NOTE: If your sample ID has \_R20, \_R10 or \_SE0 before the fastq suffix, you will have to alter this (or it will probably keep over-writing files)!_

Once this is made, change NUMBER in line 4 of 02.2_htstream_align.sh to the result of `wc -l < samples_align.txt`, then run: 
```
sbatch 02.2_htstream_align.sh
```
while in the `/PATH/DateCode_Project/02_Align` directory.

## Step 2.3 - Merge split alignment files
#### Directory = /PATH/DateCode_Project/02_Aligned
#### BAM files (aligned in step 2.2) in /PATH/DateCode_Project/02_Aligned
#### Files needed in working directory = `samples_merge.txt` 
##### `samples_merge.txt` is a 1-column file containing sample IDs
###### `samples_merge.txt` is created by running this in the current directory:
```
cut -f4 samples_align.txt | sort -u | grep -v SE > samples_merge.txt
```
To run, change NUMBER in line 4 of 02.3_htstream_merge.sh to the result of `wc -l < samples_merge.txt`, then run: 
```
sbatch 02.3_htstream_merge.sh
```
while in the `/PATH/DateCode_Project/02_Align` directory.

## Step 3.1 - Create variant calling scripts and directory structure
#### Directory = /PATH/DateCode_Project/03_Call_Variants
#### Files needed in working directory = `chromosome_lengths.txt` 
##### This is a 2-column (tab-delimited) text file containing chromosome ID (matching ref genome) in column 1 and the length of that chromosome in column 2
Example (in an equCab3.0 fasta that I changed chr names to chr1-chrn):
```
user@cluster:/PATH/DateCode_Project/03_Call_Variants$ head -n 5 chromosome_lengths.txt
chr1	188260577
chr2	121350024
chr3	121351753
chr4	109462549
chr5	96759418
```
To run, change NUMBER in line 4 of 03.1_hts_divide_for_freebayes.sh to the result of `wc -l < chromosome_lengths.txt`, then run: 
```
sbatch 03.1_hts_divide_for_freebayes.sh
```
while in the `/PATH/DateCode_Project/03_Call_Variants` directory.

## Step 3.2 - Call variants using freebayes/samtools mpileup on thousands of subsets of the genome (RIP your cluster user priority)
#### Directory = /PATH/DateCode_Project/03_Call_Variants
#### BAM files (merged in step 2.3) in /PATH/DateCode_Project/02_Aligned
#### Files needed in working directory = `chromosome_lengths.txt` 
##### This is a 2-column (tab-delimited) text file containing chromosome ID (matching ref genome) in column 1 and the length of that chromosome in column 2

To run, change NUMBER in line 4 of 03.2_htsfreebayes.sh to the result of `wc -l < chromosome_lengths.txt`, then run:
```
sbatch 03.2_htsfreebayes.sh
```
while in the `/PATH/DateCode_Project/03_Call_Variants` directory.

## Step 3.3 - Merge chr-specific vcf subsets into single vcfs per chromosome 
### (Be prepared to wait in the queue a bit for this, your priority is likely in bad shape and everyone is probably a little mad at you. Just a little though. Hey chin up you're doing great!)
#### Directory = /PATH/DateCode_Project/03_Call_Variants
#### VCF files (created in step 3.2) in /PATH/DateCode_Project/03_Aligned
#### Files needed in working directory = `chromosome_lengths.txt`

To run, change NUMBER in line 4 of 03.3_Concatenate_and_add_IDs_vcfs.sh to the result of `wc -l < chromosome_lengths.txt`, then run: 
```
sbatch 03.3_Concatenate_and_add_IDs_vcfs.sh
```
while in the `/PATH/DateCode_Project/03_Call_Variants` directory.

## Step 3.4 - Merge chr-specific vcfs into a single vcf. The final step!
#### Directory = /PATH/DateCode_Project/03_Call_Variants
#### VCF files (created in step 3.3) in /PATH/DateCode_Project/03_Aligned

To run: 
```
sbatch 03.4_Concatenate_vcfs_All.sh
```
while in the `/PATH/DateCode_Project/03_Call_Variants` directory.

_NOTE: Some chunks will be missing. If the variant caller runs into an issue with a repetitive or otherwise low-complexity region, it may stall out. That region may time out, fail, etc. but the rest of the genome will run fine. To figure out which regions you are missing (and determine if you want to rescue them), try `grep -i canc */*out` in the `/PATH/DateCode_Project/03_Call_Variants` directory. Every slurm outfile with a cancel job will correspond to a region:_

```
user@cluster:/PATH/DateCode_Project/03_Call_Variants$ grep CANC */*out
chr10/arrayJob_1199087_275.out:slurmstepd: error: *** JOB 1201694 ON fleet-34 CANCELLED AT 2019-07-01T16:28:11 ***
chr10/arrayJob_1199087_287.out:slurmstepd: error: *** JOB 1201706 ON fleet-5 CANCELLED AT 2019-07-01T16:35:12 ***
chr10/arrayJob_1199087_288.out:slurmstepd: error: *** JOB 1201707 ON fleet-3 CANCELLED AT 2019-07-01T16:32:12 ***
```
