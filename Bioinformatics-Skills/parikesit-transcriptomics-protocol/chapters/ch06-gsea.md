# Chapter 6: GSEA Tutorial

## Core Idea
Run Gene Set Enrichment Analysis in the Broad GSEA desktop app: load four tab-delimited inputs, set required parameters, run, then refine with leading-edge analysis and MSigDB gene sets.

## Frameworks Introduced
- **Four ways to run GSEA**: desktop app (GUI), `.jar` command line (offline), R-GSEA, GenePattern module.
- **Four required input files**
  1. Expression dataset — `.gct` (or `.res`, `.pcl`)
  2. Phenotype labels — `.cls`
  3. Gene sets — `.gmt`
  4. Chip annotations — `.chip` (probe → HUGO symbol)
- **Parameter tiers**: Required / Basic (defaults fine) / Advanced (rarely changed).
- **Pilot-then-full permutations**: 5 permutations to test, 1000 for results.
- **Identifier consistency rule**: every file must use the same identifier space.
- **Leading edge analysis**: genes recurring in leading-edge subsets of several enriched sets are most interesting.

## Key Concepts
- **P53 sample data**: `p53_hgu95av2` dataset, MUT vs WT phenotypes (Subramanian & Tamayo, PNAS 2005).
- **c1.v2.symbols.gmt**: positional gene sets used in the demo.
- **HG_U95Av2.chip**: chip annotation for demo.
- **Collapse dataset to gene symbols** (default true): merges probe sets to one gene vector; prevents multi-probe score inflation.
- **Permutation type = phenotype**.
- **MSigDB**: Molecular Signatures Database; browse, filter, export gene sets.
- **Processes panel**: blue Running (pause/stop), red Error, green Success (open report).
- **GSEA output folder**: Help › Show GSEA output folder; change via Options › Preferences.

## Code Examples
Run steps (GUI):
1. Load Data → Browse for files → select `.gct`, `.cls`, (`.gmt`, `.chip`) → Open.
2. Run GSEA → dataset `p53_hgu95av2` → gene sets `c1.v2.symbols.gmt` → permutations 5 → phenotype MUT_vs_WT → chip `HG_U95Av2.chip` → Collapse = true → Permutation type = phenotype → Run.
3. Leading Edge Analysis → pick report → Load GSEA Results → sort by FDR, select 11 sets with FDR < 0.01 → Run.

## Anti-patterns
- **Saved files with extra `.txt`** (`p53.gct.txt`): rename to `.gct`/`.cls`.
- **Mixing probe IDs and gene symbols**: collapse=true requires HUGO-symbol gene sets; collapse=false requires probe-ID gene sets.
- **Trusting 5-permutation results**: pilot only.
- **Expecting exact reproduction of paper numbers**: RNG/seeds differ; significant sets still match.

## Key Takeaways
1. Four inputs, all tab-delimited ASCII, editable in Excel/text editor.
2. Keep collapse=true unless you have a reason.
3. Validate setup with 5 permutations, then run 1000.
4. Use FDR < 0.01 sets for leading-edge analysis.
5. Share results by zipping the report folder (or set "Make a zipped file with all reports" = true).
6. Re-run exact parameters from Analysis History › Show in ToolRunner.
7. Help: in-app ? buttons, GSEA User Guide, groups.google.com/group/gsea-help.

## Connects To
- **Ch 5**: provides expression/DE input; mouse MSigDB `.rdata` files for R-based enrichment.
- **fgsea / clusterProfiler**: R alternatives (outside book).
