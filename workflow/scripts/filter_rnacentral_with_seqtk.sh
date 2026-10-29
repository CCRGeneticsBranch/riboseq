#!/usr/bin/env bash

# Subset RNAcentral FASTA by ID lists using seqtk

set -euo pipefail

ml seqtk

INPUT_FASTA="rnacentral_species_specific_ids.fasta.gz"

ID_FILES=(
  "rRNA.ids.txt"
  "snRNA.ids.txt"
  "tRNA.ids.txt"
)

for ids in "${ID_FILES[@]}"; do
  base="${ids%.ids.txt}"
  out_fasta="${base}.fasta"

  seqtk subseq "$INPUT_FASTA" "$ids" > "$out_fasta"
done