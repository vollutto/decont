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

