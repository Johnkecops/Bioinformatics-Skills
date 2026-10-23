# Cheatsheet — Transcriptomics Protocol BI021

## Which tool?
| Task | Tool (book) | Modern alt |
|---|---|---|
| Protein homology | blastp | DIAMOND |
| DNA short reads → genome | Bowtie | Bowtie2/BWA |
| RNA-seq reads → genome (spliced) | TopHat (+Bowtie2) | HISAT2, STAR |
| Transcript assembly/FPKM | Cufflinks | StringTie |
| Count filtering / DE | edgeR in R | edgeR, limma-voom, DESeq2 |
| Pathway enrichment | GSEA desktop | fgsea, clusterProfiler |

## Commands
```bash
makeblastdb -in db.faa -dbtype prot
blastp -query q.faa -db db.faa -evalue 1e-6 -out out.txt &
bowtie-build ref.fna base ; bowtie -t idx/base reads.fq out.map ; bowtie -S idx/base reads.fq out.sam
bowtie2-build chr20.fa chr20
tophat -N 3 --read-edit-dist 5 --read-realign-edit-dist 2 -i 50 -I 5000 --max-coverage-intron 5000 -M -o out index/chr20 reads.fastq
cufflinks -o tophat.cufflinks tophat.out/accepted_hits.bam
```
```r
myCPM <- cpm(countdata); keep <- rowSums(myCPM > 0.5) >= 2; counts.keep <- countdata[keep, ]
```

## TopHat parameters
| Flag | Meaning | Value |
|---|---|---|
| `-i` / `-I` | min / max intron | 50 / 5000 |
| `--max-coverage-intron` | max intron in coverage search | 5000 |
| `-N` | max mismatches in final alignment | 3 |
| `--read-edit-dist` | max edit distance | 5 |
| `--read-realign-edit-dist` | realign if ≥ | 2 (0 = all) |
| `-M` | whole-genome, drop multi-mappers | on |
| `-o` | output dir | out |

## Outputs
| Tool | Key files |
|---|---|
| Bowtie | `.map` / `.sam`, terminal % aligned |
| TopHat | `align_summary.txt`, `accepted_hits.bam`, `junctions.bed`, `insertions.bed`, `deletions.bed` |
| Cufflinks | `transcripts.gtf`, `genes.fpkm_tracking`, `isoforms.fpkm_tracking` |
| GSEA | `index.html` report in output folder |

## GSEA files
`.gct` expression · `.cls` phenotypes · `.gmt` gene sets · `.chip` probe→HUGO

## Expected numbers
- Bowtie E. coli demo: 699/1000 aligned (69.9%)
- TopHat chr20 only: ~0.6% mapped (normal); whole genome: 80–90%, multi ≤10–15%
- GSE60450: 27179 genes → 15804 kept; 12 samples (6 groups × 2)
- CPM 0.5 ≈ 10–15 counts

## Rules
- Hyphens, not en-dashes, in flags.
- Filter on CPM, not counts; min samples = smallest group.
- GSEA IDs consistent; collapse=true; 5 → 1000 permutations.
- UCSC genome build must match reference.
