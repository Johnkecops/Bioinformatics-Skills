---
name: cooccurrence-benchmark
description: Measure histone-mark (or any binary-feature) co-occurrence and avoidance across one or more tables with the project's mandatory rigor guardrails. Use when benchmarking a database, adding a data source, reasoning about which unit a co-occurrence question is defined on, or reporting which feature pairs co-occur or avoid each other. Enforces the unit-of-row check first, then degenerate-column filtering, two-sided Fisher exact testing with odds ratios and exact confidence intervals, one Benjamini-Hochberg family per source, a simulation-based software check, and honest labelling of curation-effort correlations.
---

# Co-occurrence and avoidance benchmark

For a table whose rows are entities and whose columns are binary marks, decide which mark
pairs occur together more or less often than chance, with the guardrails that keep the
result publishable. The skill exists so a weaker model cannot skip FDR, test a constant
column, report a p-value with no effect size, or (the failure that cost this project a
round of peer review) run the test on a table whose rows are not the unit the question is
about.

Reference implementation: `stats_core.py` (`compute_stats`, `generate_nucleosome_data`),
imported by `benchmark_databases.py`, `generate_figures.py` and `app-covid.py`. There is one
copy; do not add a second. For the pattern of finding a unit a resource does support, see
`curated_db_context.py` (`taxon_cooccupancy`, `variant_map`, `power`). Read before extending.

## When to use

- Adding a new database or data source to the benchmark.
- Reporting co-occurrence or avoidance for any binary or binarizable feature table.
- Any time the sentence "these marks co-occur" or "these marks avoid each other" is about
  to appear in output.
- Any time a reviewer, collaborator or you ask what a curated resource can actually support.

## Step 0. The unit-of-row check, before anything else

**A co-occurrence question is defined only when both marks are scored on the same physical
unit.** Ask, in order:

1. What is one row? (A nucleosome? A PTM site? A sequence family? A taxon?)
2. What does each column hold: a measured mark on that unit, or a curation attribute
   (enzyme counts, HMM scores, sequence counts, taxon counts, sequence length)?
3. Could two marks in this table be present on the same physical object at the same time?

If the answer to 3 is no, **stop. Do not run the pairwise test and report it as
co-occurrence.** The test will still return numbers, and some will cross the significance
threshold, but they describe how the records were assembled, not biology. Two worked
examples from this project:

| Resource | Row | "Significant" pair | What it actually measures |
|---|---|---|---|
| HistoneDB 2.0 | histone variant | sequence count vs taxon count (OR 122, p_adj 8.7e-6) | A variant cannot span more taxa than it has sequences. Bounded by construction. |
| HISTome2 | PTM site | writer count vs eraser count (OR 4.70, p_adj 0.0068) | A well-studied site accumulates annotations of both kinds. Curation effort. |

Call these **curation-effort correlations** in every output. Never "co-occurrence". The
honest framing is a positive statement about what the attributes measure, not a report of
a failed test.

**When the unit is wrong, look for a unit the resource does support** rather than
abandoning it. ProHistoneDB rows are proto-histone categories, which is the wrong unit,
but taxon occupancy is a real shared unit: score each category present or absent per taxon,
and the same machinery becomes valid (`curated_db_context.taxon_cooccupancy`). State the
universe (every taxonomic code attached to a named clade across all category trees, n = 174)
and the filtering rule (drop categories present in < 2 taxa) in the methods, because both
change the result.

## Step 1. Binarize continuous features by median split, then filter degenerates

```python
numeric = pd.to_numeric(df[col], errors="coerce")
vals = numeric.dropna()
if len(vals) >= 2:
    median = vals.median()
    df[new_name] = (numeric > median).fillna(False).astype(int)
```

Median splitting costs information and forces roughly 50% prevalence, which caps achievable
enrichment near 2x. Say so when reporting; it is a limitation, not a property of the data.

