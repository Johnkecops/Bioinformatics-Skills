# Patterns & Techniques

## Local BLAST Database Search
**When to use**: homology search against a downloaded proteome.
**How**: `wget` RefSeq `.faa.gz` → `gunzip *.gz` → `makeblastdb -in X.faa -dbtype prot` → `blastp -query q.faa -db X.faa -evalue 1e-6 -out hits.txt`.
**Trade-offs**: fast and offline; databases must be rebuilt when proteomes update.

## Reciprocal All-vs-All BLAST
**When to use**: ortholog inference between two species.
**How**: run A→B and B→A `blastp` in background (`&`); later extract reciprocal best hits.
**Trade-offs**: hours of CPU; add `-outfmt 6 -max_target_seqs 1 -num_threads N` for tractable output (beyond book).

## Background Job Progress Estimate
**When to use**: any long streaming job writing one record per query.
**How**: `grep Query= out | wc -l` vs `grep '^>' query.faa | wc -l`.
**Trade-offs**: rough; depends on output format containing a per-query marker.

## Index-then-Map (Bowtie/Bowtie2)
**When to use**: first alignment against a new reference.
**How**: `bowtie-build ref.fa base` (or `bowtie2-build`) → keep index files in one folder → pass `folder/base` to aligner.
**Trade-offs**: indexing is slow once, mapping fast forever.

## Choose Output Format for Downstream
**When to use**: Bowtie mapping.
**How**: default `.map` for quick inspection; `-S` SAM for samtools/other tools.
**Trade-offs**: SAM is large; convert to BAM.

## De Novo Spliced Alignment (TopHat)
**When to use**: RNA-seq reads, no annotation GTF.
**How**: Bowtie2 index → `tophat -i 50 -I 5000 --max-coverage-intron 5000 -N 3 --read-edit-dist 5 --read-realign-edit-dist 2 -M -o out index/base reads.fastq`.
**Trade-offs**: `--read-realign-edit-dist 0` increases accuracy but runtime; `-M` drops multi-mappers (lose repetitive genes).

## Mapping-Rate Sanity Check
**When to use**: after any alignment.
**How**: compare `align_summary.txt` to expectation: partial reference → tiny %; whole genome → 80–90% aligned, ≤10–15% multi.
**Trade-offs**: species/contamination issues also lower rate.

## Transcript Assembly + Browser QC
**When to use**: novel isoforms / FPKM from spliced alignments.
**How**: `cufflinks -o outdir accepted_hits.bam` → upload `transcripts.gtf` to UCSC custom track (matching assembly) → Table Browser.
**Trade-offs**: FPKM not suited to DE testing; tool deprecated (StringTie).

## Count Matrix Hygiene
**When to use**: loading featureCounts-style tables into R.
**How**: drop annotation columns, set IDs as rownames, shorten colnames (`substr`), assert `colnames == sampleinfo$SampleName`.
**Trade-offs**: `substr` length depends on naming scheme.

## CPM Low-Expression Filter
**When to use**: before DE testing.
**How**: `cpm()` → threshold = CPM at count ≈ 10 → keep `rowSums(cpm > t) >= min_group_size`; verify with CPM-vs-count plot.
**Trade-offs**: too strict loses group-specific genes; too loose hurts FDR power.

## GSEA Pilot-then-Full Run
**When to use**: any GSEA analysis.
**How**: load `.gct/.cls/.gmt/.chip`, collapse=true, permutation=phenotype, 5 permutations → confirm success → 1000.
**Trade-offs**: few permutations give unreliable p/FDR.

## Leading Edge Prioritisation
**When to use**: many enriched sets; need core genes.
**How**: select sets with FDR < 0.01 → Run leading edge → prioritise genes shared across subsets.
**Trade-offs**: biased toward large, overlapping gene sets.
