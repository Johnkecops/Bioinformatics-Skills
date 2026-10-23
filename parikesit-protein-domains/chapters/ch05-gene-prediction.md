# Chapter 5: Gene Prediction

## Core Idea
AUGUSTUS (trained) outperforms GENSCAN (untrained) for gene prediction across diverse eukaryotes; species-specific training is required for organisms with unusual genome architectures.

## Frameworks Introduced
- **GENSCAN vs. AUGUSTUS Selection Criteria**:
  - GENSCAN: untrained, general-purpose, uses HMM; problematic for polycistronic genomes, extreme AT content, intron-poor genomes
  - AUGUSTUS: trainable on species-specific cDNA data; produces non-overlapping predictions; better for cross-species comparison
  - Decision rule: Prefer AUGUSTUS for any multi-species study; fall back to GENSCAN only when training data unavailable

- **Online vs. Offline AUGUSTUS Training**:
  - Online: web-based, longer iteration period → more complete gene models
  - Offline: local, shorter iteration (cap ~1 day) → faster but less complete
  - Recommendation: Use online for final analysis (selected in ADD pipeline)

## Key Concepts
- **Non-overlapping ORF**: ADD pipeline requirement; AUGUSTUS configured specifically for this; verified with bedtools
- **Species-specific training set**: cDNAs from GenBank; redundancies removed; FASTA headers cleaned of meta-characters
- **Polycistronic transcript (kinetoplastids)**: GENSCAN overcounts co-occurrences; AUGUSTUS handles better with training
- **Extreme A/T content (Plasmodium)**: GENSCAN severely underpredicts; AUGUSTUS recovers acceptable counts
- **UTR prediction disabled**: For non-human/Galdieria/Toxoplasma/Caenorhabditis genomes in AUGUSTUS

## Reference Tables
| Species Category | GENSCAN Issue | AUGUSTUS Solution |
|-----------------|--------------|------------------|
| Kinetoplastids (Leishmania, Trypanosoma) | Overcounts (polycistronic) | Species-specific training |
| Plasmodium | Severely undercounts (extreme AT content) | Training corrects |
| Tetrahymena | Undercounts (short scaffolds) | Training corrects |
| Trichomonas, Giardia | Mishandles single-exon genomes | Training corrects |
| Human | Overcounts 118,894 genes (false positives) | Training → 33,507 |

18 species studied: Homo sapiens, Drosophila melanogaster, C. elegans, S. pombe, Aspergillus niger, Dictyostelium discoideum, Oryza sativa, Arabidopsis thaliana, Chlamydomonas reinhardtii, Phytophthora ramorum, Thalassiosira pseudonana, Tetrahymena thermophila, Plasmodium falciparum, Naegleria gruberi, Leishmania major, Trypanosoma brucei, Trichomonas vaginalis, Giardia lamblia

## Anti-patterns
- **Using GENSCAN for organisms with unusual genome architecture**: Systematic over/undercounting renders cross-species statistics meaningless
- **Using overlapping gene predictions**: Creates domain co-occurrence overcounting
- **GENSCAN on Homo sapiens without filtering**: Reports 118,894 genes — 3x biological estimate

## Key Takeaways
1. AUGUSTUS online mode selected for all final ADD pipeline analyses
2. GENSCAN retained as baseline for comparison, not primary annotation
3. Species-specific training is mandatory for protists and other non-standard genomes
4. bedtools used to verify non-overlapping output before domain annotation
5. Chromosome fragmentation to ~500 kb overcomes GENSCAN input length restriction

## Connects To
- **Ch3**: HMM basis of both gene predictors
- **Ch6**: AUGUSTUS output feeds directly into HMMER domain annotation
- **Ch8**: Better gene prediction → better functional annotation statistics
