# Chapter 4: Quantitative View of Protein Domain Distributions

## Core Idea
Existing domain annotation data (SUPERFAMILY, RefSeq) shows dramatic inter-species discrepancies that violate phylogenetic expectations, demonstrating that re-annotation via the ADD pipeline is necessary.

## Frameworks Introduced
- **Domain Distribution as Evolutionary Fingerprint**:
  - Protein domain abundance + co-occurrence encodes metabolic/regulatory capability at kingdom level
  - More informative than individual gene/protein comparisons for deep evolutionary time
  - When to use: Comparing regulatory complexity across phylum-level or higher taxonomic groups

- **Domain Re-annotation Necessity Framework**:
  - Step 1: Show existing annotation discrepancy (human vs. chimp TF counts differ 2x — biologically implausible)
  - Step 2: Identify source (different annotation depth, not biology)
  - Step 3: Justify pipeline development (ADD)
  - When to use: Any cross-species domain count comparison using public databases

- **Arli's Domain Distribution (ADD) Pipeline** (formal introduction):
  - Left path: de novo gene prediction → AUGUSTUS ORFs → HMMER domain scan
  - Right path (baseline): RefSeq transcripts → ORF detection → HMMER domain scan
  - Statistical comparison of both paths validates pipeline

## Key Concepts
- **Ascertainment bias sources** (4 identified):
  1. Different completeness of protein annotation per genome
  2. Differences in transcript coverage (model vs. non-model organisms)
  3. Different domain coverage at kingdom level
  4. Misannotations (e.g., chromodomain annotated as TF in SCOP)
- **Chromodomain (SUPERFAMILY ID 54160)**: Chromatin regulation domain incorrectly classified as TF in SCOP — concrete annotation error example
- **RefSeq**: NCBI reference sequence database; used as gold standard baseline; subject to annotation incompleteness

## Mental Models
- "Model organism inflation": Human has 10x more annotated transcripts than gorilla not because biology differs, but because of research attention
- Domain fusions/fissions are more frequent than domain innovations — comparing combinations is more informative than counting novel domains

## Anti-patterns
- **Using raw domain counts from SUPERFAMILY for cross-species statistics without checking annotation coverage**
- **Accepting human-gorilla domain differences at face value**: Almost always reflects annotation effort, not evolutionary divergence

## Key Takeaways
1. Human-chimp and human-dolphin domain distribution discrepancies in existing data are annotation artifacts
2. Four sources of ascertainment bias in existing annotations — all addressed by ADD pipeline
3. Domain combinations (co-occurrences) are the most tractable unit for kingdom-level evolutionary analysis
4. Chromodomain misclassification demonstrates that even curated databases contain functional errors
5. ADD pipeline designed to produce comparable, bias-minimized domain counts across 18 eukaryotic species

## Connects To
- **Ch1**: Motivation for ADD pipeline
- **Ch5**: ADD pipeline implementation (gene prediction)
- **Ch6**: ADD pipeline implementation (domain annotation)
