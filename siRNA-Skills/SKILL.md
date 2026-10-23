---
name: sirna-computational-design-pipeline-universal
version: "2.0"
author: "Dr. Arli Aditya Parikesit"
affiliation: "Department of Bioinformatics, i3L University, Jakarta, Indonesia"
created: "2026-04-20"
updated: "2026-04-20"
reference: "Parikesit, Ansori & Kharisma (2022). Indonesian Journal of Chemistry, 22(5), 1163–1176. DOI: 10.22146/ijc.68415"
description: >
  Universal end-to-end computational pipeline for siRNA design and RNA-RNA molecular
  docking applicable to any target gene in any organism (viral, bacterial, fungal,
  plant, animal, or human). Covers sequence retrieval, MSA, phylogenetics, siRNA
  design, 2D/3D RNA structure prediction, molecular docking, and chemical interaction
  profiling. Originally validated against SARS-CoV-2 Spike glycoprotein mRNA;
  generalised for broad application across pathogens, disease genes, and functional
  genomics targets.
tags:
  - siRNA
  - RNA-RNA docking
  - structural bioinformatics
  - transcriptomics
  - RNAi therapeutics
  - ViennaRNA
  - HNADOCK
  - RNAxs
  - iFoldRNA
  - MolProbity
  - PLIP
  - universal pipeline
  - gene silencing
  - mRNA targeting
keywords:
  - small interfering RNA
  - mRNA silencing
  - molecular simulation
  - RNAi therapeutics
  - multiple sequence alignment
  - phylogenetic tree
  - RNA secondary structure
  - RNA tertiary structure
  - molecular docking
  - chemical interaction profiling
  - any organism
  - pathogen
  - disease gene
tools:
  - NCBI Databases (Virus / Nucleotide / Gene)
  - ClustalX
  - MAFFT (alternative to ClustalX)
  - Jalview
  - RNAxs
  - RNAalifold
  - RNAfold
  - Barriers Server
  - iFoldRNA v2
  - MolProbity
  - AVOGADRO
  - HNADOCK
  - IntaRNA
  - PLIP
  - UCSF Chimera
pipeline_steps: 14
language: "Python / Shell (post-processing); web servers for core analysis"
organism: "Any — viral, bacterial, fungal, plant, animal, or human"
applicability:
  - RNA viruses (coronaviruses, influenza, HIV, dengue, MERS, Ebola, etc.)
  - DNA viruses with RNA intermediates
  - Bacterial pathogens with non-coding RNA targets
  - Cancer driver genes (oncogenes, fusion transcripts)
  - Plant pathogens (fungal, oomycete, viral)
  - Parasite targets (Plasmodium, Leishmania, etc.)
  - Human disease genes (gain-of-function mutations)
  - Aquaculture pathogens and fish growth genes
---

# SKILL.md — Universal Computational siRNA Design Pipeline

