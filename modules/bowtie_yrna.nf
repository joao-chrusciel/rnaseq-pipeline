process BOWTIE_YRNA {
    tag "${meta.id}"
    label 'process_low'

    publishDir "${params.outdir}/yrna", mode: 'copy'

    input:
    tuple val(meta), path(reads)
    path yrna_fasta

    output:
    tuple val(meta), path("${meta.id}.yrna_full.counts.tsv"),    emit: counts_full
    tuple val(meta), path("${meta.id}.yrna_regions.counts.tsv"), emit: counts_regions
    path "${meta.id}.yrna_align.log", emit: log

    script:
    def region_size = params.yrna_region_size ?: 30
    """
    bowtie-build ${yrna_fasta} yrna_idx 2> bowtie_build.log

    zcat ${reads} | bowtie \\
        -p ${task.cpus} \\
        -S \\
        -n 0 \\
        -l 20 \\
        -m 1 \\
        --best \\
        -q \\
        yrna_idx \\
        - \\
        2> ${meta.id}.yrna_align.log \\
        > ${meta.id}.yrna.sam

    echo -e "feature\\tcount" > ${meta.id}.yrna_full.counts.tsv
    samtools view -F 4 ${meta.id}.yrna.sam | \\
        awk '{counts[\$3]++} END {for (r in counts) print r"\\t"counts[r]}' \\
        >> ${meta.id}.yrna_full.counts.tsv

    samtools faidx ${yrna_fasta}

    python3 - <<'PYEOF' > ${meta.id}.yrna_regions.counts.tsv
import sys

REGION_SIZE = ${region_size}

ref_len = {}
with open("${yrna_fasta}.fai") as f:
    for line in f:
        fields = line.strip().split("\\t")
        ref_len[fields[0]] = int(fields[1])

counts = {}
with open("${meta.id}.yrna.sam") as f:
    for line in f:
        if line.startswith("@"):
            continue
        fields = line.split("\\t")
        flag = int(fields[1])
        if flag & 4:
            continue
        ref = fields[2]
        pos = int(fields[3])
        seq_len = len(fields[9])
        midpoint = pos + seq_len // 2

        L = ref_len[ref]
        if midpoint <= REGION_SIZE:
            region = "5p"
        elif midpoint > L - REGION_SIZE:
            region = "3p"
        else:
            region = "central"

        key = f"{ref}_{region}"
        counts[key] = counts.get(key, 0) + 1

print("feature\\tcount")
for k in sorted(counts):
    print(f"{k}\\t{counts[k]}")
PYEOF

    rm -f ${meta.id}.yrna.sam yrna_idx*
    """
}