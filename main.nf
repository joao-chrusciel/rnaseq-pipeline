nextflow.enable.dsl = 2

include { SMALLRNASEQ } from './workflows/smallrnaseq'

workflow {
    if (!params.input) {
        error "No input provided. Please specify which sample sheet should be used with --input samplesheet.csv."
    }
    if (!params.species) {
    error "No species provided. Use --species (human, mouse, rat, zebrafish or others)"
    }

    ch_reads = channel.fromPath(params.input, checkIfExists: true)
        .splitCsv(header: true)
        .map {row ->
            def meta = [id: row.sample, condition: row.condition]
            def reads = file(row.fastq_1, checkIfExists: true)
            return [ meta, reads ]
            }

    SMALLRNASEQ(ch_reads)
}