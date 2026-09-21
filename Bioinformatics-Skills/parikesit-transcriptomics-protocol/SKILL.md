---
name: parikesit-transcriptomics-protocol
description: "Knowledge base from \"Transcriptomics Computational Protocol\" (Complete Lab Protocol of Transcriptomics Course BI021) by Arli Aditya Parikesit & David Agustriawan (i3L Press, 2022). Use when running or teaching the i3L transcriptomics lab: Linux basics, BLAST+ (makeblastdb/blastp), Bowtie/Bowtie2 indexing and read mapping, TopHat spliced alignment, Cufflinks transcript assembly/FPKM, RNA-seq count filtering in R (edgeR CPM), and GSEA desktop analysis."
allowed-tools:
  - Read
  - Grep
argument-hint: [topic, tool name, or chapter number]
---

# Transcriptomics Computational Protocol (Course BI021)
**Authors**: Arli Aditya Parikesit, David Agustriawan | **Editors**: Parikesit, Agustriawan, Andamar Pradipta | **Publisher**: i3L Press, Jakarta, 2022 (ISBN 978623884904) | **Pages**: 60 | **Chapters**: 6 lab sessions | **Generated**: 2026-09-21

## How to Use This Skill

- **No arguments** — load the pipeline map and core rules below
- **With a tool/topic** — e.g. `tophat`, `CPM filter`, `leading edge`; I open the matching chapter
- **With chapter** — `ch03` loads TopHat protocol
- **Browse** — "what chapters do you have?"

For command syntax, parameter meanings, or expected outputs not listed here, read the chapter file before answering.

---

## Core Framework: The Course Pipeline

```
Reads (FASTQ) + reference genome (FASTA)
  │  ch02 Bowtie / Bowtie2  → build BWT index, map unspliced reads
  ▼
  │  ch03 TopHat (uses Bowtie2) → spliced alignment, junctions → accepted_hits.bam
  ▼
  │  ch04 Cufflinks → transcripts.gtf + genes/isoforms.fpkm_tracking → UCSC browser
  ▼
Count table (featureCounts)  → ch05 R/edgeR: read, reshape, CPM filter, plot
  ▼
Ranked expression + phenotypes → ch06 GSEA: enriched gene sets, leading edge
Side track: ch01 Linux + BLAST+ homology search (zebrafish vs mouse proteomes)
```

Every protocol shares the same **three learning objectives**: (1) know the input files and formats, (2) know how to process them with the tool, (3) know the output format and how to interpret it. Use this triad when explaining or troubleshooting any step: *input → command → output interpretation*.

## Key Principles (use X when Y)

1. **Index before you map.** Bowtie/Bowtie2 need a Burrows–Wheeler index of the reference (`bowtie-build` / `bowtie2-build <ref.fa> <basename>`). Mapping commands take the *basename*, not the `.fa` file. BWT keeps memory small (~2.2 GB human, 2.9 GB paired-end).
2. **Use Bowtie for unspliced DNA reads; TopHat for RNA-seq.** TopHat handles reads spanning exon–exon junctions and delegates the rest to Bowtie2 — install Bowtie2 first.
3. **Judge mapping rate against the reference you used.** Mapping to chr20 only → ~0.6% mapped is expected. Whole genome → expect 80–90% aligned, up to 10–15% multi-mapped. Bowtie E. coli demo: 699/1000 (69.9%) aligned.
4. **`accepted_hits.bam` is the hand-off file.** TopHat's BAM feeds Cufflinks (and counting). Manipulate BAMs (sort/merge/view) with samtools.
5. **Filter lowly expressed genes on CPM, never raw counts.** CPM normalises library size. Rule: pick the CPM corresponding to a count of ~10 (≈0.5 in GSE60450); keep genes above it in ≥ *n* samples, *n* = smallest group size (here 2).
6. **Keep sample metadata aligned with count columns.** After renaming columns (`substr(...,1,7)`), assert `table(colnames(countdata)==sampleinfo$SampleName)` is all TRUE.
7. **GSEA: identifiers must match across all files.** Default *Collapse dataset to gene symbols = true* → gene sets must use HUGO symbols; collapsing removes multi-probe inflation of enrichment scores.
8. **GSEA: pilot with few permutations.** Run 5 permutations to confirm setup, then 1000 for real results; permutation type = phenotype.
9. **Run long jobs in background and monitor.** Append `&` to all-vs-all BLAST; track progress with `grep Query= out | wc -l` versus `grep '^>' query.faa | wc -l`.

## Canonical Commands (quick)

