# Chapter 5: RNA-Seq in R (Session 5)

## Core Idea
Start from a gene-level count table (not reads), reshape it into a clean count matrix aligned with sample metadata, and remove lowly expressed genes using a CPM threshold chosen from library size and replicate structure.

## Frameworks Introduced
- **Reads → align → count → statistics in R**: the session enters at the count table (featureCounts output).
- **CPM filtering rule**
  - Threshold: CPM corresponding to a raw count of ~10 (here 0.5 ≈ 10–15 counts)
  - Replicate rule: keep gene if above threshold in ≥ *k* samples, *k* = smallest group size (2)
  - Why: low-count genes add no DE evidence, break statistical approximations, and increase multiple-testing burden (lower FDR power).
- **Metadata-alignment check**: verify sample order before any analysis.

## Key Concepts
- **GSE60450**: Fu et al. 2015 *Nat Cell Biol* (EGF → Mcl-1 at switch to lactation); mouse mammary gland.
- **Design**: basal (B) vs luminal (L) × virgin/pregnant/lactating = 6 groups × 2 replicates = 12 samples.
- **featureCounts**: counted reads on RefSeq mouse genes.
- **seqdata**: col1 EntrezGeneID, col2 Length, cols 3–14 counts.
- **countdata**: counts only, Entrez IDs as rownames.
- **CPM**: counts per million; normalises sequencing depth (`edgeR::cpm`).
- **Data files** (figshare s/1d788fd384d33e913a2a): `sampleinfo.txt`, `SampleInfo_Corrected.txt`, `GSE60450_Lactation-GenewiseCounts.txt`, `mouse_c2_v5.rdata`, `mouse_H_v5.rdata`, `ResultsTable_small.txt`, `small_counts.txt`.

## Code Examples
```r
library(edgeR)
seqdata    <- read.delim("data/GSE60450_Lactation-GenewiseCounts.txt", stringsAsFactors = FALSE)
sampleinfo <- read.delim("data/SampleInfo.txt")
head(seqdata); dim(seqdata)

countdata <- seqdata[, -(1:2)]              # drop EntrezGeneID + Length
rownames(countdata) <- seqdata[, 1]
colnames(countdata) <- substr(colnames(countdata), start = 1, stop = 7)  # "MCL1.DG"...
table(colnames(countdata) == sampleinfo$SampleName)   # expect TRUE 12

myCPM  <- cpm(countdata)
thresh <- myCPM > 0.5
table(rowSums(thresh))                      # 11433 genes TRUE in all 12
keep <- rowSums(thresh) >= 2
counts.keep <- countdata[keep, ]
summary(keep)                               # FALSE 11375, TRUE 15804
dim(counts.keep)                            # 15804 12

plot(myCPM[, 1], countdata[, 1])            # check 0.5 CPM ≈ 10-15 counts
plot(myCPM[, 1], countdata[, 1], ylim = c(0, 50), xlim = c(0, 3)); abline(v = 0.5)
```
- **What it demonstrates**: count-matrix hygiene and principled low-expression filtering.
- Note: book rownames step implied (Entrez IDs as rownames); last zoomed plot is the standard follow-up.

## Anti-patterns
- **Filtering on raw counts**: ignores library-size differences.
- **Requiring expression in all samples**: drops genes expressed in only one group; use ≥ min group size.
- **Fixed CPM across datasets**: larger libraries need smaller CPM thresholds; recompute from count≈10.
- **Skipping the order check** between `colnames(countdata)` and `sampleinfo$SampleName`.

## Key Takeaways
1. Separate annotation columns from counts; keep IDs as rownames.
2. Shorten sample names, then assert match with metadata.
3. Threshold = CPM at ~10 counts; min samples = smallest group size.
4. Visual check: CPM vs count scatter for one sample.
5. Next (beyond book): DGEList, TMM normalisation, MDS, voom/limma or edgeR DE, then GSEA (Ch 6) using `mouse_H_v5.rdata`/`mouse_c2_v5.rdata`.

## Connects To
- **Ch 3–4**: upstream alignment/quantification.
- **Ch 6**: enrichment on DE results.
- Based on the WEHI/Melbourne "RNA-seq analysis in R" course material.