> **Validated reference**: Parikesit, Ansori & Kharisma (2022). *Indonesian Journal of Chemistry*, 22(5), 1163–1176.
> DOI: [10.22146/ijc.68415](https://doi.org/10.22146/ijc.68415)
>
> This pipeline was originally developed for SARS-CoV-2 Spike glycoprotein mRNA silencing. Version 2.0 generalises every step for application to **any target gene in any organism**. SARS-CoV-2 values are retained throughout as concrete worked examples.

---

## Overview

This SKILL.md documents the complete end-to-end computational pipeline for **siRNA design and RNA-RNA molecular docking** applicable to any target gene across all domains of life. The pipeline combines transcriptomics-based approaches with structural bioinformatics to design siRNA candidates capable of silencing a chosen mRNA before ribosomal translation.

**Universal biological goal**: Identify a conserved, accessible region within a target gene's mRNA, design a complementary 19-nt siRNA guide strand, and computationally validate the siRNA-mRNA complex stability through structure prediction, docking, and chemical interaction analysis.

**Methodological paradigm**: RNA interference (RNAi)-based gene silencing — a transcriptomics-driven therapeutic or functional genomics strategy applicable to any organism where RNAi machinery exists or can be delivered.

**Scope of applicability**:
- Viral RNA genomes (positive-sense, negative-sense, segmented)
- Bacterial non-coding RNA or virulence gene mRNA targets
- Oncogenes and fusion transcripts in cancer
- Parasite-specific transcripts
- Plant pathogen effector mRNAs
- Gain-of-function disease alleles in human genetics
- Aquaculture pathogens and fish production genes

---

## Pipeline Architecture

The full pipeline proceeds in **14 consecutive steps**. Each must be completed in order — outputs from each step feed directly into the next.

```
1. Target Gene Selection & Sequence Retrieval
         ↓
2. Multiple Sequence Alignment (MSA)
         ↓
3. Phylogenetic Tree Construction
         ↓
4. siRNA Design from Conserved Region (RNAxs)
         ↓
5. MSA Visualization & siRNA Target Localization (Jalview)
         ↓
6. Conserved mRNA 2D Structure Prediction (RNAalifold)
         ↓
7. Individual 2D Structure Prediction — siRNA & mRNA (RNAfold)
         ↓
8. 2D Structural Diversity Analysis (Barriers Server)
         ↓
9. 3D Structure De Novo Modeling — siRNA & mRNA (iFoldRNA)
         ↓
10. 3D Structure Validation (MolProbity)
         ↓
11. Energy Protonation & Minimization (AVOGADRO)
         ↓
12. RNA-RNA Molecular Docking (HNADOCK)
         ↓
13. Chemical Interaction Prediction (IntaRNA)
         ↓
14. 3D Chemical Interaction Profiling (PLIP) + Visualization (UCSF Chimera)
```

---

## Step-by-Step Pipeline Details

### Step 1 — Target Gene Selection & Sequence Retrieval

**Tools**:
- [NCBI Virus](https://www.ncbi.nlm.nih.gov/labs/virus/) — for viral genomes
- [NCBI Nucleotide](https://www.ncbi.nlm.nih.gov/nuccore/) — for all organism types
- [NCBI Gene](https://www.ncbi.nlm.nih.gov/gene/) — for annotated gene records
- [Ensembl](https://www.ensembl.org/) — for eukaryotic genomes
- [UniProt](https://www.uniprot.org/) — for protein-anchored reverse lookup

**Output format**: GenBank / FASTA nucleotide sequences

**General filtering criteria**:

| Parameter              | General Guidance                                              |
|------------------------|---------------------------------------------------------------|
| Target organism taxon  | Specify NCBI TaxID of pathogen or organism of interest        |
| Sequence type          | mRNA / CDS / partial gene sequences                          |
| Sequence length        | Select range appropriate to target gene length (e.g., 100–3000 bp) |
| Completeness           | Partial or complete depending on target region availability   |
| Geographic regions     | Maximise geographic diversity to capture natural variation    |
| Collection date range  | Include the most recent available sequences                   |
| Host (if applicable)   | Specify host TaxID when targeting host-pathogen systems       |
| Sequence type          | GenBank preferred for annotation metadata                     |

**Adapting per organism type**:

| Organism Class          | Recommended Database                   | Key Considerations                              |
|-------------------------|----------------------------------------|-------------------------------------------------|
| RNA viruses             | NCBI Virus                             | Include variant/lineage metadata (Pango, clade) |
| DNA viruses             | NCBI Nucleotide                        | Target mRNA transcripts, not genomic DNA         |
| Bacteria                | NCBI Nucleotide / RefSeq               | Target virulence genes or essential mRNAs        |
| Fungi / Parasites       | NCBI Nucleotide / FungiDB / TriTrypDB  | Check for organism-specific codon usage          |
| Plants                  | NCBI Nucleotide / TAIR / Phytozome     | Consider chloroplast vs. nuclear targets         |
| Human / Animal genes    | Ensembl / RefSeq / NCBI Gene           | Use isoform-specific CDS; avoid off-target regions |
| Aquaculture organisms   | NCBI Nucleotide / FishBase             | Non-model organisms may have sparse annotations  |

**Skill notes**:
- Download at least 20–50 sequences from diverse isolates, strains, or individuals to ensure robust conserved region identification
- Record all metadata (accession, geographic location, collection date, strain/variant classification) in a spreadsheet before proceeding
- For non-viral targets without a dedicated database, use NCBI Nucleotide with organism TaxID + gene name as search terms
- Variant metadata should be recorded for downstream phylogenetic interpretation

**SARS-CoV-2 worked example parameters**:

| Parameter              | Value used in reference study                |
|------------------------|----------------------------------------------|
| Virus taxon            | SARS-CoV-2 (TaxID: 2697049)                 |
| Sequence length        | 100–1000 bp                                  |
| Protein target         | Surface glycoprotein (S gene)                |
| Geographic regions     | Africa, Asia, South America                  |
| Collection date range  | Nov 16, 2020 – May 18, 2021                 |
| Host                   | Homo sapiens (TaxID: 9605)                   |

---

### Step 2 — Multiple Sequence Alignment (MSA)

**Primary tool**: [MAFFT](https://mafft.cbrc.jp/alignment/server/) (recommended for large datasets) or MUSCLE via NCBI Virus applet
**Annotation tool**: ClustalX (for parameter-controlled alignment and phylogeny preparation)

**ClustalX parameters** (validated in reference study; applicable broadly):

| Parameter                       | Value         | Notes for Adaptation                            |
|---------------------------------|---------------|-------------------------------------------------|
| Gap Opening                     | 15            | Increase to 20+ for highly divergent sequences  |
| Gap Extension                   | 6.66          | Lower for closely related sequences             |
| Delay Divergent Sequences (%)   | 30            | Raise if outlier sequences cause misalignment   |
| DNA Transition Weight           | 0.5           | Standard for most nucleotide alignments         |
| Use Negative Matrix             | Off           | Enable only for very divergent sequences        |
| Protein Weight Matrix           | Gonnet series | Use BLOSUM62 for protein-coding gene regions    |
| DNA Weight Matrix               | IUB           | Standard IUPAC ambiguity coding                 |

**Skill notes**:
- The MSA conserved region is extracted from the `.aln` output as plain text — this is the **critical input** for siRNA design in Step 4
- Verify that the conserved region spans a functionally important domain of the target gene (binding sites, catalytic residues, essential structural motifs)
- MAFFT is preferred over ClustalX for datasets > 50 sequences or when sequences are highly divergent; use the `--auto` strategy for unknown datasets
- For eukaryotic mRNA targets, use CDS sequences only (remove introns) to avoid spurious conserved intronic regions

---

### Step 3 — Phylogenetic Tree Construction

**Tool**: ClustalX built-in phylogeny module, or [IQ-TREE 2](http://www.iqtree.org/) (recommended for rigorous analysis)
**Output format**: Phylip tree format (`.ph`) or Newick format (`.nwk`)

**Parameters**:

| Parameter                      | Value for NJ (reference study) | Value for ML (IQ-TREE recommended) |
|--------------------------------|--------------------------------|------------------------------------|
| Algorithm                      | Bootstrap NJ                   | Maximum Likelihood (GTR+G model)   |
| Random seed                    | 111                            | Any fixed seed for reproducibility |
| Bootstrap trials               | 1000                           | 1000 ultrafast bootstrap (IQ-TREE) |
| Output format                  | Phylip tree                    | Newick (.nwk)                      |

**Skill notes**:
- Bootstrap value ≥ 1000 is mandatory for statistical confidence in topology
- The phylogenetic tree contextualises which clades, variants, or strains are most represented in the sequence dataset — this directly informs how broadly the conserved region applies
- For rapidly evolving pathogens (RNA viruses), expect geographic clustering; for human disease genes, expect low variation
- IQ-TREE with ModelFinder is the modern gold standard for ML phylogenetics when computational resources allow
- Identify and note any outlier sequences before proceeding to siRNA design — outliers may indicate sequencing errors or highly divergent strains

---

### Step 4 — siRNA Design from Conserved Region (RNAxs)

**Tool**: [RNAxs](http://rna.tbi.univie.ac.at/cgi-bin/RNAxs/RNAxs.cgi)
**Input**: Conserved region nucleotide sequence (RNA format, in FASTA) extracted from MSA (Step 2)

**Parameters**:

| Parameter                      | Value (reference study)                 | Adaptation Notes                                      |
|--------------------------------|-----------------------------------------|-------------------------------------------------------|
| 8nt Accessibility Threshold    | 0.01157                                 | Default; lower for highly structured targets          |
| 16nt Accessibility Threshold   | 0.001002                                | Default; adjust based on target GC content            |
| Self Folding Energy            | 0.9022                                  | Default                                               |
| Sequence Asymmetry             | 0.5                                     | Default                                               |
| Energy Asymmetry               | 0.4655                                  | Default                                               |
| Free End                       | 0.625                                   | Default                                               |
| Custom Sequence Rules          | `NNNNNNNNNNNNNNNNNNN` (19-mer)          | Canonical siRNA length; adjust to 21-mer if needed    |
| Max number of siRNAs returned  | 3                                       | Increase to 5–10 for broader candidate screening      |

**Interpreting RNAxs output**:

| Output field      | Meaning                                                                        |
|-------------------|--------------------------------------------------------------------------------|
| Rank              | Efficacy rank among all candidate positions (lower = better design score)      |
| Position          | Start nucleotide position of the target within the input sequence              |
| Target mRNA seq   | The mRNA sequence to be silenced (sense strand, RNA format)                    |
| siRNA sequence    | Antisense guide strand (reverse complement of target; will be loaded into RISC)|

**Skill notes**:
- RNAxs combines RNA accessibility (how open the target region is) with thermodynamic asymmetry criteria from the Schwarz efficacy rules
- The 19-nt canonical siRNA guide strand is the antisense complement of the target mRNA sequence
- Select the top-ranked siRNA whose target falls within the verified conserved region from Jalview (Step 5) — rank alone is insufficient without conservation confirmation
- Cross-check target sequence against the host transcriptome using BLAST to avoid off-target silencing in the host organism
- For human disease gene targets, always run an off-target screen against the human transcriptome (BLAST or Bowtie2)

**SARS-CoV-2 worked example output**:

| Indicator        | Value                       |
|------------------|-----------------------------|
| Rank             | 33                          |
| Position         | 187 (within conserved region) |
| Target mRNA seq  | `ACUUUCCUUUACAAUCAUA`       |
| siRNA sequence   | `UAUGAUUGUAAAGGAAAGU`       |

---

### Step 5 — MSA Visualization & siRNA Target Localization

**Tool**: [Jalview 2.11+](https://www.jalview.org/)
**Input**: `.aln` file from ClustalX / MAFFT MSA (Step 2)

**Purpose**: Visually confirm that the RNAxs-identified siRNA target sequence falls within a genuinely conserved MSA region across all collected sequences. The consensus logo at the bottom of Jalview provides position-specific information content scores.

**Skill notes**:
- Highlight the target sequence block in the alignment — conservation should be ≥ 90% at each position across all sequences
- The consensus logo (Shannon information content, bits) should be near maximum at target positions; low-information positions indicate polymorphic sites unsuitable for universal siRNA targeting
- Verify that the target region is free from insertion/deletion polymorphisms across all included isolates or strains
- If targeting a gene across multiple species (e.g., pan-coronavirus siRNA), conservation across species is more important than within-species variation
- Export annotated alignment figure for manuscript supplementary materials

---

### Step 6 — Conserved mRNA 2D Structure Prediction (RNAalifold)

**Tool**: [RNAalifold](http://rna.tbi.univie.ac.at/cgi-bin/RNAWebSuite/RNAalifold.cgi)
**Input**: Conserved region alignment (multiple sequences) from MSA (Step 2)

**Parameters**:

| Parameter                  | Value                                          |
|----------------------------|------------------------------------------------|
| Version                    | New RNAalifold with RIBOSUM scoring            |
| Fold algorithm             | Minimum Free Energy (MFE) + partition function |
| Isolated base pairs        | Avoid                                          |

**Interpreting MFE values**:

| MFE range (kcal/mol) | Structural interpretation                                              |
|----------------------|------------------------------------------------------------------------|
| 0.00 to −5.00        | Weakly structured or unstructured; highly accessible for siRNA binding |
| −5.00 to −15.00      | Moderately structured; siRNA can compete with self-structure            |
| < −15.00             | Highly stable fold; siRNA binding thermodynamically competitive         |

**Skill notes**:
- RNAalifold computes a consensus secondary structure incorporating covariation signals across aligned sequences — this is more biologically accurate than single-sequence prediction
- RIBOSUM scoring is the preferred substitution matrix for RNA covariation analysis
- Very stable structures (MFE < −15 kcal/mol) with large bulges or unusual topologies may represent transition-state conformations and do not preclude siRNA binding
- Compare the RNAalifold consensus structure with the individual RNAfold prediction (Step 7) — discrepancies indicate covariation-driven structural variation across strains

**SARS-CoV-2 worked example**: conserved mRNA MFE = **−18.62 kcal/mol**

---

### Step 7 — Individual 2D Structure Prediction (RNAfold)

**Tool**: [RNAfold](http://rna.tbi.univie.ac.at/cgi-bin/RNAWebSuite/RNAfold.cgi)
**Input**: Individual FASTA sequences of (1) the target mRNA region and (2) the designed siRNA

**Parameters**:

| Parameter             | Value                                      |
|-----------------------|--------------------------------------------|
| Fold algorithm        | MFE + partition function                   |
| Isolated base pairs   | Avoid                                      |
| Temperature           | 37°C (physiological; adjust for non-human hosts) |

**Interpreting results**:

| Molecule     | MFE interpretation                                                              |
|--------------|---------------------------------------------------------------------------------|
| Target mRNA  | MFE near 0 = structurally accessible (favourable for siRNA binding)            |
| siRNA        | MFE slightly negative = marginally stable stem; appropriate for RISC loading   |

**Skill notes**:
- The **Vienna dot-bracket notation** output from RNAfold is required as input for Steps 8 and 9 — save both the sequence and the dot-bracket string in a paired file
- For organisms with non-physiological temperatures (thermophilic bacteria, cold-water fish), adjust folding temperature accordingly
- The partition function output provides base pair probabilities — positions with probability > 0.9 are structurally constrained and should be avoided as siRNA targets
- For siRNA, a short partial stem is desirable (promotes asymmetric RISC loading) but excessive self-complementarity (strong hairpin) reduces efficacy

**SARS-CoV-2 worked example**:

| Molecule     | MFE (kcal/mol) | Interpretation                                     |
|--------------|----------------|----------------------------------------------------|
| Target mRNA  | 0.00           | Structurally flexible; accessible for siRNA binding |
| siRNA        | −0.06          | Marginally stable; appropriate for RISC loading     |

---

### Step 8 — 2D Structural Diversity Analysis (Barriers Server)

**Tool**: [Barriers Server (ViennaRNA Web Suite)](http://rna.tbi.univie.ac.at/cgi-bin/RNAWebSuite/barriers.cgi)
**Input**: Vienna dot-bracket 2D annotation from RNAfold (Step 7)

**Parameters**:

| Parameter                              | Value                          |
|----------------------------------------|--------------------------------|
| Maximal number of lowest local minima  | 50                             |
| Barrier height threshold               | > 0.1 kcal/mol                 |
| Isolated base pairs                    | Avoid                          |
| Energy parameter model                 | RNA Turner model               |
| Temperature                            | 37°C (adjust per organism)     |
| Energy decline on both sides of helix  | Yes                            |

**Interpreting results**:

| Result                              | Biological interpretation                                               |
|-------------------------------------|-------------------------------------------------------------------------|
| mRNA: singular conformation         | Stable, predictable target structure — favourable for siRNA binding     |
| siRNA: multiple conformations (≥ 3) | Conformational flexibility — supports RISC complex loading              |
| siRNA: single rigid conformation    | May impair RISC loading; consider redesigning the guide strand          |

**Skill notes**:
- The barriers server maps the RNA free energy landscape to reveal metastable conformational states
- Multiple siRNA conformations reflect the flexibility needed for asymmetric RISC incorporation
- mRNA structural singularity at the target site supports stable, reproducible siRNA binding
- The 2D landscape is a simplification — it prepares biological expectations for 3D modeling in Step 9

**SARS-CoV-2 worked example**: mRNA — singular structure; siRNA — 3 possible conformations

---

### Step 9 — 3D Structure De Novo Modeling (iFoldRNA)

**Tool**: [iFoldRNA v2](https://dokhlab.med.psu.edu/ifoldrna/)
**Input**: FASTA sequence + Vienna dot-bracket 2D structure from RNAfold (Step 7)

**Replica Exchange Molecular Dynamics (REMD) parameters**:

| Parameter                                    | Value (reference study) |
|----------------------------------------------|-------------------------|
| Simulation time (DMD units)                  | 20000                   |
| Replica 1 Temperature (DMD units)            | 0.200                   |
| Replica 2 Temperature (DMD units)            | 0.225                   |
| Replica 3 Temperature (DMD units)            | 0.250                   |
| Replica 4 Temperature (DMD units)            | 0.270                   |
| Replica 5 Temperature (DMD units)            | 0.300                   |
| Replica 6 Temperature (DMD units)            | 0.333                   |
| Replica 7 Temperature (DMD units)            | 0.367                   |
| Replica 8 Temperature (DMD units)            | 0.400                   |
| Replica Exchange Interval (DMD units)        | 1000                    |
| Heat Exchange Coefficient (Berendsen)        | 0.1                     |

**Skill notes**:
- iFoldRNA uses Discrete Molecular Dynamics (DMD) with replica exchange for enhanced conformational sampling — universally applicable to any RNA sequence
- 8 replicas spanning the 0.2–0.4 temperature range provides adequate sampling for RNAs up to ~100 nt; for longer RNAs, consider increasing simulation time
- **Output format**: PDB file — required as input for Steps 10 and 11
- For sequences > 100 nt, consider alternative 3D modeling tools: RoseTTAFold2NA, trRosettaRNA, or SimRNA
- The loose siRNA conformation (partially unbound strands) reflects biological readiness for RISC incorporation; compact mRNA loop conformation indicates target accessibility

**SARS-CoV-2 worked example**: mRNA — compact loop; siRNA — loose loop (partially unbound strands)

---

### Step 10 — 3D Structure Validation (MolProbity)

**Tool**: [MolProbity](http://molprobity.biochem.duke.edu/)
**Input**: PDB files from iFoldRNA (Step 9)

**Validation parameters assessed**:
- All-atom contacts (clashscore)
- Nucleic acid geometry (sugar puckers, bad bonds, bad angles)
- Additional validations (chiral volume outliers, water clashes)

**Universal quality decision thresholds**:

| Parameter                     | Accept (Green)  | Caution (Yellow) | Reject (Red)    |
|-------------------------------|-----------------|------------------|-----------------|
| Sugar pucker outliers         | 0%              | < 5%             | ≥ 5%            |
| Bad bonds                     | < 0.1%          | 0.1–5%           | ≥ 5%            |
| Bad angles                    | < 0.1%          | 0.1–5%           | ≥ 5%            |
| Clashscore percentile         | ≥ 50th          | 1–49th           | 0th (worst)     |

**Decision rule**: Models in the yellow (caution) zone are acceptable for docking provided deviation from the standard reference plot is < 10%. Document all metrics transparently regardless of outcome.

**SARS-CoV-2 worked example results**:

| Parameter              | siRNA model    | mRNA model     | Decision        |
|------------------------|----------------|----------------|-----------------|
| Clashscore             | 206.35         | 210.72         | Yellow (proceed)|
| Wrong sugar puckers    | 2 (10.53%)     | 0 (0.00%)      | Yellow          |
| Bad bonds              | 16/460 (3.48%) | 17/434 (3.92%) | Yellow          |
| Bad angles             | 37/713 (5.19%) | 25/668 (3.74%) | Yellow          |

**Skill notes**:
- De novo modeled structures from short RNA sequences routinely fall in the warning zone due to limited experimental constraint — this is expected behaviour, not a pipeline failure
- Energy minimization in Step 11 is mandatory when clashscores are elevated regardless of organism
- If models land in the red zone (> 10% deviation), rerun iFoldRNA with different random seeds or consider alternative 3D modeling tools

---

### Step 11 — Energy Protonation & Minimization (AVOGADRO)

**Tool**: [AVOGADRO molecular editor](https://avogadro.cc/)
**Input**: PDB files from iFoldRNA (Step 9), assessed in MolProbity (Step 10)

**Parameters**:

| Parameter              | Value                          | Notes for Adaptation                          |
|------------------------|--------------------------------|-----------------------------------------------|
| Hydrogen addition      | Add hydrogen (enabled)         | Always required regardless of target organism |
| Force field            | UFF (Universal Force Field)    | MMFF94 is an alternative for better accuracy  |
| Steps per update       | 4                              | Increase for larger RNA molecules             |
| Optimization algorithm | Steepest Descent               | Follow with Conjugate Gradient for final polish|

**Skill notes**:
- Hydrogen addition is mandatory before energy minimization — protonation state critically affects electrostatic interactions in RNA-RNA binding
- UFF is applicable to all RNA molecules regardless of organism origin
- Steepest descent efficiently removes severe clashes; conjugate gradient converges to a local energy minimum — use both in sequence for best results
- **Output**: Optimized PDB files — these are the direct inputs for HNADOCK (Step 12)
- Verify that bond lengths (P-O: ~1.6 Å; C-N: ~1.35 Å) and angles are within normal ranges post-minimization

---

### Step 12 — RNA-RNA Molecular Docking (HNADOCK)

**Tool**: [HNADOCK](http://huanglab.phys.hust.edu.cn/hnadock/)
**Input**: Optimized PDB files of both siRNA and target mRNA from AVOGADRO (Step 11)

**Parameters**:

| Parameter                          | Value                     | Notes for Adaptation                              |
|------------------------------------|---------------------------|---------------------------------------------------|
| Secondary structure prediction     | RNAfold                   | Use the same tool as Steps 6–7 for consistency    |
| RNA-RNA interaction method         | Ab initio                 | Preferred; requires no prior binding site knowledge |
| Refine top models with MD          | Yes (top 10 models)       | Always enable — improves complex geometry quality |

**Skill notes**:
- HNADOCK is specifically designed for nucleic acid–nucleic acid docking and handles RNA-RNA, RNA-DNA, and DNA-DNA interactions — it is universally applicable regardless of organism
- Ab initio docking does not require a known binding site, making it appropriate for all novel siRNA-mRNA pairs
- For targets where a binding site is known (e.g., known ribozyme active sites), use the template-based mode instead
- The top 10 complex models are each refined with extended MD simulations — select the model with the lowest HNADOCK energy score and best visual plausibility
- **Output**: PDB file of the siRNA-mRNA complex — required for Steps 13 and 14
- UCSF Chimera is recommended for visualization — HNADOCK's built-in visualizer lacks sufficient resolution for publication figures

---

### Step 13 — Chemical Interaction Prediction (IntaRNA)

**Tool**: [IntaRNA](http://rna.informatik.uni-freiburg.de/IntaRNA/Input.jsp)
**Input**: Vienna dot-bracket annotation + FASTA sequences of siRNA (query) and target mRNA (target)

**Parameters**:

| Parameter                          | Value                                 | Notes for Adaptation                                |
|------------------------------------|---------------------------------------|-----------------------------------------------------|
| Number of interactions per pair    | 1                                     | Increase to 3–5 for screening multiple candidates   |
| Suboptimal interaction overlap     | Overlap in query                      | Standard setting                                    |
| Lonely base pairs                  | None                                  | Prevents weak/artefactual terminal pairings         |
| GU at helix ends                   | Not allowed                           | Reduces false positives                             |
| Minimum seed base pairs            | 7                                     | Appropriate for 19-nt siRNA; lower to 5 for shorter |
| Seeds with GU ends                 | Ignored                               | Standard filter                                     |

**Skill notes**:
- IntaRNA uses a seed-extension model with RNA accessibility pre-computation — universally applicable to any RNA pair regardless of organism
- The output shows predicted hydrogen bonding patterns between siRNA guide strand and mRNA target in 2D
- **Known limitation**: IntaRNA reports H-bonds but not Van der Waals or hydrophobic/stacking interactions — use PLIP (Step 14) for a complete interaction profile
- A minimum seed of 7 base pairs is standard for 19-nt siRNA; for longer RNA therapeutics (e.g., antisense oligonucleotides), increase accordingly
- When targeting multiple organisms simultaneously, run IntaRNA separately for each representative sequence

---

### Step 14 — 3D Chemical Interaction Profiling (PLIP) + Visualization

**Tool**: [PLIP (Protein-Ligand Interaction Profiler)](https://plip-tool.biotec.tu-dresden.de/)
**Visualization**: [UCSF Chimera 1.15+](https://www.cgl.ucsf.edu/chimera/) or [ChimeraX](https://www.cgl.ucsf.edu/chimerax/)
**Input**: siRNA-mRNA complex PDB from HNADOCK (Step 12)

**PLIP configuration for RNA-RNA complexes**:

| Parameter                                    | Value                              |
|----------------------------------------------|------------------------------------|
| Macromolecule treatment                      | Nucleic acid as receptor           |
| Interaction detection scope                  | 1 model                            |
| Inter-chain interaction detection            | Detect (receptor vs. ligand chains)|

**Interaction types detected by PLIP**:

| Interaction type     | Biological significance                                                  |
|----------------------|--------------------------------------------------------------------------|
| Hydrogen bonds       | Primary determinant of base-pairing specificity and complex stability    |
| Metal interactions   | Divalent cations (Mg²⁺, Ca²⁺) stabilise RNA tertiary structure globally |
| π-stacking           | Aromatic base stacking — contributes significantly to helix stability    |
| Hydrophobic contacts | Minor contribution in RNA complexes; more relevant in RNA-protein docking|

**Skill notes**:
- PLIP was designed for protein-ligand complexes but is adapted here for nucleic acid interactions by treating one RNA chain as the "receptor" — applicable for any RNA-RNA system
- The presence of Mg²⁺ coordination at the siRNA-mRNA interface is expected for all RNA systems — Mg²⁺ is a universal cofactor for RNA folding and complex stability in vivo
- π-stacking between nucleobases is a major energetic contributor to complex stability beyond hydrogen bonding
- Traditional 2D interaction visualizers (LigPlot+, LeView) use protein-specific scoring functions and are **not compatible** with RNA-RNA complexes — always use PLIP for nucleic acid interaction profiling
- For UCSF Chimera visualization: use `Tools > Structure Analysis > FindHBond` and `Tools > Surface/Binding Analysis`; export at ≥ 300 DPI for publication

**SARS-CoV-2 worked example interactions**:

| Interaction type  | Description                                            |
|-------------------|--------------------------------------------------------|
| Hydrogen bonds    | 9 H-bonds at the siRNA-mRNA interface                  |
| Metal interaction | ATP–Mg²⁺ coordination at the binding interface        |
| π-stacking        | Resonance stacking between adjacent nucleobase rings   |

---

## Universal Findings Summary Template

When applying this pipeline to a new target, populate this summary table:

| Stage                          | Finding / Result                                              |
|--------------------------------|---------------------------------------------------------------|
| Target organism & gene         | [Organism name, TaxID, gene name, functional role]            |
| Sequence diversity             | [Number of sequences, variant/strain distribution]            |
| Phylogenetic structure         | [Clustering pattern, notable outliers]                        |
| siRNA candidate                | Target: `[mRNA sequence]`; siRNA: `[guide strand sequence]`  |
| Target mRNA 2D MFE             | [value] kcal/mol — [accessibility interpretation]             |
| siRNA 2D MFE                   | [value] kcal/mol — [RISC loading suitability]                 |
| Conserved mRNA MFE             | [value] kcal/mol — [structural stability interpretation]       |
| siRNA conformations (Barriers) | [number] conformations identified                             |
| 3D structure quality           | [Green / Yellow / Red] — [proceed / revise decision]          |
| Docking result                 | Complex formed / not formed; top model energy score           |
| Chemical interactions          | [# H-bonds] + [metal interactions] + [π-stacking] noted      |
| Off-target risk assessment     | BLAST screen result against host transcriptome                |
| Conclusion                     | [siRNA is / is not a viable candidate for wet-lab validation] |

**SARS-CoV-2 worked example values**:

| Stage                          | Finding                                                                      |
|--------------------------------|------------------------------------------------------------------------------|
| Target organism & gene         | SARS-CoV-2, Spike glycoprotein S gene — ACE2 receptor binding domain        |
| Sequence diversity             | 46 sequences; Delta variant (B.1.617.2) dominant in South Asian dataset     |
| Phylogenetic structure         | 3 clusters (Indian dominant × 2, Uzbek/Pakistani cluster); 1 outlier        |
| siRNA candidate                | Target: `ACUUUCCUUUACAAUCAUA`; siRNA: `UAUGAUUGUAAAGGAAAGU` (pos. 187)     |
| Target mRNA 2D MFE             | 0.00 kcal/mol — structurally accessible; favourable for siRNA binding        |
| siRNA 2D MFE                   | −0.06 kcal/mol — marginally stable; appropriate for RISC loading             |
| Conserved mRNA MFE             | −18.62 kcal/mol — thermodynamically stable conserved fold                   |
| siRNA conformations (Barriers) | 3 conformations identified                                                   |
| 3D structure quality           | Yellow (warning threshold) — proceeded with docking                          |
| Docking result                 | Complex formed successfully                                                  |
| Chemical interactions          | 9 H-bonds + ATP-Mg²⁺ metal interaction + π-stacking → stable complex        |
| Conclusion                     | siRNA is a viable COVID-19 therapeutic candidate for wet-lab validation      |

---

## Software & Web Server Reference Table

| Tool                     | Purpose                                    | URL / Access                                                        |
|--------------------------|--------------------------------------------|---------------------------------------------------------------------|
| NCBI Virus               | Sequence retrieval (viruses)               | https://www.ncbi.nlm.nih.gov/labs/virus/                           |
| NCBI Nucleotide          | Sequence retrieval (all organisms)         | https://www.ncbi.nlm.nih.gov/nuccore/                              |
| Ensembl                  | Eukaryotic genome annotation               | https://www.ensembl.org/                                            |
| MAFFT                    | MSA (large or divergent datasets)          | https://mafft.cbrc.jp/alignment/server/                            |
| ClustalX                 | MSA + phylogeny (desktop)                  | Desktop software                                                    |
| IQ-TREE 2                | Maximum likelihood phylogenetics           | http://www.iqtree.org/                                              |
| Jalview 2.11+            | MSA visualization                          | https://www.jalview.org/                                            |
| RNAxs                    | siRNA design from conserved sequence       | http://rna.tbi.univie.ac.at/cgi-bin/RNAxs/RNAxs.cgi               |
| RNAalifold               | Conserved structure (aligned input)        | http://rna.tbi.univie.ac.at/cgi-bin/RNAWebSuite/RNAalifold.cgi    |
| RNAfold                  | Individual 2D structure + MFE              | http://rna.tbi.univie.ac.at/cgi-bin/RNAWebSuite/RNAfold.cgi       |
| Barriers Server          | 2D structural energy landscape             | http://rna.tbi.univie.ac.at/cgi-bin/RNAWebSuite/barriers.cgi      |
| iFoldRNA v2              | 3D structure de novo modeling              | https://dokhlab.med.psu.edu/ifoldrna/                               |
| MolProbity               | 3D structure validation                    | http://molprobity.biochem.duke.edu/                                 |
| AVOGADRO                 | Energy minimization & protonation          | https://avogadro.cc/                                                |
| HNADOCK                  | RNA-RNA molecular docking                  | http://huanglab.phys.hust.edu.cn/hnadock/                           |
| IntaRNA                  | RNA-RNA interaction prediction (2D)        | http://rna.informatik.uni-freiburg.de/IntaRNA/Input.jsp            |
| PLIP                     | 3D chemical interaction profiling          | https://plip-tool.biotec.tu-dresden.de/                             |
| UCSF Chimera / ChimeraX  | 3D molecular visualization                 | https://www.cgl.ucsf.edu/chimera/ / https://www.cgl.ucsf.edu/chimerax/ |

---

## Universal Data Format Flow

```
[Database] (NCBI Virus / Nucleotide / Ensembl / etc.)
    → FASTA / GenBank sequences of target gene
         → MAFFT or ClustalX → .aln file + conserved region (plain text FASTA)
         → ClustalX / IQ-TREE → .ph / .nwk phylogenetic tree
Conserved region (FASTA) → RNAxs → candidate siRNA + target mRNA sequences
.aln file → Jalview → validated conserved region annotation + figure
Conserved region alignment → RNAalifold → consensus 2D structure (dot-bracket + MFE)
siRNA FASTA → RNAfold → siRNA dot-bracket + MFE
mRNA FASTA → RNAfold → mRNA dot-bracket + MFE
siRNA dot-bracket → Barriers Server → siRNA conformational landscape
mRNA dot-bracket → Barriers Server → mRNA conformational landscape
siRNA FASTA + dot-bracket → iFoldRNA → siRNA PDB (3D model)
mRNA FASTA + dot-bracket → iFoldRNA → mRNA PDB (3D model)
siRNA PDB → MolProbity → validation report (accept / revise)
mRNA PDB → MolProbity → validation report (accept / revise)
siRNA PDB → AVOGADRO → optimized siRNA PDB (protonated + energy-minimized)
mRNA PDB → AVOGADRO → optimized mRNA PDB (protonated + energy-minimized)
Optimized siRNA PDB + optimized mRNA PDB → HNADOCK → complex PDB
siRNA FASTA + dot-bracket + mRNA FASTA + dot-bracket → IntaRNA → H-bond map (2D)
Complex PDB → PLIP → full interaction report (H-bonds, metal, π-stacking)
Complex PDB → UCSF Chimera → publication-quality 3D figures
```

---

## Critical Implementation Notes (Universal)

**On reproducibility**: Fix all random seeds (e.g., phylogeny seed = 111) and document exact tool versions and access dates for all web servers. Tool updates can change numerical outputs — always note the version in your methods section.

**On off-target screening**: For any human-host siRNA application, BLAST the guide strand sequence against the host transcriptome before proceeding to wet-lab work. A single 6–7 nt match to an essential host gene is sufficient to cause toxicity. For pathogen-targeting siRNAs, verify specificity against the pathogen and absence of complementarity to the host.

**On 3D validation thresholds**: MolProbity warning-range results are normal for de novo modeled short RNAs. The pragmatic threshold is < 10% deviation from standard validation plots. Proceed with docking but report all metrics transparently. Red-zone results require remodeling before docking.

**On tool compatibility for interaction profiling**: LigPlot+ and LeView are incompatible with RNA-RNA complex visualization. Always use PLIP in RNA-as-receptor mode for nucleic acid interaction profiling.

**On Mg²⁺ universality**: Divalent cation coordination (Mg²⁺, Ca²⁺) at RNA-RNA interfaces is a universal feature of RNA biology, not specific to SARS-CoV-2. Retain metal ion coordinates in PDB files from iFoldRNA — removing them eliminates biologically critical stabilizing interactions.

**On temperature adjustment**: The default folding temperature is 37°C (human/mammalian physiology). For organisms with different physiological temperatures — thermophilic bacteria (65–80°C), cold-water fish (4–15°C), plants (25°C) — adjust the temperature parameter in RNAfold, RNAalifold, and Barriers Server accordingly.

**On sequence length limits**: iFoldRNA is optimised for RNAs ≤ 100 nt. For longer mRNA targets, consider modeling only the conserved target region (the ~30–50 nt window surrounding the siRNA binding site) rather than the full-length transcript.

---

## Wet-Lab Validation Pathway (Universal)

Computational results from this pipeline should always be validated experimentally. Adapt the following pathway to your organism and experimental system:

1. **siRNA synthesis**: Chemical synthesis of the 19-nt guide strand + passenger strand duplex
2. **Delivery system selection**: Lipid nanoparticles (LNP) for in vivo; transfection reagent (Lipofectamine, RNAiMAX) for cell culture; electroporation for hard-to-transfect cells; VIGS or spray for plants
3. **Cell / organism model**: Select appropriate infection model, cell line, or transgenic system
4. **RT-qPCR**: Quantify target gene mRNA knockdown efficiency (aim for ≥ 70% knockdown)
5. **Western blot / ELISA**: Confirm reduction in target protein expression
6. **Phenotypic assay**: Measure functional outcome (viral plaque reduction, cell viability, growth inhibition, etc.)
7. **Off-target toxicity screen**: Transcriptome-wide RNA-seq to detect unintended gene silencing
8. **In vivo validation** (if applicable): Animal model or organism challenge experiment

---

## Citation

If using this pipeline, please cite the original validated study:

> Parikesit, A.A., Ansori, A.N.M., & Kharisma, V.D. (2022). A Computational Design of siRNA in SARS-CoV-2 Spike Glycoprotein Gene and Its Binding Capability toward mRNA. *Indonesian Journal of Chemistry*, 22(5), 1163–1176. https://doi.org/10.22146/ijc.68415

---

*SKILL.md v2.0 — Generalised for universal application*
*Created: April 2026 | Updated: April 2026*
*Author: Dr. Arli Aditya Parikesit, i3L University, Jakarta*
*Original pipeline source: Parikesit, Ansori & Kharisma (2022), IJC*
