---
name: prd-ai-life-sciences
description: Generate a comprehensive Product Requirements Document (PRD) for AI/ML products in life sciences and health — clinical AI / SaMD, drug-discovery and R&D AI, bioinformatics and omics platforms, digital health apps, and LLM-based health tools — either as a blank fill-in template or as a populated draft for a specific product, delivered as a formatted .docx. Use this whenever the user asks for a PRD, product requirements, product spec, requirements document, feature spec, or "requirements template" for anything touching healthcare, clinical, biomedical, pharma, genomics, diagnostics, medical devices or health AI — even if they only say "write the requirements for my AI tool" or "spec out this model" without saying PRD. Also use when a user wants to review an existing health-AI PRD for missing sections (intended use, validation plan, regulatory classification, risk register, MLOps monitoring).
---

# PRD for AI in Life Sciences and Health

A PRD for a health or life-science AI product has to do two jobs a generic software PRD does not: bound the **intended use** tightly enough that a regulator, ethics committee or clinical lead will accept it, and pre-specify the **evidence** (performance thresholds, subgroups, validation tiers, monitoring) that will be needed to defend it. This skill produces a 44-page, 21-section Word document with six appendices that does both.

## Decide the mode first

| User signal | Mode | What to do |
|---|---|---|
| "template", "blank", "format", no product details given | **Template** | Run the bundled script (Section A). ~1 minute. |
| Names a product, model, disease, dataset or team | **Populated draft** | Run the script to get the skeleton, then fill it (Section B). |
| Pastes or uploads an existing PRD | **Gap review** | Compare against `references/section_guide.md` and report missing/weak sections (Section C). |

If the signal is ambiguous ("PRD for my variant classifier"), produce a populated draft — the user has given enough to start and a blank template would feel like a non-answer. State any assumptions you fill in.

## Section A — Blank template

Read `/mnt/skills/public/docx/SKILL.md` first if anything in the document must be edited afterwards; for a straight template you only need the script.

```bash
node <skill-path>/scripts/build_prd_template.js /mnt/user-data/outputs/PRD_Template_AI_Life_Sciences_Health.docx \
  --product "Product name" --org "Organisation" --author "Owner" --version "v0.1 DRAFT"
```

All flags are optional. The script needs the `docx` npm package (preinstalled in the Anthropic sandbox; otherwise `npm install docx`). It writes A4, Calibri, navy/teal headings, yellow-highlighted `[fill-in]` fields, grey italic guidance notes, and a table of contents that populates on F9 in Word (LibreOffice renders it empty — that is expected, not a bug).

Then present the file with `present_files` and tell the user, in two or three sentences, what the document contains and that regulatory references are anchors to verify, not conclusions. Do not offer to publish it as an Artifact.

## Section B — Populated draft for a named product

1. Generate the skeleton with the script into `/home/claude/` (not outputs yet).
2. Read `references/section_guide.md`. It lists, for every section, what must be present, common omissions, and which product archetype (clinical SaMD, R&D/discovery tool, bioinformatics pipeline, LLM assistant) needs what.
3. Ask the user at most one round of questions, and only for things you cannot reasonably infer: intended-use population and setting, whether the output reaches patients or clinicians, target markets, data already in hand. Everything else, draft with explicit assumptions and mark them in Section 6.3 (Assumptions) so they are reviewed rather than silently accepted.
4. Fill the document by editing the generated .docx (unzip → edit `word/document.xml` → zip, per the docx skill) or, if most of the content changes, by copying `scripts/build_prd_template.js` and replacing `placeholder(...)` calls with real `p(...)` paragraphs. The second route is usually cleaner for a full draft. Keep the guidance notes for sections you could not fill; delete them for sections you did.
5. Leave `[fill-in]` highlights on anything that requires a human decision: sign-offs, performance thresholds nobody has agreed, regulatory classification, IRB numbers. A draft that invents a sensitivity target or a device class is worse than one with a visible gap.
6. Render to PDF and inspect at least the title page, one requirements table and the risk register before presenting.

## Section C — Gap review of an existing PRD

Convert with `pandoc -t markdown` if it is a .docx. Walk `references/section_guide.md` top to bottom and produce a table: section, present / partial / missing, why it matters for this product, what to add. Prioritise the five sections most often missing from health-AI PRDs: intended-use statement, pre-specified subgroup performance, reference-standard definition, regulatory classification with date, and post-deployment monitoring thresholds. Deliver as a .docx or .md depending on how the input arrived.

## Things that make health-AI PRDs fail review

Keep these in mind whichever mode you are in; they are the reasons the template is shaped the way it is.

- **Claims drift.** Marketing says "diagnoses", the intended-use statement says "supports triage". Every claim anywhere in the document must be consistent with 5.1.
- **Metrics chosen after the fact.** The primary metric, minimum acceptable value and comparator belong in the PRD before any model is trained (Section 8.2). Otherwise the validation is unfalsifiable.
- **Leakage.** Train/test splits at the image or sequence level rather than the patient/sample level. Section 9.4 asks for this explicitly.
- **RUO/clinical blur.** Research-use-only tools quietly used to return results to patients. Section 5.5 (foreseeable misuse) is where this is caught.
- **LLM components treated as ordinary features.** Grounding, hallucination rate, PHI-in-prompt policy and prompt-injection defences are separate requirements (Section 8.6).
- **Monitoring described as "we'll watch it".** Section 17.3 needs named metrics, thresholds, owners and responses.

## Honesty constraints for regulatory content

Name frameworks by their common titles (FDA CDS guidance, EU MDR 2017/745, EU AI Act 2024/1689, ISO 14971, IEC 62304, TRIPOD+AI, and so on) and tell the user to verify editions and applicability against the issuing body. Do not invent guidance document numbers, publication dates, or claim a specific device class for the user's product. If the user's market is one whose rules you are unsure about (many national ministries of health), say so and point to the ministry rather than guessing. Reporting-guideline publication status changes — flag STARD-AI and similar as "confirm current status" rather than asserting they are final.

## Bundled files

- `scripts/build_prd_template.js` — generator; run it, do not reimplement it.
- `references/section_guide.md` — per-section content checklist and archetype notes; read for populated drafts and gap reviews.
