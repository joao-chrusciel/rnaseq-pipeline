#!/usr/bin/env python3
import argparse
import csv
import sys

parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True)
parser.add_argument("--output", required=True)
parser.add_argument("--min-total", type=int, default=10)
parser.add_argument("--min-samples", type=int, default=5)
parser.add_argument("--sample-start", type=int, default=11)
args = parser.parse_args()

n_kept = 0
n_total = 0
with open(args.input) as fin, open(args.output, "w") as fout:
    reader = csv.reader(fin)
    header = next(reader)
    for row in reader:
        n_total += 1
        seq = row[0]
        counts = [int(c) if c else 0 for c in row[args.sample_start:]]
        total = sum(counts)
        n_pos = sum(1 for c in counts if c > 0)
        if total >= args.min_total and n_pos >= args.min_samples:
            seq_id = f"seq_{n_kept:08d}_total{total}_samp{n_pos}"
            fout.write(f">{seq_id}\n{seq}\n")
            n_kept += 1

print(f"Input sequences: {n_total}", file=sys.stderr)
print(f"Kept (total>={args.min_total}, samples>={args.min_samples}): {n_kept}", file=sys.stderr)