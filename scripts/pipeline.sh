cd /home/user05/DECONT/decont
export WD=$(pwd)

#Download all the files specified in data/urls
echo "Downloading the files..."
for url in $(cat data/urls) #TODO
do
    bash scripts/download.sh $url data
done
#bonus: wget -i data/urls -P data/

# Download the contaminants fasta file, and uncompress it
echo "Downloading the contaminants fasta files and uncompress it..."
bash scripts/download.sh https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz res yes
gunzip -k res/contaminants.fasta.gz #TODO

# Index the contaminants file
echo "Running index..."
bash scripts/index.sh res/contaminants.fasta res/contaminants_idx/

# Merge the samples into a single file
echo "Running Merge..."
mkdir -p out/merged
for sid in $(ls data/*.fastq.gz | cut -d"-" -f1 | sed 's:data/::' | sort | uniq) #TODO
do
   bash scripts/merge_fastqs.sh data out/merged $sid
done

# TODO: run cutadapt for all merged files
echo "Running cutadapt..."
mkdir -p out/trimmed
mkdir -p log/cutadapt
for sampleid in $(ls out/merged/*.fastq.gz | cut -d"." -f1 | sed 's:out/merged/::' | sort)
do
cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed -o out/trimmed/${sampleid}.trimmed.fastq.gz out/merged/${sampleid}.fastq.gz > log/cutadapt/${sampleid}.log
done

#TODO: run STAR for all trimmed files
echo "Running STAR..."
for fname in out/trimmed/*.fastq.gz
do
    # you will need to obtain the sample ID from the filename
    sid=$(basename $fname .trimmed.fastq.gz)
    mkdir -p out/star/$sid
    STAR --runThreadN 4 --genomeDir res/contaminants_idx --outReadsUnmapped Fastx --readFilesIn out/trimmed/${sid}.trimmed.fastq.gz --readFilesCommand zcat --outFileNamePrefix out/star/${sid}/
done

# TODO: create a log file containing information from cutadapt and star logs
echo "Creating the log file..."
for sid in $(ls log/cutadapt/*.log | cut -d"." -f1 | sed 's:log/cutadapt/::' | sort)
do
        echo >> log/pipeline.log
	echo "${sid}" >> log/pipeline.log
	echo >> log/pipeline.log
	echo "CUTADAPT ANALYSE FOR ${sid} :" >> log/pipeline.log
	cat log/cutadapt/${sid}.log | grep "Reads with adapters" >> log/pipeline.log
        cat log/cutadapt/${sid}.log | grep "Total basepair" >> log/pipeline.log
	echo >> log/pipeline.log
	echo "STAR ANALYSE FOR ${sid} :" >> log/pipeline.log
        cat out/star/${sid}/Log.final.out | grep "Uniquely mapped reads %" >> log/pipeline.log
        cat out/star/${sid}/Log.final.out | grep "% of reads mapped to multiple loci" >> log/pipeline.log
        cat out/star/${sid}/Log.final.out | grep "% of reads mapped to too many loci" >> log/pipeline.log
done

echo "DONE!"

# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
