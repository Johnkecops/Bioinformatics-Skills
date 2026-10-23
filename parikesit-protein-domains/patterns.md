# Patterns & Techniques — ADD Pipeline

## Pattern: ADD Pipeline (Full Workflow)
**When to use**: Quantitative comparison of protein domain distributions across distantly related eukaryotes
**How**:
1. Download genome FASTA for each species
2. Run AUGUSTUS (online-trained mode) to predict non-overlapping ORFs
3. Verify non-overlap with bedtools
4. Run HMMER3 (E ≤ 10⁻³) against PFAM v26+ and SUPERFAMILY v1.75
5. Pool domains by GO functional category (7 groups)
6. Compute expected co-occurrence: (count_A × count_B) / total_proteins
7. Test observed vs. expected; flag significant co-occurrence/avoidance
8. Compare patterns across species
**Trade-offs**: High computational cost; requires species-specific AUGUSTUS training; Plasmodium and Tetrahymena remain problematic

---

## Pattern: AUGUSTUS Species-Specific Training
**When to use**: Gene prediction for any non-model eukaryote, especially organisms with unusual genome architecture
**How**:
1. Download cDNA sequences from GenBank for target species
2. Remove redundancies with PERL script
3. Clean FASTA headers (remove meta-characters and gaps)
4. Train AUGUSTUS locally (offline) or via web pipeline (online)
5. Prefer online training (longer iteration = more complete model)
6. Configure AUGUSTUS for non-overlapping gene predictions only
7. Disable UTR prediction for non-human/non-standard genomes
**Trade-offs**: Online training can exceed one day; offline capped at ~1 day; for species with unusual architecture (polycistronic, single-exon) training may still be insufficient

---

## Pattern: Domain Database Selection by Organism Type
**When to use**: Choosing between SUPERFAMILY and PFAM for annotation
**How**:
- Protists (Trypanosoma, Leishmania, Giardia, Plasmodium, Tetrahymena, Dictyostelium) → SUPERFAMILY
- Multicellular organisms (plants, metazoa, fungi) → PFAM
- Cross-kingdom study → use both; pool by GO
**Trade-offs**: PFAM has 3.4x more models than SUPERFAMILY; SUPERFAMILY structurally grounded; PFAM sequence-biased toward well-studied organisms

---

## Pattern: GO Functional Pooling for Statistical Power
**When to use**: Domain co-occurrence analysis where individual domain counts are too sparse (esp. protists)
**How**:
1. Map all SUPERFAMILY IDs → GO via SDFO (v1.75)
2. Map all PFAM IDs → GO via InterPro2GO
3. Assign each domain to one or more of 7 functional groups
4. Aggregate domain counts per functional group per species
5. Compute co-occurrence/avoidance at functional group level instead of individual domain level
**Trade-offs**: Loses resolution on individual domain identities; gains statistical power; 7 groups is a minimal but workable partition

---

## Pattern: Annotation Quality Validation via Venn Overlap
**When to use**: Validating gene prediction quality before downstream domain analysis
**How**:
1. For each species, collect: AUGUSTUS-online genes, AUGUSTUS-offline genes, RefSeq genes
2. Filter each set to genes with ≥1 annotated PFAM/SUPERFAMILY domain
3. Compute pairwise overlaps using bedtools
4. Visualize as Venn diagrams
5. Select prediction method with highest overlap with RefSeq as primary data source
**Trade-offs**: RefSeq itself may be incomplete; overlap with incomplete reference does not guarantee biological accuracy

---

## Pattern: Chromosome Fragmentation for GENSCAN
**When to use**: Running GENSCAN on chromosomes >500 kb
**How**:
1. Fragment long chromosomes into overlapping ~500 kb segments
2. Run GENSCAN on each fragment independently
3. Remove duplicate predictions in overlapping regions
**Trade-offs**: Overlap removal is imperfect; GENSCAN may misidentify gene boundaries at fragment edges

---

## Pattern: Domain Co-occurrence Statistical Test
**When to use**: Determining whether two domains (or functional groups) co-occur or avoid each other
**How**:
1. Count observed proteins containing both domain A and domain B: O_AB
2. Count total proteins with domain A: n_A; total with B: n_B; total proteins: N
3. Expected: E_AB = (n_A × n_B) / N
4. Test O_AB vs E_AB with χ² or Fisher's exact test
5. Co-occurrence if O_AB >> E_AB (significant); avoidance if O_AB << E_AB (significant)
**Trade-offs**: Assumes independence of domain occurrences; paralog expansion in multicellular organisms violates this; results should be interpreted relative to lineage context
