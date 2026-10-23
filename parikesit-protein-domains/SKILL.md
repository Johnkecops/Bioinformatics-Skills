---
name: parikesit-protein-domains
description: "Knowledge base from Dr. Arli Aditya Parikesit's PhD dissertation: \"Evolutionary Analysis of the Protein Domain Distribution in Eukaryotes\" (University of Leipzig, 2012, cum laude). Use when applying the ADD pipeline methodology, reasoning about protein domain co-occurrence/avoidance, gene prediction strategies, cross-species domain annotation, or evolutionary bioinformatics."
allowed-tools:
  - Read
  - Grep
argument-hint: [topic, chapter number, tool name, or framework]
---

# Evolutionary Analysis of the Protein Domain Distribution in Eukaryotes
**Author**: Dr.rer.nat. Arli Aditya Parikesit (University of Leipzig, Germany) | **Year**: 2012 | **Grade**: cum laude | **Chapters**: 9

## How to Use This Skill

- **Without arguments** — load core frameworks for reference
- **With a topic** — ask about `ADD pipeline`, `AUGUSTUS`, `co-occurrence`, or another indexed topic; I find and read the relevant chapter
- **With chapter** — ask for `ch05` or `gene prediction`; I load that chapter
- **Browse** — ask "what chapters do you have?" to see the full index

---

## Core Frameworks & Mental Models

### The ADD Pipeline (Central Contribution)

**Problem solved**: Existing genome annotations (RefSeq, SUPERFAMILY) contain ascertainment biases that make quantitative cross-clade protein domain comparison invalid. Human-dolphin or human-chimp discrepancies in domain counts reflect annotation effort, not biology.