`compute_stats` drops any column with `nunique(dropna=True) < 2` before building the test
family. Median split of a low-variance integer feature (HISTome2 `multi_mod`, where every
site carries exactly one modification type) produces a constant column. Log every drop: a
silently dropped column reads as "not tested" when it should read "could not be tested".

## Step 2. Observed vs expected under independence

For each unordered pair (i, j), i < j:

```python
both = ((df[mi] == 1) & (df[mj] == 1)).sum()
pi, pj = df[mi].mean(), df[mj].mean()
exp_cnt = n * pi * pj          # expected joint count if independent
```

## Step 3. Two-sided Fisher exact test (primary), with the 2x2 table

```python
from scipy.stats import fisher_exact
n11 = int((a & b).sum()); n10 = int((a & ~b).sum()); n01 = int((~a & b).sum())
table = [[n11, n10], [n01, n - n11 - n10 - n01]]
p = fisher_exact(table, alternative="two-sided")[1]
```

**Fisher, not Poisson.** The Poisson distribution approximates the binomial count of joint
occurrences only when `p_i * p_j` is small. For the strongest simulated pair here that
product is 0.137, so the Poisson tail is visibly wider than the exact distribution: the
co-occurrence test comes out conservative and the avoidance test anti-conservative. Fisher
conditions on the observed margins, needs no approximation, and gives both directions from
one test instead of two overlapping one-tailed tests.

If asked why not the alternatives: chi-square fails because expected cell counts fall below
five in the small tables (n = 24 to 62 for the curated resources); logistic regression is
not used because the question is pairwise and n does not support a multivariable model.

Keep Poisson and exact binomial p-values for the same pairs as a **sensitivity analysis**,
reported in supplementary material. They show that the choice of test changes which pairs
cross the threshold, which is itself an argument for the exact conditional test.

## Step 4. Effect size with uncertainty, always alongside the p-value

```python
from scipy.stats.contingency import odds_ratio
res = odds_ratio(table)              # conditional maximum likelihood
ci = res.confidence_interval(0.95)   # exact interval
lfc = np.log2(both / exp_cnt) if both > 0 else -np.inf
```

Report the odds ratio, its exact 95% CI, and the log2 ratio next to every p-value. An
FDR-adjusted p with no effect size is not a result. When no units are shared the odds ratio
is 0 and the lower limit is 0; report the **upper** confidence limit instead (for example,
the viral doublet against the archaeal face-to-face fold: 0 shared taxa, 12.0 expected,
upper limit 0.158). When a margin is zero the odds ratio can be infinite; print "infinity"
rather than a float.

## Step 5. One Benjamini-Hochberg family per data source

```python
from statsmodels.stats.multitest import multipletests
p_adj = multipletests(p_fisher, method="fdr_bh")[1]
```

The family is **m(m-1)/2 two-sided tests per source**: one per unordered pair, corrected
once. Earlier versions of this pipeline corrected co-occurrence and avoidance as two
families over overlapping tails of the same comparisons, which double-counted the burden
and let the two p-values sum to more than one. Do not reintroduce that.

Direction comes from the sign of observed minus expected, not from a second test:

```python
up = df["observed"] > df["expected"]
df["cooccurrence_significant"] = up & (df["p_fisher_adj"] < alpha)
df["avoidance_significant"] = ~up & (df["p_fisher_adj"] < alpha)
```

`compute_stats` also scatters the adjusted values into `p_cooccurrence_adj` /
`p_avoidance_adj` matrices so figures gate on adjusted p, never raw. Any figure legend
claiming FDR must be drawn from those matrices.

## Step 6. Simulation-based software check, in the same batch

Run `generate_nucleosome_data(n_nuc=200, seed=42)` as an extra source in every batch. It has
six rules written in (H3K4me3 with H3K27ac, H3K27ac with H2AK5ac, H3K4me3 with H2AK5ac
co-occur; all three active marks avoid H3K9me3; H3K36me3 independent). If the analysis does
not recover them, the pipeline is broken and no real-data result is trustworthy.

