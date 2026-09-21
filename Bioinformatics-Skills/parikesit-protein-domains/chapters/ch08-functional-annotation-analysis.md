# Chapter 8: Analysis of Functional Annotation

## Core Idea
Pooling domain models by GO functional category (instead of individual domain pairs) provides statistically tractable co-occurrence analysis across all 18 eukaryotes; AUGUSTUS + GO pooling reveals that TF and CR functional groups are correlated, with strong avoidance between functional groups in complex multicellular organisms.

## Frameworks Introduced
- **GO Functional Pooling Strategy**:
  - Problem: Individual domain models too sparse for statistical analysis in many species
  - Solution: Pool all domains sharing the same high-level GO term into one functional group
  - 7 functional groups used: bN (nucleic acid binding), bP (protein binding with nuclear localization), + 5 others
  - When to use: Any cross-species domain analysis where individual domain counts are statistically insufficient

- **ADD Pipeline Final Stage**:
  - Input: AUGUSTUS online-predicted genes
  - Domain scan: HMMER3 against SUPERFAMILY v1.75 + PFAM v26.0
  - Pooling: GO term mapping (SUPERFAMILY SDFO + InterPro2GO)
  - Output: Functional group co-occurrence/avoidance matrix per species

- **SUPERFAMILY Structural Domain Functional Ontology (SDFO)**:
  - Maps SUPERFAMILY superfamily/family IDs → functional/phenotypic annotations
  - Used in combination with InterPro2GO for PFAM-to-GO mapping

## Key Concepts
- **GO functional groups (7 used)**:
  - bN: binding of nucleic acids (GO:0003676)
  - bP: binding of proteins with nuclear localization (GO:0005515)
  - (5 additional groups covering other regulatory/enzymatic functions)
- **GENSCAN-SUPERFAMILY performance**: Tested first; protist data largely insignificant — confirms GENSCAN inadequacy
- **AUGUSTUS-SUPERFAMILY/PFAM performance**: All 18 clades covered with significant co-occurrences
- **TF-CR correlation**: Transcription factor and chromatin regulation functional groups are positively correlated across eukaryotes
- **Avoidance in complex multicellular organisms**: Strong avoidance signal between certain functional groups in organisms with large genomes and large gene families
- **Lineage-specific variation**: Substantial differences in domain co-occurrence patterns between distant lineages — no universal patterns

## Reference Tables
| Pipeline Configuration | Protist Coverage | Metazoa Coverage | Recommendation |
|----------------------|-----------------|-----------------|---------------|
| GENSCAN + SUPERFAMILY | Poor (insignificant) | Moderate | Baseline only |
| AUGUSTUS + SUPERFAMILY | Good | Good | Protists |
| AUGUSTUS + PFAM | Moderate | Excellent | Multicellular |
| AUGUSTUS + GO-pooled | All 18 species | All 18 species | Final analysis |

## Anti-patterns
- **GENSCAN-based functional annotation for cross-kingdom comparison**: Statistically insufficient, especially for protists
- **Interpreting avoidance in large multicellular genomes as universal**: Reflects paralog expansion and subfunctionalization, not a general rule
- **Claiming universal domain co-occurrence patterns**: Data shows strong lineage-specific variation — there are no ubiquitous regulatory domain rules across all eukaryotes

## Key Takeaways
1. GO pooling solves the statistical sparsity problem of individual domain pair analysis
2. AUGUSTUS + GO pooling covers all 18 tested eukaryotic species with significant results
3. TF and CR functional groups are positively correlated — co-evolve across eukaryotes
4. Avoidance predominates in large multicellular organisms (plants, animals) — linked to paralog family expansion
5. Plasmodium and Tetrahymena remain underrepresented even in best pipeline — genome architecture limitations
6. Strong lineage-specific differences disprove a universal domain co-occurrence ruleset

## Connects To
- **Ch7**: Individual pair analysis → GO pooling addresses its limitations
- **Ch9**: These results form the basis of conclusions about eukaryotic domain evolution
