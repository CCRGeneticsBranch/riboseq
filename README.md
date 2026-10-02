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

## Config files

- `config/config.yaml`: run configuration template
- `config/samples.tsv`: sample sheet template (columns: `Sample`, `Fastq`)

## Running with run_riboseq

Use [run_riboseq](run_riboseq) with `--runmode` and `--workdir`.

### 1. Initialize a run directory

This creates the work directory and copies config files.

```bash
bash run_riboseq --runmode=init --workdir=/path/to/my_run
```

Then edit:
- ` /path/to/my_run/config/config.yaml`
- ` /path/to/my_run/config/samples.tsv`

### 2. Dry run

This validates the workflow and planned jobs without executing them.

```bash
bash run_riboseq --runmode=dryrun --workdir=/path/to/my_run
```

### 3. Run on SLURM

This submits the pipeline through the Biowulf/SLURM path used by the wrapper.

```bash
bash run_riboseq --runmode=run --workdir=/path/to/my_run
```