**ADD Pipeline (Arli's Domain Distribution)**:
1. Download genome FASTA for each species
2. AUGUSTUS (online-trained) → non-overlapping ORF predictions; verify with bedtools
3. HMMER3 (E ≤ 10⁻³) against PFAM v26.0 (33,672 models) + SUPERFAMILY v1.75 (9,821 HMMs)
4. Pool domains by GO functional category (7 groups via SDFO + InterPro2GO)
5. Compute expected co-occurrence: `(count_A × count_B) / total_proteins`
6. Test observed vs. expected; classify as co-occurrence (O >> E) or avoidance (O << E)

**Why it works**: De novo gene prediction bypasses transcript-level annotation biases; GO pooling converts sparse individual domain counts into statistically tractable functional group counts.

---

### Domain Database Selection Rule

| Organism | Preferred DB | Reason |
|----------|-------------|--------|
| Protists (Trypanosoma, Leishmania, Giardia, Plasmodium, Dictyostelium, Tetrahymena) | SUPERFAMILY v1.75 | PFAM phylogenetically biased toward multicellular organisms |
| Plants, animals, fungi | PFAM v26.0 | Greater coverage for multicellular organisms |
| Cross-kingdom study | Both + GO pooling | No single database covers full eukaryotic space |

---

### Gene Prediction Selection Rule

- **GENSCAN**: Untrained; fails for polycistronic genomes (kinetoplastids), extreme AT-content (Plasmodium), single-exon genomes (Trichomonas, Giardia). Use only as baseline.
- **AUGUSTUS**: Trainable; handles unusual genome architectures after species-specific training on cDNA data. **Always prefer for quantitative analysis.**
- **Online vs. offline AUGUSTUS**: Online training has longer iteration → more complete models. Use online for final analysis.

---

### Key Biological Findings

1. **TF and CR co-evolve**: Transcription factor and chromatin regulation functional groups are positively correlated across all tested eukaryotes
2. **Avoidance dominates in complex organisms**: Strong avoidance between functional domain groups in large-genome multicellular organisms — reflects paralog expansion and subfunctionalization
3. **No universal patterns**: Strong lineage-specific variation in domain co-occurrence across Eukaryota — no global regulatory domain rules
4. **KRAB-ZNF is vertebrate-specific**: Co-occurrence of KRAB + Zinc Finger domains significant only in human; absent/insignificant in all protists
5. **Scale-free domain networks**: Domain combination networks follow power-law topology; complexity scales with organismal complexity

---

### Co-occurrence Formula
```
Expected(A,B) = (count_A × count_B) / total_proteins
Co-occurrence:  Observed >> Expected  (χ² or Fisher's exact, significant)
Avoidance:      Observed << Expected  (significant)
```

---

### Anti-patterns (What Not to Do)

- **Do not compare domain counts directly from RefSeq/SUPERFAMILY across species without checking annotation coverage** — biases invalidate comparisons
- **Do not use GENSCAN for non-model organisms with unusual genome architecture** — systematic over/undercounting
- **Do not use a single domain database for kingdom-wide studies** — PFAM misses protist domains; SUPERFAMILY misses multicellular domains
- **Do not report KRAB-ZNF co-occurrence as universal** — vertebrate-specific signal
- **Do not interpret avoidance in multicellular organisms as universal** — reflects paralog expansion in those lineages, not general biology

---

## Chapter Index

| # | Title | Key Frameworks |
|---|-------|----------------|
| [ch01](chapters/ch01-introduction.md) | Introduction | ADD pipeline motivation, ascertainment bias |
| [ch02](chapters/ch02-biological-background.md) | Biological Background | TF/CR classes, splicing problem, polycistronic genomes |
| [ch03](chapters/ch03-technical-background.md) | Technical Background | HMM, Viterbi, SUPERFAMILY vs. PFAM, GO |
| [ch04](chapters/ch04-quantitative-domain-distributions.md) | Quantitative Domain Distributions | Annotation bias sources, ADD pipeline introduction |
| [ch05](chapters/ch05-gene-prediction.md) | Gene Prediction | AUGUSTUS vs. GENSCAN, species-specific training |
| [ch06](chapters/ch06-domain-annotation-hmm.md) | Protein Domain Annotation Using HMMs | HMMER, PFAM/SUPERFAMILY comparison, Venn validation |
| [ch07](chapters/ch07-protein-domain-distribution.md) | Protein Domain Distribution | Co-occurrence/avoidance math, Zinc finger, scale-free networks |
| [ch08](chapters/ch08-functional-annotation-analysis.md) | Analysis of Functional Annotation | GO pooling, 7 functional groups, TF-CR correlation |
| [ch09](chapters/ch09-conclusion.md) | Conclusion and Outlook | Final results, future directions, deep phylogeny application |

## Topic Index

- **ADD pipeline** → ch01, ch04, ch05, ch06, ch07, ch08, ch09
- **AUGUSTUS** → ch03, ch05, ch06
- **avoidance** → ch07, ch08
- **ascertainment bias** → ch01, ch04, ch06
- **bedtools** → ch05, ch06
- **chromatin regulation (CR)** → ch02, ch08
- **co-occurrence** → ch07, ch08
- **domain annotation** → ch03, ch06
- **E-value** → ch03, ch06
- **GENSCAN** → ch05
- **gene prediction** → ch05
- **gene ontology (GO)** → ch03, ch08
- **HMM / HMMER** → ch03, ch05, ch06
- **KRAB-ZNF** → ch07
- **kinetoplastids** → ch02, ch05
- **Markov chain / Viterbi** → ch03
- **PFAM** → ch03, ch06, ch08
- **polycistronic** → ch02, ch05
- **RefSeq** → ch04, ch05, ch06
- **SCOP** → ch03
- **SUPERFAMILY** → ch03, ch06, ch08
- **transcription factor (TF)** → ch02, ch07, ch08
- **zinc finger** → ch07

## Supporting Files

- [glossary.md](glossary.md) — all key terms with definitions
- [patterns.md](patterns.md) — ADD pipeline patterns and techniques
- [cheatsheet.md](cheatsheet.md) — quick reference tables and decision guides

---

## Scope & Limits

This skill covers the dissertation content: ADD pipeline methodology, protein domain annotation strategies, gene prediction for diverse eukaryotes, and evolutionary analysis of domain distributions across 18 species. For updated tool versions or databases beyond 2012, verify against current releases. For hands-on implementation, combine with current AUGUSTUS/HMMER/PFAM documentation.
