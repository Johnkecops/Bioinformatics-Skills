# Glossary — Evolutionary Analysis of Protein Domain Distribution in Eukaryotes

**ADD (Arli's Domain Distribution) Pipeline** — Custom bioinformatics pipeline using de novo gene prediction (AUGUSTUS) + HMM domain annotation (PFAM/SUPERFAMILY) + GO pooling for unbiased cross-species domain distribution analysis (Ch1, Ch4–8)

**Ascertainment bias** — Systematic over/underrepresentation of domains due to differences in annotation effort between model and non-model organisms (Ch4)

**AUGUSTUS** — Trainable ab initio gene predictor; uses HMMs; produces non-overlapping ORFs; preferred tool in ADD pipeline (Ch5)

**Avoidance** — Statistically significant tendency for two or more domains NOT to co-occur in the same protein (Ch7)

**bedtools** — Software to verify non-overlapping predictions and compute gene set overlaps (Ch5, Ch6)

**Central dogma** — DNA → mRNA → protein; splicing is the step that creates domain annotation problems (Ch2)

**Chromatin Regulator (CR)** — Protein domain class that organizes DNA via histones; one of two regulatory classes under study (Ch2)

**Chromodomain (SUPERFAMILY ID 54160)** — CR domain incorrectly classified as TF in SCOP; concrete annotation error example (Ch4)

**Co-occurrence** — Statistically significant tendency for two or more domains to appear together in the same protein (Ch7)

**CpG island** — GC-rich genomic region marking gene start; used as HMM teaching example (Ch3)

**De novo gene prediction** — Gene annotation from sequence without relying on existing transcript databases; core of ADD pipeline (Ch1, Ch5)

**Domain avoidance** — See Avoidance (Ch7)

**E-value threshold** — Statistical significance cutoff; E ≤ 10⁻³ used in ADD pipeline for HMMER searches (Ch3, Ch6)

**Exon** — Nucleic acid sequence retained in mature mRNA after splicing (Ch2)

**Expectation Method Count** — Expected co-occurrence = (count_A × count_B) / total_proteins; compared to observed count (Ch7)

**GENSCAN** — Untrained general-purpose gene predictor; used as baseline in ADD pipeline; fails for unusual genome architectures (Ch5)

**Gene Ontology (GO)** — Controlled vocabulary for gene/protein function; used to pool domain models into functional categories (Ch3, Ch8)

**HMMER** — Profile HMM search software; version 3.0rc1 used in ADD pipeline (Ch3, Ch6)

**Hidden Markov Model (HMM)** — Probabilistic model where states are hidden but outputs are observed; underlies both gene prediction and domain annotation (Ch3)

**InterPro2GO** — Mapping from Pfam domain IDs to GO terms; used for GO pooling in ADD pipeline (Ch3, Ch8)

**KRAB-ZNF pair** — Vertebrate-specific domain combination; co-occurrence significant only in human among tested species (Ch7)

**Kinetoplastids** — Protozoan group (Leishmania, Trypanosoma) with polycistronic mRNAs and trans-splicing; requires special gene prediction handling (Ch2, Ch5)

**Markov Chain** — Simplest probabilistic model; next state depends only on current state (memoryless) (Ch3)

**Non-overlapping ORF** — Open Reading Frame predicted without isoform redundancy; prevents domain double-counting; required by ADD pipeline (Ch5)

**PFAM** — Sequence-based HMM domain database; version 26.0 with 33,672 models; better for multicellular organisms (Ch3, Ch6)

**Polycistronic mRNA** — Single mRNA encoding multiple proteins; found in kinetoplastids; causes gene prediction overcounting (Ch2)

**Profile HMM** — HMM trained on multiple sequence alignment; encodes position-specific amino acid probabilities for a domain family (Ch3)

**RefSeq** — NCBI reference sequence database; used as ADD pipeline validation baseline; release 53 (Ch4, Ch5, Ch6)

**Scale-free network** — Network topology where few nodes have many connections (power law); domain combination networks follow this topology (Ch7)

**SCOP** — Structural Classification of Proteins; hierarchical: Class → Fold → Superfamily → Family; basis of SUPERFAMILY database (Ch3)

**SDFO (Structural Domain Functional Ontology)** — SUPERFAMILY v1.75 functional annotation layer mapping domain IDs to phenotypic annotations (Ch8)

**SUPER script** — Earlier pipeline by Prohaska et al. using existing gene/domain annotation; precursor to ADD pipeline (Ch9)

**SUPERFAMILY** — SCOP-based structural HMM domain database; version 1.75 with 9,821 HMMs; better for protists (Ch3, Ch6)

**Trans-splicing** — Exon joining from separate transcripts (kinetoplastids); disrupts standard gene prediction (Ch2)

**Transcription Factor (TF)** — Protein domain class that binds DNA regulatory regions; one of two regulatory classes under study (Ch2)

**Viterbi Algorithm** — Dynamic programming to find the most probable hidden state path through an observed sequence; used in gene prediction and domain annotation (Ch3)

**Zinc Finger (ZNF) domain** — Most abundant TF domain class; hub in domain co-occurrence networks; KRAB-ZNF co-occurrence is vertebrate-specific (Ch7)
