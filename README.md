## Nanopore pipeline for DPIRD

The pipeline requires [Nextflow](https://github.com/nextflow-io/nextflow) to run. 
Tests have been done with Nextflow version 19.04.1. 
The standard profile assumes running on Zeus at Pawsey Supercomputing Centre.


### Pipeline

Basecalling -> Chopping -> De-novo assembling -> Blasting -> Aligning\#

\# Requires additional input in a subsequent run


### Basic usage

```
./nanopore.nf --read_dir='reads'
```

The flag `--read_dir` feeds the directory name where read files for a single experiments are located. 
Name patterns can be used to run multiple experiments at once. Output files are stored in subdirectory(ies) with name `results_$read_dir`.

After blasting and identifying reference sequences of interest, aligned can be performed against them, by using the flag `--seqid` to provide the sequence IDs:

```
./nanopore.nf -resume --read_dir='read_dir' --seqid='comma,separated,list,of,ids,from,blast'
```


### Optional parameters

* Change *evalue* for blasting: `--evalue='0.1'`
* Change minimum length threshold for assembled contigs to be considered for blasting: `--min_len_contig='1000'`
