nextflow.enable.dsl = 2

include { FASTQC } from './modules/fastqc.nf'

workflow {
    if (!params.input) {
        error "No input provided. Please specify which sample sheet should be used with --input samplesheet.csv."
    }

    ch_reads = channel.fromPath(params.input, checkIfExists: true)
        .splitCsv(header: true)
        .map {row ->
            def meta = [id: row.sample, condition: row.condition]
            def reads = file(row.fastq_1, checkIfExists: true)
            return [ meta, reads ]
            }
    FASTQC(ch_reads)
}