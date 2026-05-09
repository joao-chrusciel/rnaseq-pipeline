process BOWTIE_SPIKEIN {
    tag "${meta.id}"
    label 'process_medium'
    container 'quay.io/biocontainers/bowtie:1.3.1--py312hf8dbd9f_10'
    publishDir "${params.outdir}/bowtie_spikein", mode: 'copy'

    input:
    tuple val(meta), path(reads)
    path spikein_fasta

    output:
    tuple val(meta), path('*.no_spikein.fastq.gz'), emit: reads
    path '*.spikein_counts.txt', emit: counts
    path '*.bowtie.log', emit: log

    script:
    """
    bowtie-build ${spikein_fasta} spikein_index

    bowtie -x spikein_index \\
        -q ${reads} \\
        --un ${meta.id}.no_spikein.fastq \\
        -S ${meta.id}.spikein.sam \\
        --threads ${task.cpus} \\
        2> ${meta.id}.bowtie.log

    grep -v '^@' ${meta.id}.spikein.sam \\
        | awk '\$3 != "*"' \\
        | wc -l > ${meta.id}.spikein_counts.txt

    gzip ${meta.id}.no_spikein.fastq
    """
}