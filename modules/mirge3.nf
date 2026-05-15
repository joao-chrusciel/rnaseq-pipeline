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
    def read_list = reads instanceof List ? reads : [reads]
    def bare = read_list.collect { f -> f.name.replaceAll(/\.(clean|trimmed)\.fastq\.gz$/, '.fastq.gz') }
    def links = [read_list, bare].transpose().findAll { s, d -> s.name != d }.collect { s, d -> "ln -sf ${s} ${d}" }.join('\n    ')
    """
    ${links}
    miRge3.0 \\
        -s ${bare.join(',')} \\
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