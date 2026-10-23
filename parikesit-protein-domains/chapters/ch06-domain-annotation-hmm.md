# Chapter 6: Protein Domain Annotation Using HMMs

## Core Idea
AUGUSTUS online predictions + PFAM annotation provide the best coverage of manually curated RefSeq data across 18 eukaryotes; SUPERFAMILY is preferable for protists, PFAM for multicellular organisms.

## Frameworks Introduced
- **Annotation Quality Test (Venn Overlap)**:
  - For each species: compare genes with ≥1 annotated domain between AUGUSTUS-online, AUGUSTUS-offline, and RefSeq
  - Tool: bedtools overlap + Venn diagrams
  - Selection criterion: method with highest overlap with RefSeq = best annotation source
  - Result: AUGUSTUS online wins for most species

- **SUPERFAMILY vs. PFAM Complementarity**:
  - SUPERFAMILY better for: Giardia, Trypanosoma, Leishmania, Plasmodium, Tetrahymena, Dictyostelium (protists)
  - PFAM better for: Plants (Arabidopsis, Oryza), Animals (Homo, Drosophila, C. elegans), Fungi
  - Mechanistic reason: PFAM built from sequence-rich datasets dominated by well-studied multicellular organisms

## Key Concepts
- **Domain annotation coverage**: Fraction of predicted genes with ≥1 annotated domain; used as quality proxy
- **Annotation parameters**: HMMER3.0rc1, E ≤ 10⁻³; PFAM v26.0 (33,672 models); SUPERFAMILY v1.75 (9,821 HMMs)
- **RefSeq release 53**: Baseline reference; comparison target for ADD pipeline validation
- **False positive ORF**: Unlikely to contain recognizable domains — justifies lenient E-value (false ORFs don't match domain HMMs)

## Reference Tables
| Source | Database | Version | Models |
|--------|---------|---------|--------|
| SUPERFAMILY | SCOP structural | 1.75 | 9,821 HMMs |
| PFAM | Sequence-based | 26.0 | 33,672 domain models |
| HMMER | Search tool | 3.0rc1 | — |

SUPERFAMILY outperforms PFAM for protists (Trypanosoma, Leishmania, Giardia etc.). PFAM outperforms SUPERFAMILY for multicellular organisms.

## Anti-patterns
- **Using GENSCAN predictions for quantitative domain analysis**: GENSCAN annotation coverage is inferior; AUGUSTUS offline/online substantially better
- **Single database annotation for a cross-kingdom study**: No single HMM database covers the full eukaryotic domain space equally

## Key Takeaways
1. AUGUSTUS online + PFAM = best quantitative coverage for most eukaryotes
2. SUPERFAMILY outperforms PFAM specifically for protists due to phylogenetic bias in PFAM training data
3. False ORFs from gene prediction are not a major problem — they lack detectable domains
4. RefSeq genes missed by gene predictor are predominantly pseudogenes and unannotated ORFs
5. Combining SUPERFAMILY + PFAM provides more complete domain inventory than either alone

## Connects To
- **Ch3**: HMMER and profile HMM methodology
- **Ch5**: AUGUSTUS predictions are the input here
- **Ch7**: Annotated domains feed into co-occurrence calculations
