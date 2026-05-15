process BOWTIE_PIRNA {
    tag "${meta.id}"
    label 'process_medium'

    publishDir "${params.outdir}/pirna", mode: 'copy'

    input:
    tuple val(meta), path(reads)
    path pirna_index_dir

    output:
    tuple val(meta), path("${meta.id}.pirna.counts.tsv"), emit: counts
    path "${meta.id}.pirna_align.log", emit: log

    script:
    def prefix = params.pirna_index_prefix ?: 'pirbase_v3'
    """
    zcat ${reads} | bowtie \\
        -p ${task.cpus} \\
        -S \\
        -n 0 \\
        -l 20 \\
        -m 1 \\
        --best \\
        -q \\
        -x ${pirna_index_dir}/${prefix} \\
        - \\
        2> ${meta.id}.pirna_align.log \\
        > ${meta.id}.pirna.sam

    echo -e "feature\\tcount" > ${meta.id}.pirna.counts.tsv
    samtools view -F 4 ${meta.id}.pirna.sam | \\
        awk '{counts[\$3]++} END {for (r in counts) print r"\\t"counts[r]}' \\
        | sort >> ${meta.id}.pirna.counts.tsv

    rm -f ${meta.id}.pirna.sam
    """
}