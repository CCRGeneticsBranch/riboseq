# Ribo-seq Pipeline (Development)

This repository contains an in-development Snakemake pipeline for single-end Ribo-seq processing.

## Current status

- `workflow/Snakefile` contains executable placeholder rules for:
  - linker trimming
  - UMI extraction
  - T removal
  - contaminant filtering
  - STAR alignment
  - riboWaltz handoff
- Original draft notes and example commands are preserved in comments in the Snakefile.

## Config files

- `config/config.yaml`: run configuration template
- `config/samples.tsv`: sample sheet template (columns: `Sample`, `Fastq`)

## Basic usage

1. Copy/edit `config/config.yaml` for your run directory.
2. Edit `config/samples.tsv` with sample names and FASTQ filenames.
3. Run Snakemake with a config file:

```bash
snakemake --snakefile workflow/Snakefile --configfile config/config.yaml -n
```

This pipeline is scaffolded for development and will be expanded with production tool commands.
