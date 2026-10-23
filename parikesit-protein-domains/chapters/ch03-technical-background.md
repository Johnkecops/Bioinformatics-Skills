# Chapter 3: Technical Background

## Core Idea
HMMs and the Viterbi algorithm underpin both gene prediction and protein domain annotation; SUPERFAMILY and PFAM are the two primary HMM-based domain databases with complementary strengths.

## Frameworks Introduced
- **Markov Chain → HMM → Viterbi Stack**:
  - Markov Chain: simplest probabilistic model; next state depends only on current state (memoryless)
  - Hidden Markov Model: states are hidden (e.g., CpG vs. non-CpG); observed outputs are sequence bases
  - Viterbi Algorithm: dynamic programming to find the most probable hidden state path through observed sequence
  - Application: gene finding (exon/intron boundary detection), domain annotation (profile HMM scanning)

- **SUPERFAMILY vs. PFAM Annotation Strategy**:
  - SUPERFAMILY: based on SCOP structural classification; better for protists and early-branching eukaryotes
  - PFAM: sequence-based HMM profiles; better coverage for multicellular organisms (plants, metazoa)
  - When to use: Use SUPERFAMILY for protist/unicellular analysis; PFAM for metazoa/fungi; combine both for kingdom-wide studies

## Key Concepts
- **Profile HMM**: HMM trained on multiple sequence alignment; encodes position-specific amino acid probabilities for a domain family
- **E-value threshold**: Statistical significance cutoff for HMM hits; this dissertation uses E ≤ 10⁻³
- **SCOP**: Structural Classification of Proteins; hierarchical: Class → Fold → Superfamily → Family
- **Gene Ontology (GO)**: Controlled vocabulary for gene/protein function; three sub-ontologies: Biological Process, Molecular Function, Cellular Component
- **HMMER**: Software package implementing profile HMM searches; version 3.0rc1 used in ADD pipeline
- **InterPro2GO**: Mapping from Pfam/SUPERFAMILY domain IDs to GO terms; used for functional pooling
- **Viterbi Algorithm**: Finds single best path (decoding); forward algorithm finds total probability; distinction matters for annotation confidence

## Mental Models
- HMM profile = "fingerprint" of a domain family — scan a new sequence against it to detect remote homologs
- SUPERFAMILY covers structural space (slower divergence); PFAM covers sequence space (faster divergence) — complementary
- GO annotation enables pooling sparse domain-level data into statistically tractable functional categories

## Anti-patterns
- **Using a single domain database for cross-kingdom analysis**: SUPERFAMILY biased toward structurally characterized domains; PFAM biased toward well-studied taxa
- **Ignoring E-value threshold choice**: E ≤ 10⁻³ is lenient compared to default; justified here because false positives are unlikely to contain recognizable domains

## Reference Tables
| Tool | Version | Role in ADD Pipeline |
|------|---------|---------------------|
| HMMER | 3.0rc1 | HMM scanning for domain annotation |
| SUPERFAMILY | 1.75 | SCOP-based domain HMM database |
| PFAM | 26.0 (33,672 models) | Sequence-based domain HMM database |
| AUGUSTUS | multiple | Gene prediction (trained) |
| GENSCAN | — | Gene prediction (untrained baseline) |

## Key Takeaways
1. Viterbi + profile HMM is the shared mathematical core of gene prediction and domain annotation
2. SUPERFAMILY better for protists; PFAM better for metazoa/plants — both needed for eukaryote-wide study
3. E-value threshold of 10⁻³ appropriate given ORF annotation context (false ORFs rarely match domain HMMs)
4. GO mapping transforms sparse individual domain counts into pooled functional categories with statistical power
5. CpG islands serve as pedagogical example for Markov chain / HMM reasoning

## Connects To
- **Ch5**: AUGUSTUS/GENSCAN use HMM-based gene finding
- **Ch6**: HMMER applied to gene prediction output for domain annotation
- **Ch8**: GO pooling applied to overcome sparse domain co-occurrence data
