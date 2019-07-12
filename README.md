## Nanopore pipeline for DPIRD

The pipeline requires [Nextflow](https://github.com/nextflow-io/nextflow) to run. 
Tests have been done with Nextflow version `19.04.1`. 
The standard profile assumes running on Zeus at Pawsey Supercomputing Centre.


### Pipeline

Basecalling\* -> Chopping -> De-novo assembling -> Blasting\+ -> Aligning\#

\* Optional  
\+ Either with Blast or Diamond  
\# Requires additional input in a subsequent run


### Basic usage

```
nextflow run marcodelapierre/nanopore-nf --slurm_account='pawsey0001' --read_dir='reads'
```

The flag `--read_dir` feeds the directory name where read files from a single experiment are located. 
Name patterns can be used to run multiple experiments at once. Output files are stored in subdirectory(ies) with name `results_$read_dir`. 
The flag `--slurm_account` sets your Pawsey account to run on Zeus. In alternative, edit the value of the variable `params.slurm_account` in the file `nextflow.config`.

After blasting and identifying reference sequences of interest, alignment can be performed against them, by using the flag `--seqid` to provide the sequence IDs:

```
nextflow run marcodelapierre/nanopore-nf --slurm_account='pawsey0001' --read_dir='reads' -resume --seqid='comma,separated,list,of,ids,from,blast'
```

Note the use of `-resume` to restart from the previous run.


### Pipeline variants

The expected default input is one or multiple directory/ies containing raw read files from experiment(s). By default, Blast is used for blasting.

1. To feed instead a single (or multiple, using name patterns) already basecalled FASTA file(s) as input, use the flag `--basecalled='basecalled.fasta'`; raw reads are ignored
2. To use Diamond for blasting, add the flag `--diamond`


### Optional parameters

* Change *evalue* for blasting: `--evalue='0.1'`
* Change minimum length threshold for assembled contigs to be considered for blasting: `--min_len_contig='1000'`


### Requirements

Software:
* Guppy
* Pomoxis
* Blast or Diamond

Reference data:
* Database for Blast or Diamond


### Additional resources

The `extra` directory contains example Slurm scripts, `job1.sh` and `job2.sh` to run on Zeus. There is also a sample script `nxf-log.sh` that takes a run name as input and displays formatted runtime information.


**Note**: Slurm parameters in the file `nextflow.config` (cores, memory, walltime) are general values, that require tuning for production runs.
