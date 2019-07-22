#!/bin/bash -l

#SBATCH --job-name=Nextflow-master-nanopore
#SBATCH --account=pawsey0281
#SBATCH --partition=workq
#SBATCH --time=1-00:00:00
#SBATCH --no-requeue
#SBATCH --export=none

module load nextflow

nextflow run marcodelapierre/nanopore-nf  -resume \
  -profile zeus --slurm_account='pawsey0281' -name nxf-${SLURM_JOB_ID} \
  --read_dir='sample6' --seqid='D10930.1,MK116873.1'
