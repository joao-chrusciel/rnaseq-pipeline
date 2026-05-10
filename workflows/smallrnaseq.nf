include { FASTQC as FASTQC_RAW } from '../modules/fastqc'
include { FASTQC as FASTQC_TRIMMED } from '../modules/fastqc'
include { CUTADAPT } from '../modules/cutadapt'
include { BBDUK_SPIKEIN } from '../modules/bbduk_spikein'
include { MIRGE3 } from '../modules/mirge3'
include { MULTIQC } from '../modules/multiqc'

workflow SMALLRNASEQ {
    take:
    ch_reads

    main:
    ch_qc = channel.empty()

    // FastQC
    if (!params.skip_fastqc) {
        FASTQC_RAW(ch_reads.map { meta, reads -> [meta + [stage: 'raw'], reads] })
        ch_qc = ch_qc.mix(FASTQC_RAW.out.zip.map { _meta, zip -> zip })
    }

    // Adapter and quality trimming
    CUTADAPT(ch_reads)
    ch_qc = ch_qc.mix(CUTADAPT.out.log)

    // FastQC on trimmed reads
    if (!params.skip_fastqc) {
        FASTQC_TRIMMED(CUTADAPT.out.reads.map { _meta, reads -> [_meta + [stage: 'trimmed'], reads] })
        ch_qc = ch_qc.mix(FASTQC_TRIMMED.out.zip.map { _meta, zip -> zip })
    }

    // (Optional) spike-in removal
    ch_clean_reads = CUTADAPT.out.reads
    if (params.run_spikein) {
        BBDUK_SPIKEIN(CUTADAPT.out.reads, file(params.spikein_fasta))
        ch_clean_reads = BBDUK_SPIKEIN.out.reads
        ch_qc = ch_qc.mix(BBDUK_SPIKEIN.out.log)
    }

    // Quantification
    if (!params.mirge_lib) {
        error "Missing --mirge_lib. Provide path to the miRge3.0 library folder."
    }
    ch_fastqs = ch_clean_reads.map { _meta, reads -> reads }.collect()
    MIRGE3(ch_fastqs, file(params.mirge_lib))

    // MultiQC
    MULTIQC(ch_qc.collect())
}