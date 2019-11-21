cd /home/user05/DECONT/decont
export WD=$(pwd)

#Download all the files specified in data/urls
echo "Downloading the files..."
for url in $(cat data/urls) #TODO
do

    bash scripts/download.sh $url data
done

if [ -f "data/*.fastq.gz" ]
then
	echo "Already downloaded the files"
else
	echo "Downloading the files..."
	wget -i data/urls -P data/
fi

# Download the contaminants fasta file, and uncompress it
if [ -f "res/*.fasta.gz" ]
then
	echo "Already downloaded the contaminants fasta files"
else
	echo "Downloading the contaminants fasta files and uncompress it..."
	bash scripts/download.sh https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz res yes
	gunzip -k res/contaminants.fasta.gz #TODO
fi

# Index the contaminants file
if [ -d res/contaminants_idx ]
then
	echo "Already exist the index"
else
	echo "Running index..."
	bash scripts/index.sh res/contaminants.fasta res/contaminants_idx/
fi

# Merge the samples into a single file
mkdir -p out/merged
for sid in $(ls data/*.fastq.gz | cut -d"-" -f1 | sed 's:data/::' | sort | uniq) #TODO
do
	if [ -f "out/merged/${sid}.fastq.gz" ]
	then
		echo "Already merged the samples into a single file"
	else
		echo "Running Merge..."
   		bash scripts/merge_fastqs.sh data out/merged $sid
	fi
done

# TODO: run cutadapt for all merged files
mkdir -p out/trimmed
mkdir -p log/cutadapt
for sampleid in $(ls out/merged/*.fastq.gz | cut -d"." -f1 | sed 's:out/merged/::' | sort)
do
	if [ -f "out/trimmed/${sid}.trimmed.fastq.gz" ]
	then
		echo "Already run the cutadapt for all merged files"
	else
		echo "Running cutadapt..."
		cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed -o out/trimmed/${sampleid}.trimmed.fastq.gz out/merged/${sampleid}.fastq.gz > log/cutadapt/${sampleid}.log
	fi
done

#TODO: run STAR for all trimmed files
for fname in out/trimmed/*.fastq.gz
do
	# you will need to obtain the sample ID from the filename
	sid=$(basename $fname .trimmed.fastq.gz)
	mkdir -p out/star/$sid
	if [ -f "out/star/$s{sid}/Log.final.out" ]
	then
		echo "Already run STAR for all trimmed files"
	else
		echo "Running STAR..."
    		STAR --runThreadN 4 --genomeDir res/contaminants_idx --outReadsUnmapped Fastx --readFilesIn out/trimmed/${sid}.trimmed.fastq.gz --readFilesCommand zcat --outFileNamePrefix out/star/${sid}/
	fi
done

#TODO: created the log files for cutadapt and star
if [ -f "log/pipeline.log" ]
then
	echo "Already created the log file for cutadapt and star"
else
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
fi

echo "DONE!"

