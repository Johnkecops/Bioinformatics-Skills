# Chapter 7: Protein Domain Distribution

## Core Idea
Domain co-occurrence and avoidance tendencies can be quantified using expected-vs-observed counts; Zinc Finger domain shows strongly species-specific co-occurrence patterns (significant only in human for KRAB-ZNF pair).

## Frameworks Introduced
- **Domain Co-occurrence Quantification (Expectation Method)**:
  - Observed co-occurrence: count of proteins containing both domain A and domain B
  - Expected count: (count_A × count_B) / total_proteins
  - Significance cut-off: based on χ² or Fisher's exact test
  - When to use: Determine whether two domains co-occur more/less than chance in a given species

- **Co-occurrence vs. Avoidance Classification**:
  - Co-occurrence: observed > expected (significant by chosen cutoff) — domains tend to appear together
  - Avoidance: observed < expected (significant) — domains tend to be mutually exclusive
  - Neutral: no significant deviation from expected
  - Biological implication: co-occurrence may indicate functional cooperation; avoidance may indicate functional redundancy or incompatibility

- **Domain Distribution Network Topology**:
  - Small-world and scale-free topology: few highly connected domain hubs
  - Network complexity grows with organism complexity (unicellular → multicellular)
  - Zinc finger domain family is a major hub in TF domain networks

## Key Concepts
- **Zinc Finger (ZNF) domain**: Most abundant TF domain class; co-occurrence with KRAB domain significant only in human among tested species — points to vertebrate-specific regulatory innovation
- **KRAB-ZNF pair**: Vertebrate-specific combination; its absence in protists indicates lineage-specific co-occurrence
- **Scale-free network**: Domain combination networks follow power law — few domains appear in many combinations
- **Significance cut-off**: Avoidance/co-occurrence declared only when deviation from expected exceeds statistical threshold
- **Individual domain pair limitation**: Two-domain pairwise analysis underpowered for protists — insufficient data points

## Anti-patterns
- **Reporting KRAB-ZNF significance across all eukaryotes**: Meaningful only in vertebrates; protist data is insignificant — do not generalize
- **Using domain pair analysis alone for cross-kingdom statistics**: Individual pairs are too sparse in non-metazoan genomes; need GO pooling (Ch8)

## Key Takeaways
1. Domain co-occurrence defined as: observed > expected count (statistically significant)
2. Avoidance defined as: observed < expected (statistically significant)
3. KRAB-ZNF co-occurrence is vertebrate-specific — absent/insignificant in protists
4. Zinc finger is a major regulatory hub domain with strongly lineage-specific co-occurrence patterns
5. Individual domain pair analysis insufficient for protists — motivation for GO-pooled analysis in Ch8
6. Domain networks are small-world and scale-free; complexity scales with organismal complexity

## Connects To
- **Ch6**: Domain annotation output used as input for co-occurrence calculations
- **Ch8**: Individual pair analysis → GO functional pooling to solve statistical power problem
- **Ch9**: Lineage-specific co-occurrence patterns as major conclusion
