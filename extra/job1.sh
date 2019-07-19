#!/bin/bash -l

#SBATCH --job-name=Nextflow-master-nanopore
#SBATCH --account=pawsey0001
#SBATCH --partition=workq
#SBATCH --time=1-00:00:00
#SBATCH --no-requeue
#SBATCH --export=none

module load nextflow

./nanopore.nf -resume -name nxf-${SLURM_JOB_ID} --read_dir='sample6'
