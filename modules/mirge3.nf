process MIRGE3 {
    label 'process_high'

    publishDir "${params.outdir}/mirge3", mode: 'copy'

    input:
    path reads
    path mirge_lib

    output:
    path 'mirge3_output/**', emit: results

    script:
    def novel_flag = params.predict_novel_mirna ? '--novel-miRNA' : ''
    def trf_flag = params.run_trf ? '-trf' : ''
    """
    miRge3.0 \\
        -s ${reads.join(',')} \\
        -db ${params.mirge_db} \\
        -lib ${mirge_lib.name} \\
        -on ${params.species} \\
        -a ${params.adapter} \\
        -o mirge3_output \\
        --threads ${task.cpus} \\
        ${novel_flag} \\
        ${trf_flag}
    """
}