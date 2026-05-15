include { FASTQC as FASTQC_RAW } from '../modules/fastqc'
include { FASTQC as FASTQC_TRIMMED } from '../modules/fastqc'
include { CUTADAPT } from '../modules/cutadapt'
include { BBDUK_SPIKEIN } from '../modules/bbduk_spikein'
include { MIRGE3 } from '../modules/mirge3'
include { KRAKEN2 } from '../modules/kraken2'
include { MULTIQC } from '../modules/multiqc'
include { BOWTIE_YRNA } from '../modules/bowtie_yrna'
include { BOWTIE_PIRNA } from '../modules/bowtie_pirna'
include { UNMAPPED_CURATION } from '../modules/unmapped_curation'

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
    // Kraken2
    if (params.run_kraken2) {
        if (!params.kraken2_db) {
            error "Missing --kraken2_db. Provide path to Kraken2 database directory."
        }
        KRAKEN2(ch_clean_reads, file(params.kraken2_db))
        ch_qc = ch_qc.mix(KRAKEN2.out.report.map { _meta, report -> report })
    }
    // YRNA and piRNA alignment and counting
    if (params.run_yrna) {
        BOWTIE_YRNA(ch_clean_reads, file(params.yrna_fasta))
    }
    if (params.run_pirna) {
        if (!params.pirna_index_dir) {
            error "Missing --pirna_index_dir. Provide the piRNA bowtie index directory (or use -profile lpc)."
        }
        BOWTIE_PIRNA(ch_clean_reads, file(params.pirna_index_dir))
    }
    // Quantification
    if (!params.mirge_lib) {
        error "Missing --mirge_lib. Provide path to the miRge3.0 library folder."
    }
    ch_fastqs = ch_clean_reads.map { _meta, reads -> reads }.collect()
    MIRGE3(ch_fastqs, file(params.mirge_lib))
    if (params.run_unmapped_curation) {
        if (!params.rnacentral_db_dir) {
            error "Missing --rnacentral_db_dir. Provide the RNAcentral BLAST DB directory (or use -profile lpc)."
        }
        UNMAPPED_CURATION(MIRGE3.out.results.collect(), file(params.rnacentral_db_dir))
    }
    // MultiQC
    MULTIQC(ch_qc.collect(), file("${projectDir}/assets/multiqc_config.yml"))
}