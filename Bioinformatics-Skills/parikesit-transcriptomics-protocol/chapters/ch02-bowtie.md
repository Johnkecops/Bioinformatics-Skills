# Chapter 2: Bowtie (Session 2)

## Core Idea
Map short NGS reads (FASTQ) to a reference genome (FASTA) with Bowtie: build a Burrows–Wheeler index, align, and read the alignment report and output (default `.map` or SAM).

## Frameworks Introduced
- **Input → Process → Output triad** (course-wide objectives): know input formats, how to run the tool, how to interpret output.
- **Index-then-map**
  - When to use: every Bowtie/Bowtie2 run against a new reference
  - How: `bowtie-build <genome.fna> <basename>` → move index files into a folder → `bowtie <folder/basename> <reads.fq> <out>`

## Key Concepts
- **Bowtie**: ultrafast short-read aligner; >25 million 35-bp reads/hour to human genome.
- **Burrows–Wheeler (BWT) index**: compressed genome index; ~2.2 GB human (2.9 GB paired-end).
- **FASTQ (.fq)**: reads + qualities; demo `e_coli_1000.fq` = 1,000 × 35-bp reads.
- **Reference FASTA (.fna)**: `NC_008253.fna`, E. coli O157:H7 genome.
- **Basename**: prefix shared by index files (`e_coli_0157_h7`); what you pass to `bowtie`.
- **`-t`**: print timing info.
- **`-S`**: write SAM instead of Bowtie's default output.
- **Alignment report**: reads processed / ≥1 reported alignment / failed to align.

## Code Examples
```bash
cd bowtie-1.2.1.1/genome
bowtie-build NC_008253.fna e_coli_0157_h7        # creates *.ebwt index files
mkdir ../index1 && mv e_coli_0157_h7.* ../index1/
cd ..
bowtie -t index1/e_coli_0157_h7 reads/e_coli_1000.fq e_coli1.map
more e_coli1.map
bowtie -S index1/e_coli_0157_h7 reads/e_coli_1000snp.fq e_coli1.sam
more e_coli1.sam
```
- **What it demonstrates**: full index → map → inspect loop; default and SAM outputs.

## Reference Tables

| Result (demo) | Value |
|---|---|
| Reads processed | 1000 |
| ≥1 reported alignment | 699 (69.90%) |
| Failed to align | 301 (30.10%) |

## Anti-patterns
- **Passing the FASTA to `bowtie` instead of the index basename**: fails; bowtie reads index files.
- **Inconsistent folder names**: PDF creates `index1` but types `indexes1/`; also `e_colli1.map` vs `e_coli1.map`. Pick one.
- **Using Bowtie for spliced RNA-seq reads**: junction-spanning reads fail; use TopHat/HISAT2 (Ch 3).

## Key Takeaways
1. Build the index once per reference; reuse its basename.
2. Keep index files together in one folder.
3. Read the terminal report — alignment % is the first QC check.
4. Use `-S` for SAM so downstream tools (samtools) can read it.
5. Sources: reads via SRA/ENA (biostars.org/p/111040), genomes via Ensembl FTP.

## Connects To
- **Ch 3**: TopHat wraps Bowtie2 and adds splice detection.
- **Ch 1**: shell navigation.
- **Bowtie manual** `bowtie-bio.sourceforge.net/manual.shtml#algn_out` for output columns.
