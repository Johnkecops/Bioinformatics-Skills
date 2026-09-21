# Chapter 2: Biological Background

## Core Idea
Protein domains are the fundamental evolutionary units of protein function; transcription factors (TF) and chromatin regulators (CR) are the primary regulatory domain classes under study.

## Frameworks Introduced
- **Central Dogma → Domain Annotation Chain**: DNA → (transcription) → pre-mRNA → (splicing) → mRNA → (translation) → protein → (HMM scan) → domain annotation
  - Splicing creates the annotation problem: domains can span splice sites; annotation on genomic DNA requires accounting for intron removal

- **TF + CR as Dual Regulatory Axes**:
  - Transcription Factors (TF): bind DNA regulatory regions, activate/repress gene expression, critical in development
  - Chromatin Regulators (CR): organize DNA via histones, prevent aggregation, facilitate replication and gene expression
  - When to use: Frame evolutionary questions around these two classes for regulatory complexity studies

## Key Concepts
- **Exon**: Nucleic acid sequence retained in mature mRNA after splicing
- **Intron**: Removed sequence; creates domain-spanning problem in annotation
- **CpG Island**: GC-rich genomic region marking gene start; used in HMM gene prediction examples
- **Chromatin**: DNA + histone aggregate; higher-order DNA packaging unit
- **Polycistronic mRNA**: Single mRNA encoding multiple proteins (found in kinetoplastids — creates gene prediction problems)
- **Trans-splicing**: Non-canonical splicing where exons from separate transcripts are joined (kinetoplastids)
- **Gene density**: Varies dramatically across eukaryotes — humans ~2% coding vs. some protists higher

## Mental Models
- Think of genes as lego sets: exons are bricks, alternative splicing rearranges them into different proteins from the same genomic region
- Domains are more conserved than full sequences across deep evolutionary time — use domains for kingdom-level comparisons, sequences only for closely related species
- Chromatin regulation acts as a physical switch; transcription factors as logical gates

## Anti-patterns
- **Equating transcript count with gene count**: Isoforms inflate transcript numbers; use non-redundant predicted proteins
- **Ignoring polycistronic/trans-spliced genomes** (e.g., Trypanosoma, Leishmania): Standard gene predictors fail on these architectures

## Reference Tables
| Regulatory Class | Abbreviation | Function | Domain DB Source |
|-----------------|-------------|----------|-----------------|
| Transcription Factor | TF | Gene activation/repression | SCOP/SUPERFAMILY |
| Chromatin Regulator | CR | DNA organization | SCOP/SUPERFAMILY |

## Key Takeaways
1. Central dogma processing (splicing) is the root cause of annotation bias
2. Domains span intron-exon boundaries — annotating cDNA/mRNA misses cross-splice-site domains
3. TF and CR are the two core regulatory domain classes studied in this dissertation
4. Polycistronic genomes require special handling in any gene prediction pipeline

## Connects To
- **Ch3**: HMM methods used for domain detection
- **Ch5**: Gene prediction must account for these biological structures
- **Ch7**: Domain co-occurrence specifically studied in TF class
