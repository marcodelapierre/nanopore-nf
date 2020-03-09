#!/bin/bash

docker run --rm \
  -u $(id -u):$(id -g) \
  -v $(pwd):/data -w /data \
  quay.io/biocontainers/blast:2.7.1--h4422958_6 \
  makeblastdb -in tinydb.fasta -dbtype nucl -parse_seqids

nextflow run main.nf \
  --basecalled='small.fastq' \
  --seqid='X55033.1,NC_037830.1,MG882489.1' \
  --blast_db="$(pwd)/tinydb.fasta" \
  --min_len_contig='0' \
  -profile nimbus