```bash
# BLAST+ (ch01)
makeblastdb -in mouse.1.protein.faa -dbtype prot
blastp -query zebrafish.top -db mouse.1.protein.faa -evalue 1e-6 -out xxx.txt
# Bowtie 1 (ch02)
bowtie-build NC_008253.fna e_coli_0157_h7
bowtie -t index1/e_coli_0157_h7 reads/e_coli_1000.fq e_coli1.map
bowtie -S index1/e_coli_0157_h7 reads/e_coli_1000.fq e_coli1.sam
# TopHat (ch03)
bowtie2-build chr20.fa chr20
tophat -N 3 --read-edit-dist 5 --read-realign-edit-dist 2 -i 50 -I 5000 \
  --max-coverage-intron 5000 -M -o out index/chr20 humanbrain/L6_18_GTGAAA_L007_R1_001.fastq
# Cufflinks (ch04)
cufflinks -o tophat.cufflinks tophat.out/accepted_hits.bam
```
```r
# edgeR CPM filter (ch05)
myCPM <- cpm(countdata); thresh <- myCPM > 0.5
keep <- rowSums(thresh) >= 2; counts.keep <- countdata[keep, ]   # 15804 of 27179 genes kept
```

## Known Errata in the Source (fix when following it)

- En-dash `–in`, `–t`, `–N`, `rm –r` in PDF text → must be ASCII hyphen `-`.
- `head -3 zebrafish.protein.faa` → file is `zebrafish.1.protein.faa`.
- Bowtie index folder named `index1` but command uses `indexes1/`; output `e_colli1.map` vs `e_coli1.map`. Use one name consistently.
- TopHat text says "22nd chromosome" — the reference is **chr20**.
- Machine paths (`/home/i3l-25/Software`, `i3l-27/Softwares`) are lab-specific: substitute your own user/folder.
- Erratum page: use GRCh38.p13 (`GCF_000001405.39`) reference and 1000 Genomes `SRR014948.recal.fastq.gz`; `.gz` files → `gunzip`, `.tar.gz` → `tar -xzvf`.
- Book prints Cufflinks (session 4) before TopHat (session 3); run TopHat first.

## Modern Equivalents (outside the book — mention when relevant)
TopHat/Cufflinks are deprecated → HISAT2 + StringTie (or STAR + featureCounts); Java Web Start GSEA → GSEA 4.x desktop or `fgsea`/`clusterProfiler` in R; NCBI `ftp://` → `https://ftp.ncbi.nlm.nih.gov/`. Downstream DE after CPM filtering: edgeR/limma-voom (see `R-bioinformatics`, `deseq2-differential-expression` skills).

---

## Chapter Index

| # | Title | Key Frameworks / Tools |
|---|-------|------------------------|
| [ch01](chapters/ch01-linux-blast.md) | BLAST tutorial in Linux Ubuntu | Ubuntu command list, makeblastdb, blastp, e-value, `&` + pipe monitoring |
| [ch02](chapters/ch02-bowtie.md) | Bowtie (Session 2) | BWT index, bowtie-build, default `.map` vs SAM output, alignment report |
| [ch03](chapters/ch03-tophat.md) | TopHat (Session 3) | bowtie2-build, spliced mapping, intron/edit-distance params, align_summary, erratum |
| [ch04](chapters/ch04-cufflinks.md) | Cufflinks (Session 4) | transcript assembly, FPKM tracking files, UCSC custom track + Table Browser |
| [ch05](chapters/ch05-rnaseq-in-r.md) | RNA-Seq in R (Session 5) | GSE60450 mouse mammary, count matrix reshaping, edgeR CPM filter rule |
| [ch06](chapters/ch06-gsea.md) | GSEA Tutorial | 4 input files (.gct/.cls/.gmt/.chip), run params, collapse, leading edge, MSigDB |

## Topic Index

- **accepted_hits.bam** → ch03, ch04
- **align_summary.txt / mapping rate** → ch02, ch03
- **BLAST database (makeblastdb)** → ch01
- **blastp, e-value** → ch01
- **Bowtie / bowtie-build** → ch02
- **Bowtie2 / bowtie2-build** → ch03
- **Burrows–Wheeler index** → ch02
- **Chip annotation (.chip)** → ch06
- **Collapse to gene symbols** → ch06
- **CPM filtering / edgeR cpm()** → ch05
- **Cufflinks, FPKM** → ch04
- **Edit distance** → ch03
- **featureCounts** → ch05
- **GSE60450 / Fu et al. 2015** → ch05
- **GSEA files (.gct .cls .gmt)** → ch06
- **junctions.bed, insertions/deletions.bed** → ch03
- **Leading edge analysis** → ch06
- **Linux commands** → ch01
- **MSigDB** → ch06
- **Multi-mapped reads (-M)** → ch03
- **P53 sample data** → ch06
- **Permutations** → ch06
- **SAM output (-S)** → ch02
- **samtools** → ch03
- **Splice junctions** → ch03
- **substr column renaming** → ch05
- **transcripts.gtf** → ch04
- **UCSC custom track / Table Browser** → ch04

## Supporting Files

- [glossary.md](glossary.md) — key terms with definitions
- [patterns.md](patterns.md) — reusable techniques from the protocols
- [cheatsheet.md](cheatsheet.md) — one-page commands, parameters, file formats

---

## Scope & Limits

Covers the six lab protocols only. The R session stops at filtering and a CPM-vs-count plot (no normalisation/DE testing). GSEA is the GUI walkthrough (no algorithm math). For modern pipelines or full DE analysis, pair with `R-bioinformatics`, `pydeseq2`, or `deseq2-differential-expression`.
