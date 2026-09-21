# Chapter 1: Introduction

## Core Idea
Existing genome annotations contain systematic ascertainment biases that make quantitative cross-species comparison of protein domain distributions unreliable; de novo gene prediction is required to correct this.

## Frameworks Introduced
- **ADD (Arli's Domain Distribution) Pipeline**: Custom pipeline using de novo gene prediction → HMM-based domain annotation → statistical analysis to generate unbiased domain counts.
  - When to use: Quantitative cross-clade comparison of protein domain abundances
  - How: (1) predict non-overlapping ORFs via gene predictor, (2) annotate domains with PFAM/SUPERFAMILY HMMs, (3) compare with RefSeq baseline statistically

## Key Concepts
- **Ascertainment bias**: Systematic over/underrepresentation of domains due to differences in annotation effort between model vs. non-model organisms
- **Domain co-occurrence**: Two or more domains co-existing in the same protein
- **Domain avoidance**: Tendency for certain domain combinations to be absent from proteins
- **Non-overlapping ORF**: Open Reading Frame predicted without isoform redundancy; prevents double-counting

## Mental Models
- Use "genome annotation != domain truth" — existing RefSeq data reflects curation effort, not biology
- Think of domain abundance as an evolutionary fingerprint — richer than single-gene comparisons at kingdom scale
- Domains are units of selection; combinations encode function more than individual sequences

## Anti-patterns
- **Using existing transcriptome data for cross-species domain counting**: Alternate splicing causes overcounting; model organisms have inflated transcript counts
- **Assuming human-dolphin domain distribution parity from RefSeq**: Phylogenetically similar organisms show artificial divergence due to annotation bias

## Key Takeaways
1. Annotation bias from existing databases (RefSeq, SUPERFAMILY) makes clade-wide domain count comparisons invalid
2. De novo gene prediction bypasses transcript-level annotation biases
3. Domain co-occurrence networks grow with organismal complexity
4. ADD pipeline addresses the gap between existing annotation quality and evolutionary analysis requirements
5. Figure 1.2: Human vs. chimp domain discrepancy is artifactual, not biological

## Connects To
- **Ch4**: Quantitative demonstration of annotation biases
- **Ch5**: ADD pipeline Step 1 — gene prediction with GENSCAN/AUGUSTUS
- **Ch6**: ADD pipeline Step 2 — HMM domain annotation
