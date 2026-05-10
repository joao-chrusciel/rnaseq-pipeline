process KRAKEN2 {
    tag "${meta.id}"
    label 'process_high'

    publishDir "${params.outdir}/kraken2", mode: 'copy'

    input:
    tuple val(meta), path(reads)
    path kraken2_db

    output:
    tuple val(meta), path("${meta.id}.kraken2.report"), emit: report
    tuple val(meta), path("${meta.id}.kraken2.output"), emit: classified
    path "${meta.id}.kraken2.log", emit: log

    script:
    def memmap = params.kraken2_memory_mapping ? '--memory-mapping' : ''
    """
    kraken2 \\
        --db ${kraken2_db} \\
        --threads ${task.cpus} \\
        --report ${meta.id}.kraken2.report \\
        --output ${meta.id}.kraken2.output \\
        --gzip-compressed ${memmap} ${reads} \\
        2> ${meta.id}.kraken2.log
    """
}