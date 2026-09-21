# Chapter 4: Cufflinks (Session 4)

## Core Idea
Assemble TopHat alignments into a parsimonious set of transcripts, estimate abundances (FPKM) accounting for library-prep bias, and visualise the assembly in the UCSC Genome Browser.

## Frameworks Introduced
- **Align → Assemble → Quantify → Visualise**
  - Input: `tophat.out/accepted_hits.bam`
  - Run: `cufflinks -o <outdir> <bam>`
  - Output: GTF + FPKM tracking tables
  - Visualise: upload `transcripts.gtf` as UCSC custom track → Table Browser
- **Parsimony assembly**: fewest transcripts that explain the reads; abundance from reads supporting each.

## Key Concepts
- **Cufflinks**: transcript assembly, abundance estimation, differential expression/regulation testing.
- **FPKM**: fragments per kilobase of transcript per million mapped reads.
- **transcripts.gtf**: assembled transcript models (genome-browser track).
- **isoforms.fpkm_tracking**: per-transcript expression.
- **genes.fpkm_tracking**: per-gene expression.
- **UCSC custom track**: `genome.ucsc.edu/cgi-bin/hgCustom`; clade mammal, genome human.
- **Table Browser**: export/inspect custom-track records ("get output").

## Code Examples
```bash
cd ~/Softwares
cufflinks -o tophat.cufflinks tophat.out/accepted_hits.bam
cd tophat.cufflinks && ls
more genes.fpkm_tracking      # Enter = more, q = quit
```
- **What it demonstrates**: minimal Cufflinks run on TopHat output.

## Reference Tables

| File | Use |
|---|---|
| `transcripts.gtf` | view in UCSC/IGV |
| `isoforms.fpkm_tracking` | transcript-level expression |
| `genes.fpkm_tracking` | gene-level expression |

UCSC steps: Clade = mammal → Genome = human (match your assembly) → upload `transcripts.gtf` → Submit → choose Table Browser → Go → Get output.

## Anti-patterns
- **Running Cufflinks before TopHat**: book prints this session first, but it needs `accepted_hits.bam`.
- **Genome build mismatch in UCSC**: GTF coordinates must match selected assembly (e.g. hg38 for GRCh38).
- **Comparing FPKM across samples as DE**: use Cuffdiff or count-based methods (Ch 5) instead.

## Key Takeaways
1. Cufflinks input = sorted BAM from a spliced aligner.
2. Three core outputs: GTF + two FPKM tables.
3. Always eyeball assemblies in a genome browser.
4. Interpret columns with the Cufflinks manual (garberlab.umassmed.edu/data/RNASeqCourse/cufflinks.manual.pdf); Trapnell et al. 2012 protocol (PMC3334321).

## Connects To
- **Ch 3**: produces the input BAM.
- **Ch 5**: count-based alternative for DE.
- **StringTie**: modern successor (outside book).
