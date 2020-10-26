#!/usr/bin/env nextflow

nextflow.enable.dsl=2

params.read_dir='reads'
params.basecalled = ''
params.diamond = false
params.seqid=''

params.min_len_contig='1000'
params.evalue='0.1'
params.outsuffix='results_'



process basecall {
tag "${dir}/${name}"
publishDir "${dir}/${params.outsuffix}${name}", mode: 'copy'
stageInMode 'symlink'

input:
tuple val(dir), val(name), path('read_dir')

output:
tuple val(dir), val(name), path('Basecalled.fastq')

script:
"""
guppy_basecaller \
    -i read_dir -s . \
    --recursive \
    --records_per_fastq 0 \
    -c dna_r9.4.1_450bps_hac.cfg \
    --qscore_filtering --min_score 7 \
    --num_callers 1 --cpu_threads_per_caller ${task.cpus}

ln -s pass/fastq_runid_*.fastq Basecalled.fastq
"""
}


process chop {
tag "${dir}/${name}"
publishDir "${dir}/${params.outsuffix}${name}", mode: 'copy'
stageInMode ( ( params.basecalled && workflow.profile == 'zeus' ) ? 'copy' : 'symlink' )

input:
tuple val(dir), val(name), path('Basecalled.fastq')

output:
tuple val(dir), val(name), path('Chopped.fastq')

script:
"""
porechop \
  -i Basecalled.fastq -o Chopped.fastq \
  --discard_middle -t ${task.cpus}
"""
}


process assemble{
tag "${dir}/${name}"
publishDir "${dir}/${params.outsuffix}${name}", mode: 'copy'

input:
tuple val(dir), val(name), path('Chopped.fastq')

output:
tuple val(dir), val(name), path('Denovo_subset.fa')

script:
"""
mini_assemble \
  -i Chopped.fastq -p denovo -o denovo \
  -c -t ${task.cpus}

awk -v min_len_contig=${params.min_len_contig} \
  '{ if( substr(\$1,1,1) == ">" ){ skip=0 ; s=gensub(/LN:i:/,"",1,\$2) ; if( (s-0) < min_len_contig ){ skip=1 }} ; if( skip == 0 ){print} }' \
  denovo/denovo_final.fa >Denovo_subset.fa
"""
}


process blast {
tag "${dir}/${name}"
publishDir "${dir}/${params.outsuffix}${name}", mode: 'copy'

input:
tuple val(dir), val(name), path('Denovo_subset.fa')

output:
tuple val(dir), val(name), path('blast.tsv')
tuple val(dir), val(name), path('blast.xml')

when:
!params.diamond

script:
"""
blastn \
  -query Denovo_subset.fa -db ${params.blast_db} \
  -outfmt 11 -out blast.asn \
  -evalue ${params.evalue} \
  -num_threads ${task.cpus}

blast_formatter \
  -archive blast.asn \
  -outfmt 5 -out blast.xml

blast_formatter \
  -archive blast.asn \
  -outfmt "6 qaccver saccver pident length evalue bitscore stitle" -out blast_unsort.tsv

sort -n -r -k 6 blast_unsort.tsv >blast.tsv
"""
}


process diamond {
tag "${dir}/${name}"
publishDir "${dir}/${params.outsuffix}${name}", mode: 'copy'

input:
tuple val(dir), val(name), path('Denovo_subset.fa')

output:
tuple val(dir), val(name), path('diamond.tsv')
tuple val(dir), val(name), path('diamond.xml')

when:
params.diamond

script:
"""
diamond blastx \
  -q Denovo_subset.fa -d ${params.diamond_db} \
  -f 5 -o diamond.xml \
  --evalue ${params.evalue} \
  -p ${task.cpus}

diamond blastx \
  -q Denovo_subset.fa -d ${params.diamond_db} \
  -f 6 qseqid  sseqid  pident length evalue bitscore stitle -o diamond_unsort.tsv \
  --evalue ${params.evalue} \
  -p ${task.cpus}

sort -n -r -k 6 diamond_unsort.tsv >diamond.tsv
"""
}


seqid_list = params.seqid?.tokenize(',')
seqid_ch = seqid_list ? Channel.from( seqid_list ) : Channel.empty()


process seqfile {
tag "${seqid}"
publishDir '.', mode: 'copy', saveAs: { filename -> "Refseq_${seqid}.fasta" }

input:
val(seqid)

output:
tuple val(seqid), path('Refseq.fasta')

script:
"""
blastdbcmd \
    -db ${params.blast_db} -entry ${seqid} \
    -line_length 60 \
    -out Refseq.fasta

sed -i '/^>/ s/ .*//g' Refseq.fasta
"""
}


process align {
tag "${dir}/${name}_${seqid}"
publishDir "${dir}/${params.outsuffix}${name}", mode: 'copy', saveAs: { filename -> "Aligned_${seqid}.bam" }

input:
tuple val(dir), val(name), path('Chopped.fastq'), seqid, path('Refseq.fasta')

output:
tuple val(dir), val(name), val(seqid), path('Aligned.bam')

script:
"""
mini_align \
  -i Chopped.fastq -r Refseq.fasta \
  -p Aligned \
  -t ${task.cpus}
"""
}



workflow {

read_ch =     params.basecalled ? Channel.empty() : Channel.fromPath( params.read_dir ).map{ it -> [ it.parent, it.name, it ] }
basefile_ch = params.basecalled ? Channel.fromPath( params.basecalled ).map{ it -> [ it.parent, it.name, it ] } : Channel.empty()

seqid_list = params.seqid?.tokenize(',')
seqid_ch = seqid_list ? Channel.from( seqid_list ) : Channel.empty()

basecall(read_ch)

chop(basecall.out.mix(basefile_ch))

assemble(chop.out)

blast(assemble.out)
diamond(assemble.out)

seqfile(seqid_ch)

align(chop.out.combine(seqfile.out))

}
