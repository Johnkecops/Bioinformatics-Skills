# Chapter 3: TopHat (Session 3)

## Core Idea
Align RNA-seq reads to a reference and discover splice junctions de novo with TopHat, which uses Bowtie2 for contiguous reads and handles exon–exon junction reads itself.

## Frameworks Introduced
- **Division of labour: TopHat ↔ Bowtie2** — Bowtie2 maps reads lying inside exons; TopHat resolves reads spanning junctions. Install Bowtie2 first.
- **Workspace layout**
  - `Software/humanbrain/` (FASTQ), `Software/index/` (chr20.fa + Bowtie2 index), `Software/out/` (results)
- **Interpret mapping rate relative to reference size** (see Mental Models).

## Key Concepts
- **Dataset**: `humanbrain.tar.gz` (insidedna.me) → `chr20.fa` + `L6_18_GTGAAA_L007_R1_001.fastq`.
- **bowtie2-build chr20.fa chr20**: produces `chr20.*.bt2` index.
- **-i / -I**: min / max intron length (50 / 5000).
- **--max-coverage-intron**: max intron length in coverage search (5000).
- **-N 3**: discard final alignments with >3 mismatches.
- **--read-edit-dist 5**: max edit distance accepted for reads.
- **Edit distance**: total mismatched + inserted + deleted bases vs reference; main alignment-quality metric.
- **--read-realign-edit-dist 2**: realign reads whose edit distance ≥ this; 0 = realign all (more accurate, slower).
- **-M**: whole-genome mapping mode; exclude multi-mapped reads.
- **-o out**: output directory.

## Code Examples
```bash
cd ~/Software && tar -xzvf humanbrain.tar.gz
mkdir index && mv humanbrain/chr20.fa index/
cd index && bowtie2-build chr20.fa chr20 && cd ..
tophat -N 3 --read-edit-dist 5 --read-realign-edit-dist 2 -i 50 -I 5000 \
  --max-coverage-intron 5000 -M -o out \
  ~/Software/index/chr20 ~/Software/humanbrain/L6_18_GTGAAA_L007_R1_001.fastq
# ~40 min
```
- **What it demonstrates**: de novo spliced alignment without annotation.

## Reference Tables

| Output | Content / use |
|---|---|
| `align_summary.txt` | total mapped + multi-mapped reads |
| `accepted_hits.bam` | main alignments → counting / Cufflinks input; handle with samtools |
| `junctions.bed` | intron coordinates |
| `insertions.bed`, `deletions.bed` | indel coordinates |

**Erratum (full-genome option)**: reference `GCF_000001405.39_GRCh38.p13_genomic.fna.gz` (NCBI Homo_sapiens 109.20190905); sample `SRR014948.recal.fastq.gz` (1000 Genomes NA19308). Uncompress with `gunzip`/`tar -xzvf`.

## Mental Models
- Chr20-only reference → ~0.6% mapped is *correct*, not a failure (chromosome ≈ 1–2% of genome).
- Whole genome → expect 80–90% aligned, ≤10–15% multi-mapped. Much lower = wrong reference/species or bad library.
- Think of `accepted_hits.bam` as the contract between alignment and quantification.

## Anti-patterns
- **Copying `–N`, `–M` with en-dashes** from the PDF.
- **Hardcoded lab paths** (`/home/i3l-25/Software`): replace user number and `Software` vs `Softwares`.
- **Text says "22nd chromosome"** — dataset is chr20.
- **Starting TopHat without Bowtie2 on PATH**: TopHat calls it internally.
- **Using TopHat in new projects**: deprecated; prefer HISAT2 (outside book).

## Key Takeaways
1. Build a Bowtie2 (not Bowtie1) index for TopHat.
2. Set intron bounds when discovering junctions de novo.
3. Check `align_summary.txt` first.
4. Pass `accepted_hits.bam` to Cufflinks (Ch 4).

## Connects To
- **Ch 2**: indexing concept.
- **Ch 4**: Cufflinks consumes `accepted_hits.bam`.
- **samtools**: sort/merge/view BAM.
