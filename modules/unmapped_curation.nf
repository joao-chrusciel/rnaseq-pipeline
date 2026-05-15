process UNMAPPED_CURATION {
    label 'process_high'
    publishDir "${params.outdir}/unmapped_curation", mode: 'copy'

    input:
    path mirge3_dir
    path rnacentral_db_dir

    output:
    path "unmapped_filtered.fa", emit: filtered
    path "unmapped_clusters.fa",emit: clusters
    path "unmapped_clusters.fa.clstr", emit: clstr
    path "blast_results.tsv", emit: blast
    path "unmapped_curation_summary.tsv", emit: summary
    path "unmapped_curation.log", emit: log

    script:
    def min_total = params.unmapped_min_total_count ?: 10
    def min_samples = params.unmapped_min_samples ?: 5
    def cdhit_identity = params.unmapped_cdhit_identity ?: 0.90
    def blast_prefix = params.rnacentral_db_prefix ?: 'rnacentral_active'
    """
    UNMAPPED_CSV=\$(find ${mirge3_dir} -name 'unmapped.csv' | head -1)
    if [ -z "\$UNMAPPED_CSV" ]; then
        echo "ERROR: unmapped.csv not found in ${mirge3_dir}" >&2
        exit 1
    fi
    echo "Source: \$UNMAPPED_CSV" > unmapped_curation.log

    unmapped_extract.py --input "\$UNMAPPED_CSV" \\
        --output unmapped_filtered.fa \\
        --min-total ${min_total} \\
        --min-samples ${min_samples} \\
        2>> unmapped_curation.log

    cd-hit-est -i unmapped_filtered.fa \\
        -o unmapped_clusters.fa \\
        -c ${cdhit_identity} \\
        -n 8 \\
        -d 0 \\
        -T ${task.cpus} \\
        -M 0 \\
        -G 1 \\
        -aS 0.8 \\
        2>> unmapped_curation.log

    blastn -query unmapped_clusters.fa \\
        -db ${rnacentral_db_dir}/${blast_prefix} \\
        -evalue 1e-5 \\
        -word_size 11 \\
        -max_target_seqs 5 \\
        -outfmt '6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore stitle' \\
        -num_threads ${task.cpus} \\
        -out blast_results.tsv \\
        2>> unmapped_curation.log

    unmapped_summarize.py --clstr unmapped_clusters.fa.clstr \\
        --blast blast_results.tsv \\
        --output unmapped_curation_summary.tsv \\
        2>> unmapped_curation.log
    """
}