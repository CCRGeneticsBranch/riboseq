# Ribo-seq Pipeline

> **Beta (0.x):** under active development; outputs and configuration may change between versions.

Snakemake pipeline for ribosome profiling data generated with the Immagina RiboLace Gel-Free kit (single-end reads), following the *ALL-IN-ONE RiboLace Gel Free* documentation (V15.5). Pipeline trims the linker and UMIs, removes contaminating rRNA/tRNA/snRNA reads, aligns to the genome and transcriptome with STAR, removes PCR duplicates by UMI, and runs riboWaltz for P-site identification and ribosome profiling QC.

## Pipeline steps

| Step | Rule | Tool | Description |
|---|---|---|---|
| 1 | `fastqc` | FastQC | Raw read QC |
| 2 | `remove_linker` | cutadapt | Remove the 3' linker; keep reads ≥29bp (20bp RPF plus UMIs and T) |
| 3 | `extract_umi` | UMI-tools `extract` | Move the 5'/3' 4bp UMIs to the read name |
| 4 | `remove_t` | cutadapt | Remove the 5' T added by the protocol |
| 5 | `create_contaminant_index`, `remove_contaminants` | Bowtie2 | Build indices and sequentially remove rRNA, tRNA and snRNA reads |
| 6 | `create_star_index`, `star_alignment` | STAR, samtools | Build the STAR index; align to the genome and transcriptome |
| 7 | `dedup_umi` | UMI-tools `dedup` | Remove PCR duplicates by UMI and position |
| 8 | `filter_transcriptome_bam` | samtools | Keep transcriptome alignments of reads retained after deduplication |
| 9 | `multiqc` | MultiQC | Combined QC report |
| 10 | `ribowaltz` | R (riboWaltz) | P-site offsets, periodicity, read-length and CDS coverage QC report |

## Requirements

