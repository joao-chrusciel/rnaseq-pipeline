#!/usr/bin/env python3
import argparse
import re

parser = argparse.ArgumentParser()
parser.add_argument("--clstr", required=True)
parser.add_argument("--blast", required=True)
parser.add_argument("--output", required=True)
args = parser.parse_args()

cluster_members: dict[str, list[str]] = {}
cluster_rep: dict[str, str] = {}
current: str | None = None
clstr_re = re.compile(r"\d+\s+\d+nt,\s+>(\S+?)\.\.\.\s+(.*)")

with open(args.clstr) as f:
    for line in f:
        if line.startswith(">Cluster"):
            current = line.strip().split()[1]
            cluster_members[current] = []
        else:
            m = clstr_re.match(line)
            if m and current is not None:
                seq_id, marker = m.groups()
                cluster_members[current].append(seq_id)
                if marker.strip() == "*":
                    cluster_rep[current] = seq_id

def parse_seq_id(sid):
    m = re.match(r"seq_\d+_total(\d+)_samp(\d+)", sid)
    if m:
        return int(m.group(1)), int(m.group(2))
    return 0, 0

cluster_stats = {}
for cl, members in cluster_members.items():
    total_reads = 0
    max_samples = 0
    for sid in members:
        t, s = parse_seq_id(sid)
        total_reads += t
        if s > max_samples:
            max_samples = s
    cluster_stats[cl] = (len(members), total_reads, max_samples)

best_hit: dict[str, tuple[str, float, str, str]] = {}
with open(args.blast) as f:
    for line in f:
        fields = line.rstrip("\n").split("\t", 12)
        qid = fields[0]
        evalue = float(fields[10])
        pident = fields[2]
        sseqid = fields[1]
        stitle = fields[12] if len(fields) > 12 else sseqid
        if qid not in best_hit or evalue < best_hit[qid][1]:
            best_hit[qid] = (sseqid, evalue, pident, stitle)

with open(args.output, "w") as out:
    out.write("cluster_id\tn_members\trep_seq_id\ttotal_reads\tmax_samples\trnacentral_hit\tpercent_id\tevalue\thit_description\n")
    for cl, (n_mem, tot, max_s) in sorted(cluster_stats.items(), key=lambda x: int(x[0])):
        rep = cluster_rep.get(cl, "NA")
        if rep in best_hit:
            sseqid, evalue, pident, stitle = best_hit[rep]
            out.write(f"{cl}\t{n_mem}\t{rep}\t{tot}\t{max_s}\t{sseqid}\t{pident}\t{evalue}\t{stitle}\n")
        else:
            out.write(f"{cl}\t{n_mem}\t{rep}\t{tot}\t{max_s}\tNA\tNA\tNA\tNA\n")