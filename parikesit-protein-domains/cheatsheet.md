# Cheatsheet — ADD Pipeline Quick Reference

## ADD Pipeline Stages
| Stage | Tool | Version | Key Parameter |
|-------|------|---------|--------------|
| Gene prediction | AUGUSTUS (online) | — | Non-overlapping ORFs only |
| Gene prediction (baseline) | GENSCAN | — | 500 kb chromosome fragments |
| Overlap verification | bedtools | — | No overlapping sequences |
| Domain annotation | HMMER | 3.0rc1 | E ≤ 10⁻³ |
| Domain DB (protists) | SUPERFAMILY | 1.75 (9,821 HMMs) | — |
| Domain DB (multicellular) | PFAM | 26.0 (33,672 models) | — |
| Functional pooling | GO / InterPro2GO + SDFO | — | 7 functional groups |
| Baseline | RefSeq | Release 53 | Validation only |

## Domain Database Selection
| Organism Type | Preferred DB | Notes |
|--------------|-------------|-------|
| Protists (Trypanosoma, Leishmania, Giardia, Plasmodium, Dictyostelium, Tetrahymena) | SUPERFAMILY | PFAM undercounts |
| Plants, metazoa, fungi | PFAM | PFAM better coverage |
| Cross-kingdom | Both + GO pooling | Use 7 functional groups |

## Co-occurrence Formula
```
Expected(A,B) = (count_A × count_B) / total_proteins
Co-occurrence:  Observed >> Expected (statistically significant)
Avoidance:      Observed << Expected (statistically significant)
```

## AUGUSTUS Training Decision Tree
```
Species has AUGUSTUS default training set?
  YES → Use directly
  NO  → Download cDNA from GenBank
         Remove redundancies (PERL)
         Clean FASTA headers
         Train online (preferred) or offline (≤1 day)
         Use online model for final analysis
```

## 18 Study Species (Phylogenetic Spread)
- Diplomonada: Giardia lamblia
- Parabasalia: Trichomonas vaginalis  
- Kinetoplastida: Trypanosoma brucei, Leishmania major
- Heterolobosea: Naegleria gruberi
- Alveolata: Plasmodium falciparum, Tetrahymena thermophila
- Stramenopiles: Thalassiosira pseudonana, Phytophthora ramorum
- Green algae: Chlamydomonas reinhardtii
- Land plants: Arabidopsis thaliana, Oryza sativa
- Amoebozoa: Dictyostelium discoideum
- Fungi: Aspergillus niger, Schizosaccharomyces pombe
- Metazoa: C. elegans, Drosophila melanogaster, Homo sapiens

## Key Findings Summary
| Finding | Evidence |
|---------|---------|
| Existing annotations biased | Human vs. chimp 2x discrepancy; human vs. dolphin divergence |
| GENSCAN insufficient | 118,894 human genes predicted (biologically implausible) |
| AUGUSTUS better | 33,507 human genes — close to RefSeq 36,073 |
| SUPERFAMILY > PFAM for protists | Confirmed for 6 protist species |
| PFAM > SUPERFAMILY for multicellular | Confirmed for plants + metazoa |
| TF and CR positively correlated | Across all eukaryotes |
| Avoidance in complex organisms | Strong signal in plants/metazoa with large gene families |
| No universal domain rules | Strong lineage-specific variation |
| KRAB-ZNF co-occurrence | Vertebrate-specific; significant only in human |
