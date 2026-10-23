# Bioinformatics Skills

A living library of **agent skills** for computational biology.

This repository is not an application and does not ship a single pipeline you run from a `main.py`. It is a **deposit of research methods** written so that an AI coding agent (Claude Code, Grok, Cursor, Codex, Gemini CLI, and anything else that follows the [Agent Skills](https://agentskills.io/) layout) can load a validated workflow, follow it, and apply it to a new dataset or target.

Each skill is a folder of markdown: a `SKILL.md` file plus optional chapters, cheatsheets, and reference notes. The agent reads those files when the task matches. You do not compile them. You install them by putting them on disk where the agent looks, then asking it to do the work.

New skills can be deposited here at any time. The folders below are the current holdings, not the ceiling of the collection. A dissertation knowledge base, a teaching-lab protocol, an RNA-methods family, a disease-application pipeline, a teaching app for AI equations, and a PRD generator for health AI already sit side by side; the next deposit does not need to match any of them.

---

## What this collection is for

Bioinformatics work is full of procedures that are too long to retype every session and too specific to leave to a general model: gene-prediction choices for unusual genomes, an RNA-seq teaching lab (BLAST → Bowtie → TopHat → Cufflinks → edgeR → GSEA), siRNA design from a conserved mRNA window, all-atom RNA molecular dynamics, or a methylation-plus-classifier pipeline for a named disease. A skill captures one of those procedures once — tools, parameters, decision rules, anti-patterns, and a worked example — so the agent can reuse it instead of improvising.

Typical uses:

- Run a documented research pipeline on a new organism, gene, RNA sequence, or cohort
- Consult a knowledge base (dissertation chapter, lab protocol, cheatsheet) while designing an analysis
- Teach or re-run a course lab with the same commands and file formats
- Keep lab methods versioned next to the prompts that teach an agent how to execute them
- Share the same workflow across Claude Code, Grok, Cursor, or Codex without rewriting it

The collection is **additive**. Folders are independent. A docking skill, a metagenomics skill, a phylogenetics skill, or a database-access skill can sit beside the existing ones without changing how the library is installed. Method A below is written so that a new folder is discovered on the next skill reload; you do not edit this README in order for the agent to see it.

---

## Current holdings

| Folder | Skill name | What it encodes |
|--------|------------|-----------------|
| [`parikesit-protein-domains/`](parikesit-protein-domains/) | `parikesit-protein-domains` | Knowledge base from Dr. Arli Aditya Parikesit's PhD dissertation, *Evolutionary Analysis of the Protein Domain Distribution in Eukaryotes* (University of Leipzig, 2012). ADD pipeline, AUGUSTUS vs GENSCAN, HMMER/Pfam/SUPERFAMILY annotation, domain co-occurrence and avoidance. |
| [`parikesit-transcriptomics-protocol/`](parikesit-transcriptomics-protocol/) | `parikesit-transcriptomics-protocol` | Knowledge base from *Transcriptomics Computational Protocol* (BI021 lab, i3L Press, 2022) by Parikesit & Agustriawan. Six sessions: Linux + BLAST+, Bowtie/Bowtie2, TopHat spliced alignment, Cufflinks/FPKM, RNA-seq CPM filtering in R (edgeR), GSEA. |
| [`siRNA-Skills/`](siRNA-Skills/) | `sirna-computational-design-pipeline-universal` | End-to-end computational siRNA design and RNA–RNA docking for any target gene in any organism (14 steps: retrieval → MSA → phylogeny → RNAxs → 2D/3D structure → HNADOCK → PLIP). Validated on SARS-CoV-2 Spike mRNA; generalised beyond that case. |
| [`siRNA-Skills/SKILL_openmm_sirna_md.md`](siRNA-Skills/SKILL_openmm_sirna_md.md) | `openmm-sirna-md` | All-atom NVT molecular dynamics of an siRNA guide strand or short ssRNA in OpenMM (AMBER14 + GBn2 implicit solvent): fiber geometry, pre-relaxation, minimisation, production, backbone RMSD. |
| [`alzheimer-epigenetics-ai-pipeline/`](alzheimer-epigenetics-ai-pipeline/) | `alzheimer-epigenetics-ai-pipeline` | Integrated AD detection pipeline: DMR analysis of blood methylation (GSE244352) plus MLP classification of brain microarray (GSE48350, GSE11882) on APP, PSEN1, PSEN2, APOE, MAPT, and TREM2. Mey et al. (2025). |
| [`structure-based-drug-discovery-with-ANM/`](structure-based-drug-discovery-with-ANM/) | `structure-based-drug-discovery-with-ANM` | Structure-based screening against a PDB target: receptor and ligand prep, AutoDock Vina docking, OpenMM MD, ADMET descriptors, Anisotropic Network Model (ProDy) pocket dynamics, and MCDA ranking of hits. Full source code is embedded in the skill's Appendix A. |
| [`nietzschean-ai-equations/`](nietzschean-ai-equations/) | `nietzschean-ai-equations` | Builds and extends the "Beyond Good and Computation" Streamlit teaching app. Ten AI/optimisation equations (softmax, backprop, attention, KL, cross-entropy, linear regression, gradient descent, linear programming, ADAM, MLE), each with runnable NumPy/PyTorch/SciPy code, an interactive demo, a bioinformatics use case, and a Nietzschean framing. Lists the app's known defects to fix or disclose. |
| [`prd-ai-life-sciences/`](prd-ai-life-sciences/) | `prd-ai-life-sciences` | Product Requirements Document for AI/ML products in life sciences and health (clinical AI / SaMD, drug-discovery AI, omics platforms, digital health, LLM health tools). Three modes: blank 21-section .docx template, populated draft for a named product, or gap review of an existing PRD. Bundles a Node generator script and a per-section checklist. |

These are **current deposits**, not a closed catalogue. Drop another folder at the root (or inside a family directory) when a new method is ready. The transcriptomics protocol, the Alzheimer pipeline, the equations app, and the PRD generator all arrived after the first holdings; none required a new install mechanism. The next skill will be the same.

---

## Repository layout

```
Bioinformatics-Skills/
├── README.md                            ← you are here
├── parikesit-protein-domains/           ← dissertation knowledge base
│   ├── SKILL.md
│   ├── chapters/
│   ├── cheatsheet.md
│   ├── glossary.md
│   └── patterns.md
├── parikesit-transcriptomics-protocol/  ← teaching-lab protocol
│   ├── SKILL.md
│   ├── chapters/
│   ├── cheatsheet.md
│   ├── glossary.md
│   └── patterns.md
├── siRNA-Skills/                        ← family folder (related RNA methods)
│   ├── SKILL.md                         ← universal siRNA design pipeline
│   ├── SKILL_openmm_sirna_md.md         ← OpenMM MD companion skill
│   └── references/                      ← Parikesit, Ansori & Kharisma (2022) source paper (PDF)
├── alzheimer-epigenetics-ai-pipeline/   ← disease-application pipeline
│   └── SKILL.md
├── structure-based-drug-discovery-with-ANM/  ← docking + MD + ANM pipeline
│   └── SKILL.md
├── nietzschean-ai-equations/            ← teaching app (Streamlit)
│   └── SKILL.md
└── prd-ai-life-sciences/                ← document generator (health-AI PRD)
    ├── SKILL.md
    ├── references/section_guide.md
    └── scripts/build_prd_template.js
```

**Convention for new deposits:** prefer one directory per skill, with `SKILL.md` at the top of that directory. Related skills may share a family folder (as `siRNA-Skills/` does) when they form a single research line. Supporting files — chapters, scripts, reference tables — live next to `SKILL.md`, not at the repository root.

A skill directory is valid when it contains YAML frontmatter with at least `name` and `description`, followed by the procedure the agent should follow.

---

## Requirements

- An AI coding agent that reads Agent Skills (`SKILL.md` files). No skill runtime is required.
- Git, to clone or update the library.
- Optional, per skill: the scientific tools named inside that skill (Python packages, web servers, desktop programs). Installing the library does **not** install AUGUSTUS, BLAST+, Bowtie, TopHat, OpenMM, TensorFlow, RNAxs, or HMMER. Those are pulled in only when you actually run that workflow.

Python 3.10+ covers the OpenMM, Alzheimer, and equations-app skills. The PRD skill needs Node.js with the `docx` npm package. The transcriptomics protocol also needs R (edgeR) and the classic NGS toolchain. The protein-domain and siRNA-design skills mix local tools with public web servers; see each `SKILL.md` for the list.

---

## Installation

Skills are plain markdown. There is no `pip install`, `npm install`, or build step for the library itself.

### 1. Get the repository

```bash
git clone <this-repository-url> Bioinformatics-Skills
cd Bioinformatics-Skills
```

If you already have the folder (this workspace), skip the clone and use the path you are in.

### 2. Make the agent see the skills

Pick one of the methods below. Method A is the least work if you want the **whole collection**, including skills added later. Method B is better if you only want selected skills on every project.

#### Method A — Point the agent at this folder (recommended for a growing library)

The agent walks the tree, finds every `SKILL.md`, and picks up new deposits automatically the next time it starts (or when skills reload from disk).

**Grok** — add the library path in `~/.grok/config.toml`:

```toml
[skills]
paths = [
  "/absolute/path/to/Bioinformatics-Skills"
]
```

**Claude Code / Grok compatibility** — symlink or copy the repo into a scanned skills root, or add it as a project skill path:

```bash
# User-wide (available in every project)
ln -s /absolute/path/to/Bioinformatics-Skills ~/.claude/skills/bioinformatics-skills

# Or, for Grok user skills
ln -s /absolute/path/to/Bioinformatics-Skills ~/.grok/skills/bioinformatics-skills
```

**Project-only** — from a research project that should use these skills:

```bash
mkdir -p .claude/skills .grok/skills
ln -s /absolute/path/to/Bioinformatics-Skills .claude/skills/bioinformatics-skills
```

Grok also reads `~/.claude/skills/` by default, so a Claude Code install is usually enough for both.

#### Method B — Install individual skills into the standard directories

Copy (or symlink) each skill folder into the directory your agent scans.

| Tool | User-wide directory | Project directory |
|------|---------------------|-------------------|
| Claude Code | `~/.claude/skills/` | `.claude/skills/` |
| Grok | `~/.grok/skills/` | `.grok/skills/` |
| Cursor | `~/.cursor/skills/` | `.cursor/skills/` |
| Codex | `~/.codex/skills/` | `.codex/skills/` |
| Gemini CLI | `~/.gemini/skills/` | `.gemini/skills/` |

Example for Claude Code:

```bash
SKILLS_HOME="$HOME/.claude/skills"
REPO="/absolute/path/to/Bioinformatics-Skills"

# Protein-domain knowledge base (already a standard skill folder)
ln -s "$REPO/parikesit-protein-domains" "$SKILLS_HOME/parikesit-protein-domains"

# Transcriptomics teaching-lab protocol
ln -s "$REPO/parikesit-transcriptomics-protocol" \
  "$SKILLS_HOME/parikesit-transcriptomics-protocol"

# Alzheimer epigenetics + MLP pipeline
ln -s "$REPO/alzheimer-epigenetics-ai-pipeline" \
  "$SKILLS_HOME/alzheimer-epigenetics-ai-pipeline"

# Universal siRNA design pipeline
mkdir -p "$SKILLS_HOME/sirna-computational-design-pipeline-universal"
ln -s "$REPO/siRNA-Skills/SKILL.md" \
  "$SKILLS_HOME/sirna-computational-design-pipeline-universal/SKILL.md"

# OpenMM RNA MD companion (file is not named SKILL.md in the family folder)
mkdir -p "$SKILLS_HOME/openmm-sirna-md"
ln -s "$REPO/siRNA-Skills/SKILL_openmm_sirna_md.md" \
  "$SKILLS_HOME/openmm-sirna-md/SKILL.md"

# Structure-based drug discovery with ANM
ln -s "$REPO/structure-based-drug-discovery-with-ANM" \
  "$SKILLS_HOME/structure-based-drug-discovery-with-ANM"

# Nietzschean AI equations app
ln -s "$REPO/nietzschean-ai-equations" "$SKILLS_HOME/nietzschean-ai-equations"

# Health-AI PRD generator
ln -s "$REPO/prd-ai-life-sciences" "$SKILLS_HOME/prd-ai-life-sciences"
```

Symlinks keep a single source of truth in this repository. Copies work too, but they drift when the deposit is updated.

#### Method C — Skills CLI (if you publish this repo on GitHub)

Once the repository is on GitHub, agents that use the Skills CLI can install from there:

```bash
npx skills add <owner>/<repo>
```

Until then, use Method A or B.

### 3. Confirm the agent loaded them

In the agent session:

- Claude Code: `/skills` and look for the skill names
- Grok: `/skills` or the slash menu
- Or just ask: “Which bioinformatics skills do you have loaded?”

The skill should appear within a few seconds of the files landing on disk; most agents reload skills when those files change.

### 4. Optional — scientific software for a given skill

Install tool dependencies **only for the skill you are about to run**.

OpenMM RNA MD:

```bash
pip install openmm pdbfixer numpy matplotlib
# or: conda install -c conda-forge openmm pdbfixer
```

Protein-domain ADD pipeline (when executing it, not when only consulting the knowledge base): AUGUSTUS, HMMER3, bedtools, Pfam / SUPERFAMILY HMM libraries.

Transcriptomics teaching lab (when running the BI021 protocol, not when only consulting the chapters): BLAST+, Bowtie / Bowtie2, TopHat, Cufflinks, samtools, R with edgeR, GSEA desktop. Modern substitutes (HISAT2, StringTie, STAR, featureCounts, fgsea) are noted inside that skill.

siRNA design pipeline: NCBI access plus the web servers listed in that skill (MAFFT, RNAxs, RNAfold, iFoldRNA, HNADOCK, PLIP, and others). Many steps are browser-based; no single conda environment covers the whole 14-step path.

Alzheimer epigenetics + MLP pipeline:

```bash
pip install streamlit tensorflow scikit-learn pandas numpy plotly matplotlib seaborn scipy requests GEOparse
```

Structure-based drug discovery with ANM: Python 3.10+, rdkit, pandas, numpy, matplotlib, prody, openmm, AutoDock Vina and ADFR `prepare_ligand4.py`; AmberTools for MM-PBSA.

Nietzschean AI equations app: Streamlit, NumPy, Matplotlib, SciPy, and PyTorch for the backprop/ADAM snippets. The skill warns that the app's pinned versions (torch 2.0.1, streamlit 1.28.1) may not install on Python 3.12+; check before pinning.

Health-AI PRD generator:

```bash
npm install docx
node prd-ai-life-sciences/scripts/build_prd_template.js PRD.docx --product "Name" --org "Org"
```

---

## Using a skill

You do not have to name the file. Describe the task in ordinary language; the `description` field in the frontmatter is what the agent matches against.

Examples:

- “Apply the ADD pipeline logic to compare domain co-occurrence in these two protist genomes.”
- “Walk the BI021 transcriptomics lab: index with Bowtie2, map with TopHat, assemble with Cufflinks, then CPM-filter in edgeR.”
- “Design siRNA against gene X in organism Y and walk the 14-step pipeline.”
- “Run all-atom MD on this 19-nt guide strand with AMBER14 and GBn2.”
- “Run DMR analysis and MLP classification for Alzheimer’s on APP, PSEN1, PSEN2, APOE, MAPT, and TREM2.”
- “Add a KL-divergence page to the Beyond Good and Computation app, with a transcriptomics example.”
- “Write a PRD for our TB drug-resistance variant classifier.” / “Review this PRD for missing sections.”

You can also invoke a skill by name as a slash command when the agent supports it (`/parikesit-protein-domains`, `/openmm-sirna-md`, and so on).

Read the skill’s own `SKILL.md` for parameters, worked examples, and what not to do. The README only tells you how to install the library; the skill tells you how to do the science.

---

## Depositing an additional skill

This repository is meant to grow. A new method belongs here when it is a repeatable bioinformatics (or neighbouring life-science) procedure that you want an agent to follow the same way twice.

1. **Create a directory** at the repository root, or inside a family folder if it clearly belongs with an existing line of work (`siRNA-Skills/`, a future `docking/`, `phylogenetics/`, …).

2. **Name it** with lowercase letters, digits, and hyphens (`rna-seq-de-analysis`, not `RNA Seq DE`).

3. **Write `SKILL.md`** with YAML frontmatter:

   ```markdown
   ---
   name: my-new-skill
   description: >
     One or two sentences on what the skill does, plus the phrases that
     should trigger it. Use when the user asks to …
   ---

   # Title

   Procedure, decision rules, inputs, outputs, and anti-patterns.
   ```

   The `description` field is the discovery mechanism. Put trigger phrases in it.

4. **Add supporting files** only when they earn their keep: `chapters/`, `references/`, `scripts/`, a cheatsheet. Do not dump unrelated notes at the repo root.

5. **Prefer one `SKILL.md` per directory.** If a companion procedure is large enough to stand alone (as OpenMM MD does next to siRNA design), give it its own folder named after the skill, with `SKILL.md` inside. That installs cleanly with Method B.

6. **Document tool dependencies inside the skill**, not in this README, unless the whole library suddenly needs a shared runtime.

7. After a new deposit, Method A users get it on the next skill reload. Method B users need a new symlink for that skill.

Suggested families that would still fit, without any change to the install story: sequence analysis, structural bioinformatics, cheminformatics, phylogenetics, further transcriptomics (DESeq2, HISAT2/StringTie), molecular dynamics, more teaching labs, database access, and manuscript-side research ops.

---

## How a skill is structured (for authors)

A good deposit is a procedure, not a paper reprint.

| Piece | Role |
|-------|------|
| `name` / `description` | Identity and auto-invocation |
| Overview and biological goal | Why the workflow exists |
| Prerequisites | Tools and versions |
| Ordered steps | What the agent must do, in order |
| Parameters and decision rules | Defaults and when to change them |
| Worked example | One concrete case so numbers can be checked |
| Anti-patterns | What not to do (annotation bias, off-targets, wrong gene finder, …) |
| Scope limits | What the skill does not cover |

Shapes already in this library, all valid:

- **Knowledge base** — `parikesit-protein-domains` (dissertation chapters you consult)
- **Teaching-lab protocol** — `parikesit-transcriptomics-protocol` (course sessions with canonical commands)
- **General pipeline** — the siRNA skills (steps you execute on any target)
- **Disease application** — `alzheimer-epigenetics-ai-pipeline` (a named cohort, gene set, and paper)
- **Teaching app** — `nietzschean-ai-equations` (a Streamlit app built and extended page by page)
- **Document generator** — `prd-ai-life-sciences` (a bundled script plus a review checklist)

Mix them as the work requires. A future deposit can be any of these, or something else (a database client, another course pack).

---

## Author

**Dr. rer. nat. Arli Aditya Parikesit**
Department of Bioinformatics, i3L University, Jakarta, Indonesia
ORCID: [0000-0001-8716-3926](https://orcid.org/0000-0001-8716-3926)

If you use a skill in published work, cite the scientific paper or thesis named in that skill’s frontmatter or Citation section, not only this repository.

---

## License

Individual skills may declare their own license in frontmatter (OpenMM MD and the Alzheimer pipeline are MIT). Unless a skill file says otherwise, the repository is released under the MIT License (see [`LICENSE`](LICENSE)).

## AI Assistance Disclaimer
This codebase was developed with the assistance of Claude Code and Grok CLI. While the AI provided code generation, debugging, and structural support, the human developer maintains full responsibility for reviewing, testing, and maintaining all content and functionality.