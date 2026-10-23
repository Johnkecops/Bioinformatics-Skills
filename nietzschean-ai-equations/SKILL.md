---
name: nietzschean-ai-equations
description: Build or extend the "Beyond Good and Computation" Streamlit app and its equation visuals, pairing each AI/optimization equation (softmax, backprop, attention, KL, cross-entropy, linear regression, gradient descent, linear programming, ADAM, MLE) with working code, an interactive demo, and a Nietzschean framing. Use when asked to add, fix, or explain one of these ten equations, or to produce the post-modern equation table, widget, or app for the i3L bioinformatics audience.
---

# Nietzschean AI Equations

Project: "Beyond Good and Computation." Audience: Prof. Dr. Arli Aditya Parikesit and computational biology students at i3L.

## Output rules

- Keep each equation's math correct before styling it. Verify formulas against a reference before writing them.
- Each equation entry has four parts: equation, short "why it matters" note, a runnable code snippet (NumPy, PyTorch, or SciPy), and a bioinformatics use case.
- Nietzschean framing is a lens on the equation's purpose (will-to-power, will-to-order, will-to-correct). It never replaces the mathematics. Do not invent quotes from Nietzsche.
- Bioinformatics examples: QSAR baselines, flux balance analysis (LP), transcriptomics (MLE, KL), immunoinformatics (softmax over HLA, cross-entropy for binding).

## Equation reference

| # | Equation | Core form | Will (framing) |
|---|---|---|---|
| 1 | Softmax | σ(z_i) = e^{z_i} / Σ e^{z_j} | order / probability |
| 2 | Backpropagation | ∂L/∂w = ∂L/∂y · ∂y/∂z · ∂z/∂w | correction |
| 3 | Attention | softmax(QKᵀ/√d)V | focus |
| 4 | KL divergence | D_KL(P‖Q) = Σ P log(P/Q) | distance (asymmetric) |
| 5 | Cross-entropy | L = −Σ y_i log ŷ_i | truth |
| 6 | Linear regression | w* = (XᵀX)⁻¹Xᵀy | approximation |
| 7 | Gradient descent | w_{t+1} = w_t − α∇L | descent |
| 8 | Linear programming | min cᵀx s.t. Ax ≤ b, x ≥ 0 | constraint |
| 9 | ADAM | m̂/(√v̂+ε) update with bias correction | adaptation |
| 10 | MLE | θ* = argmax Σ log p(y_i\|x_i,θ) | explanation |

## App structure (streamlit_app.py)

- `st.set_page_config` (wide layout), custom CSS dark theme (#0f0f1e background, #dc2626 accent).
- Sidebar radio selects one page: Manifesto, eight-plus equation pages, Comparative Analysis.
- Each equation page: left column (equation, philosophy box, implementation box), right column (interactive matplotlib plot with sliders).
- Plot style: transparent or #1a1a2e axes, #9ca3af ticks, no top/right spines.

## Workflow

1. Read the current `streamlit_app.py` (or the project doc of the same name) before editing.
2. Add or change one page at a time. Keep the page pattern above.
3. Seed randomness (`np.random.seed`) in any demo that should be stable across reruns.
4. Run `python -m py_compile streamlit_app.py` to check syntax. Run `streamlit run streamlit_app.py --server.headless true` and check the page loads before claiming it works.
5. Deliver changed files with SendUserFile.

## Known issues in the current app (fix or disclose)

- The app and documentation were never executed in this session. Do not describe it as "tested" or "production ready" without running it.
- Softmax and attention demos use unseeded `np.random`, so plots change on every slider move.
- The MLE implementation snippet contains invalid Python (`p(y|x,theta)`, `dist.fit`) and is illustrative only.
- README and FILE_SUMMARY list a citation "Parikesit et al., Protein Domain Annotation (various)" and a GitHub URL placeholder. These are not verified references. Remove or verify them.
- Requirements pin old versions (torch 2.0.1, streamlit 1.28.1) that may not install on Python 3.12+. Verify before pinning.
- Bio-profile details (titles, affiliations) must come from the faculty page or the user, not memory.

## Honesty rules for this skill

- State what was run and what was not. If a file was not executed, say so.
- Flag any number, citation, or statistic you cannot verify.
- Do not publish Artifacts to claude.ai. Deliver files to the outputs folder and the conversation.
