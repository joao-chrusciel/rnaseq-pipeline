process MULTIQC {
    label 'process_single'
    container 'quay.io/biocontainers/multiqc:1.34--pyhdfd78af_0'
    publishDir "${params.outdir}/multiqc", mode: 'copy'

    input:
    path qc_files

    output:
    path 'multiqc_report.html', emit: report
    path 'multiqc_data/', emit: data

    script:
    """
    multiqc . --filename multiqc_report.html
    """
}