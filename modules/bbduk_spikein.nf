process BBDUK_SPIKEIN {
    tag "${meta.id}"
    label 'process_medium'
    publishDir "${params.outdir}/bbduk_spikein", mode: 'copy'

    input:
    tuple val(meta), path(reads)
    path spikein_fasta

    output:
    tuple val(meta), path("${meta.id}.clean.fastq.gz"), emit: reads
    path '*.spikein_stats.txt', emit: stats
    path '*.bbduk.log', emit: log

    script:
    """
    bbduk.sh \\
        in=${reads} \\
        out=${meta.id}.clean.fastq.gz \\
        ref=${spikein_fasta} \\
        stats=${meta.id}.spikein_stats.txt \\
        statscolumns=5 \\
        k=13 \\
        maskmiddle=f \\
        rcomp=f \\
        hdist=0 \\
        edist=0 \\
        rename=t \\
        threads=${task.cpus} \\
        -Xmx${task.memory.toGiga()}g \\
        2> ${meta.id}.bbduk.log
    """
}