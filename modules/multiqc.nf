process MULTIQC {
    label 'process_single'
    publishDir "${params.outdir}/multiqc", mode: 'copy'

    input:
    path qc_files

    output:
    path 'multiqc_report.html', emit: report
    path '*_data', emit: data

    script:
    """
    multiqc . --filename multiqc_report.html
    """
}