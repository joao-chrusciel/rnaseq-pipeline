process MULTIQC {
    label 'process_single'
    publishDir "${params.outdir}/multiqc", mode: 'copy'

    input:
    path qc_files
    path multiqc_config

    output:
    path 'multiqc_report.html', emit: report
    path '*_data', emit: data

    script:
    """
    multiqc . -c ${multiqc_config} --filename multiqc_report.html
    """
}