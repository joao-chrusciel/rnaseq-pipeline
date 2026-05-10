process MIRGE3 {
    label 'process_high'
    container 'quay.io/biocontainers/mirge3:0.1.4--pyh7cba7a3_0'
    publishDir "${params.outdir}/mirge3", mode: 'copy'

    input:
    path reads
    path mirge_lib

    output:
    path 'mirge3_output/miR.Counts.csv', emit: mirna_counts
    path 'mirge3_output/mapped.csv', emit: mapped
    path 'mirge3_output/*', emit: all_results

    script:
    def species_map = [human: 'human', mouse: 'mouse', rat: 'rat', zebrafish: 'zebrafish', fruitfly: 'fruitfly']
    def species_code = species_map[params.species] ?: params.species
    """
    miRge3.0 \\
        -s ${reads} \\
        -lib ${mirge_lib} \\
        -on ${species_code} \\
        -a none \\
        -o mirge3_output \\
        -t ${task.cpus} \\
        -pbwt ${params.mirge_pbwt}
    """
}