**Call it a software check, not a positive control and never biological validation.** The
rules are written into the generator, so recovering them is expected by construction, and a
reviewer will say so. Each rule and its probability must trace to a citation (active-promoter
surveys, heterochromatin separation, gene-body tracking, shared acetyltransferase
recruitment), and the marginal frequencies the rules produce (22% to 38.5% here) should sit
inside the range reported for individual marks in reference epigenomes.

Power at n = 200, over 1,000 replicates (`curated_db_context.power`, 8 worker processes,
about one minute):

| Relationship | Power at n = 200 |
|---|---|
| H3K4me3 / H3K27ac | 1.000 |
| H3K27ac / H2AK5ac | 0.999 |
| H3K27ac / H3K9me3 | 0.996 |
| H3K4me3 / H3K9me3 | 0.996 |
| H3K4me3 / H2AK5ac | 0.842 |
| H3K9me3 / H2AK5ac (indirect) | 0.336 |

False-positive rate for at least one of the four pairs involving the independent mark: 0.090.
Report the indirect figure too. Quoting only the favourable five is the kind of selective
reporting this skill exists to prevent.

Real validation means nucleosome-resolution assays (Co-ChIP, single-molecule decoding), not a
larger simulation. Say that rather than implying the check validates biology.

## Step 7. Provenance, caching and reproducibility

- Cache every download under `data/raw/` (`histone_mark_mining._cached_get`) so reruns use
  one dated snapshot and a truncated transfer cannot change the input silently. A partial
  XML that parses as "fewer categories" is otherwise invisible: this project retrieved 21,
  then 23, then 24 ProHistoneDB categories across three runs before caching caught it.
  Delete the cached file to refresh.
- Parse XML with `defusedxml.ElementTree`, not the stdlib parser.
- Print per source: the source, N, marks kept, marks dropped, and every significant pair
  with obs, exp, OR, CI and adjusted p.
- Write two CSVs: the summary (`results/figures/db_comparison_summary.csv`) and the full
  per-pair table with effect sizes and sensitivity p-values
  (`results/figures/db_comparison_full.csv`).
- Figures at `dpi=600` with a PDF alongside; `matplotlib.use("Agg")` before pyplot.
- Cite the analysis by commit hash. If the commit is rewritten (files removed before a
  push, say), rebuild any document that quotes the old hash.

## Quality gate (all must be true before you report a result)

- [ ] Unit-of-row check done, and any curation-attribute result labelled as a
      curation-effort correlation rather than co-occurrence.
- [ ] Simulation-based software check ran in the same batch and recovered its six rules.
- [ ] Degenerate columns filtered and every drop logged.
- [ ] Every pair has an FDR-adjusted Fisher p, an odds ratio, and an exact 95% CI.
- [ ] One BH family per source, sized m(m-1)/2; direction from observed minus expected.
- [ ] Figures gate on the adjusted matrices, and their legends say so.
- [ ] Poisson and binomial sensitivity values reported in supplementary material.
- [ ] Provenance (source, N, retrieval date) printed for every table.
- [ ] Summary and full CSVs written, and their numbers match what the manuscript cites.
- [ ] Power reported for the simulated check, including the weakest relationship.

## What to hand back

State, in plain language a wet-lab reader can act on: which pairs co-occur, which avoid,
the effect size and interval for each, and whether the software check passed.

Separate the three kinds of statement explicitly:

1. **Measured on a shared unit** (the simulated set, taxon occupancy). Real associations.
2. **Curation-effort correlations** (attribute pairs in curated resources). Real numbers
   about how records were assembled, never biology.
3. **Hypothesis** (what the pattern might mean mechanistically). Labelled as such.

If a result changes a number the manuscript already quotes, say so in the handback with the
old and new values and where they appear. Do not dress up a null result, do not hide one,
and do not let a significant p on a curation attribute become a biological claim.
