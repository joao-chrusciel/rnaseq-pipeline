process CUTADAPT {
    tag "${meta.id}"
    label 'process_medium'
    container 'quay.io/biocontainers/cutadapt:5.2--py313h8c92656_1'
    publishDir "${params.outdir}/cutadapt", mode: 'copy'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*.trimmed.fastq.gz'), emit: reads
    path '*.log', emit: log

    script:
    """
    cutadapt -a ${params.adapter} \\
             --minimum-length ${params.min_length} \\
             --maximum-length ${params.max_length} \\
             --quality-cutoff ${params.quality_cutoff} \\
             --cores ${task.cpus} \\
             -o ${meta.id}.trimmed.fastq.gz \\
             ${reads} > ${meta.id}.cutadapt.log
    """
}