- Runs on NIH [Biowulf](https://hpc.nih.gov/) (SLURM and environment modules).
- Must have access to dependencies listed in [config/config.yaml](config/config.yaml).
- R packages used by the report: riboWaltz, data.table, txdbmaker, GenomicFeatures, rmarkdown

## Installation

```bash
git clone https://github.com/CCRGeneticsBranch/riboseq.git
```

## Quick start

The pipeline is designed to be run in a separate directory (/path/to/my_run).

```bash
# 1. Create a work folder with template config files
bash riboseq/run_riboseq --runmode=init --workdir=/path/to/my_run [--samplesheet=/path/to/samples.tsv]

# 2. Edit /path/to/my_run/config/config.yaml and config/samples.tsv (see Inputs)

# 3. Dry run (writes /path/to/my_run/dryrun.log)
bash riboseq/run_riboseq --runmode=dryrun --workdir=/path/to/my_run

# 4. Submit to SLURM
bash riboseq/run_riboseq --runmode=run --workdir=/path/to/my_run

# Unlock the work folder after an interrupted run
bash riboseq/run_riboseq --runmode=unlock --workdir=/path/to/my_run
```

`-h` shows all options; `-v` prints the pipeline and launcher versions. Per-rule SLURM resources are in `WORKDIR/config/cluster.yaml` (copied from [resources/cluster.yaml](resources/cluster.yaml) at `init`).

## Inputs

### Sample sheet (`config/samples.tsv`)

| Column | Description | Example |
|---|---|---|
| `Sample` | Sample name | `sample1` |
| `Fastq` | Single-end FASTQ file name, relative to `raw_data_dir` | `sample1.fastq.gz` |

### Configuration (`config/config.yaml`)

| Key | Default | Description (source) | Edit? |
|---|---|---|---|
| `raw_data_dir` | `/path/to/raw/fastqs` | Folder containing the FASTQ files | Yes |
| `rrna_fasta`, `trna_fasta`, `snrna_fasta` | `/data/khanlab3/gb_omics/resources/rnacentral/*.fasta` | Human contaminant sequences from [RNAcentral](https://rnacentral.org/); see [contaminant references](#contaminant-reference-provenance) | |
| `reference_fasta`, `reference_gtf`, `transcript_fasta` | `/fdb/GENCODE/Gencode_human/release_45/` | GRCh38 primary assembly, annotation, and transcript FASTA (GENCODE release 45; [GENCODE](https://www.gencodegenes.org/human/release_45.html)) | For another species/release |
| `samples`, `results_dir`, `tools` | `WORKDIR/...`, `PIPELINE_HOME/...` | Work folder and launcher/repository paths (filled by `init`) | |

### Contaminant References

The RNAcentral species-specific FASTA was downloaded on May 22, 2026. RNAcentral's search function was used to retrieve IDs with `TAXONOMY:"9606"` (Homo sapiens) and `so_rna_type_name:"SnRNA"` or `"TRNA"` or `"RRNA"` (RNA Type from Sequence Ontology), excluding records where `entry_type:"Gene"`. The FASTA was subset by the ID lists using `seqtk subseq`. 

## Outputs

All paths are relative to the work folder.

| Path | Description |
|---|---|
| `results/qc/<sample>_fastqc.html` | FastQC report |
| `results/trim/<sample>.trim.fastq.gz`, `.umi.fastq.gz`, `.trim2.fastq.gz` | Reads after linker removal, UMI extraction and 5' T removal |
| `results/filter_contaminants/<sample>.clean.fastq.gz` | Reads after rRNA/tRNA/snRNA removal |
| `results/star/<sample>.Aligned.sortedByCoord.out.bam` | Genome alignments |
| `results/star/<sample>.dedup.bam` | Deduplicated genome alignments |
| `results/star/<sample>.dedup.transcriptome.bam` | Deduplicated transcriptome alignments |
| `results/qc/multiqc_report.html` | Combined QC report |
| `results/ribowaltz/<sample>.ribowaltz.html` | riboWaltz report |
| `results/ribowaltz/<sample>.cds_coverage.tsv` | P-site counts per transcript CDS |
| `results/pipeline_version.txt` | Pipeline version used for the run |
| `runinfo.yaml`, `snakemake.log`, `logs/` | Run information, Snakemake log and per-rule SLURM logs |

The Bowtie2 contaminant indices and STAR index are built by the pipeline under `results/`.

## Tools and references

Modules are listed in [resources/tools.yaml](resources/tools.yaml).

| Tool | Module | Used in | Reference |
|---|---|---|---|
| Snakemake | `snakemake/7.19.1` | workflow | Mölder et al. 2021, *F1000Research* [doi:10.12688/f1000research.29032.2](https://doi.org/10.12688/f1000research.29032.2) |
| RiboLace | — | protocol | Clamer et al. 2018, *Cell Rep* [doi:10.1016/j.celrep.2018.09.084](https://doi.org/10.1016/j.celrep.2018.09.084) |
| FastQC | `fastqc` | `fastqc` | [Babraham Bioinformatics](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) |
| cutadapt | `cutadapt` | `remove_linker`, `remove_t` | Martin 2011, *EMBnet.journal* [doi:10.14806/ej.17.1.200](https://doi.org/10.14806/ej.17.1.200) |
| UMI-tools | `umitools` | `extract_umi`, `dedup_umi` | Smith et al. 2017, *Genome Res* [doi:10.1101/gr.209601.116](https://doi.org/10.1101/gr.209601.116) |
| Bowtie2 | `bowtie2` | contaminant removal | Langmead & Salzberg 2012, *Nat Methods* [doi:10.1038/nmeth.1923](https://doi.org/10.1038/nmeth.1923) |
| STAR | `STAR` | alignment | Dobin et al. 2013, *Bioinformatics* [doi:10.1093/bioinformatics/bts635](https://doi.org/10.1093/bioinformatics/bts635) |
| SAMtools | `samtools` | BAM processing | Danecek et al. 2021, *GigaScience* [doi:10.1093/gigascience/giab008](https://doi.org/10.1093/gigascience/giab008) |
| MultiQC | `multiqc` | `multiqc` | Ewels et al. 2016, *Bioinformatics* [doi:10.1093/bioinformatics/btw354](https://doi.org/10.1093/bioinformatics/btw354) |
| riboWaltz | `R` | `ribowaltz` | Lauria et al. 2018, *PLoS Comput Biol* [doi:10.1371/journal.pcbi.1006169](https://doi.org/10.1371/journal.pcbi.1006169) |

## Versioning

The pipeline version is in [VERSION](VERSION) and changes are listed in [CHANGELOG.md](CHANGELOG.md). Each run records the pipeline version, git commit and launcher version in `runinfo.yaml` and `results/pipeline_version.txt`. The launch script is a copy of [biowulf-snakemake-launcher](https://github.com/CCRGeneticsBranch/biowulf-snakemake-launcher) (`bin/launcher.sh`).

## License

Original pipeline code and documentation are licensed under MIT; see [LICENSE](LICENSE). Third-party software and reference data retain their own terms. The MIT license does not grant redistribution rights for external or bundled third-party resources.

## Contact

Erica Pehrsson, Genetics Branch, Center for Cancer Research, National Cancer Institute. Please report problems through GitHub issues.
