# Section guide — PRD for AI in Life Sciences and Health

Use this when populating a draft (Section B of SKILL.md) or reviewing an existing PRD (Section C). For each section: what must be present, what is commonly missing, and which archetypes need extra attention.

**Archetypes** referenced below:
- **CLIN** — clinical AI / SaMD whose output reaches a clinician or patient (imaging, risk scores, decision support, digital diagnostics)
- **RND** — drug-discovery / translational R&D AI (target ID, virtual screening, ADMET, biomarker discovery)
- **BIX** — bioinformatics / omics platforms and pipelines (variant calling and interpretation, expression analysis, metagenomics, structure prediction)
- **LLM** — generative / LLM-based assistants (literature QA, report drafting, clinical summarisation, chat)

## Contents
0. Document control · 1. Executive summary · 2. Problem · 3. Vision & non-goals · 4. Users · 5. Intended use & use cases · 6. Scope & assumptions · 7. Functional requirements · 8. AI/ML requirements · 9. Data · 10. Validation · 11. Regulatory · 12. Risk & ethics · 13. Security & privacy · 14. NFRs · 15. Architecture · 16. UX · 17. MLOps · 18. KPIs · 19. Commercialisation · 20. Plan · 21. Risks & decisions · Appendices

---

## 0. Document control
**Must have:** revision table; approvals including a clinical/scientific lead and regulatory/QA where the product could be a device; related-document links (risk file, DPIA, evidence plan, PCCP).
**Often missing:** privacy officer and security sign-off; links to model cards and datasheets.
**Archetype notes:** RND/BIX academic tools may replace "Regulatory Affairs" with "Ethics/IRB liaison" and "Core facility lead", but should not delete the row — mark N/A with reason.

## 1. Executive summary
**Must have:** one paragraph on what/for whom/where/outcome; the decision being requested; top 3–5 risks with owners.
**Often missing:** the decision requested. A PRD that asks for nothing gets no gate decision.

## 2. Problem statement
**Must have:** current workflow and its failure modes with sourced evidence; why AI over rules/non-software; landscape table including open-source and published models.
**Often missing:** the "alternatives considered and rejected" paragraph. Regulators and reviewers ask for it.
**Archetype notes:** BIX — compare against the standard pipelines (e.g., GATK-style best practices, nf-core workflows) not only commercial tools. LLM — compare against a retrieval-only or non-generative baseline.

## 3. Vision, goals, non-goals
**Must have:** objectives with baseline, target, measurement method; explicit non-goals that bound the intended use.
**Often missing:** non-goals altogether. Examples that should appear when true: "does not provide a diagnosis"; "not validated in paediatric patients"; "not intended for germline variant reporting"; "not for use as the sole basis for compound progression".

## 4. Users, stakeholders, personas
**Must have:** primary vs. secondary users with expertise level (domain vs. ML literacy); stakeholder map including regulators, payers, ethics committee, data custodians; affected non-users.
**Often missing:** affected non-users (patients whose data trained the model; populations absent from training data; staff whose work changes).

## 5. Intended use, use cases, user stories
**Must have:** intended-use statement (what, for whom, setting, user, purpose, how output is used); indications; contraindications and unvalidated populations; as-is/to-be workflow with the exact point where the AI output enters a decision; foreseeable misuse with controls.
**Often missing:** contraindications; what happens when the model abstains or the service is down; RUO vs. clinical separation.
**Archetype notes:** CLIN — this section determines device class; wording must be conservative and consistent across the whole document. RND — state whether output informs a human decision or gates an automated pipeline step. BIX — state reference genome build, assay/platform scope and sample types in the indications. LLM — state whether generated text can enter a patient record or publication without human edit (it should not).

## 6. Scope, assumptions, constraints, dependencies
**Must have:** in/out scope for this release; assumptions with owner, impact-if-false and validation plan; constraints incl. data residency and compute; dependencies with needed-by dates.
**Often missing:** data-access and EHR/LIMS-integration assumptions — the two most common causes of health-AI project delay.

## 7. Functional requirements
**Must have:** unique IDs, "shall" statements, MoSCoW priority, testable acceptance criteria, trace column. Feature areas: ingestion/validation, inference, results/explainability/reporting, human-in-the-loop override, IAM, audit/provenance, integration, admin/monitoring, feedback/incident reporting.
**Often missing:** override recording with rationale; provenance sufficient to reproduce a result (container digest, workflow version, reference data version, seeds); a "never auto-execute clinically consequential action" requirement.
**Archetype notes:** BIX — inputs as FASTQ/BAM/CRAM/VCF, outputs coded with HGVS/HGNC; provenance is central. CLIN — FHIR/DICOM integration and terminology coding. LLM — citation/grounding display and clear labelling of generated text.

## 8. AI/ML model requirements
**Must have:** model overview table (task, paradigm, architecture, locked vs. adaptive, inputs/outputs, third-party models and licences); performance table with primary metric, minimum acceptable, target, comparator, evaluation dataset; subgroup table with minimum n and max gap; uncertainty/abstention/OOD handling; explainability with audience; reproducibility; documentation deliverables (model card, datasheet, evaluation report, failure-mode register).
**Often missing:** justification of the metric in terms of clinical/scientific consequence; calibration; pre-specified subgroups; LLM sub-section when there is an LLM anywhere in the stack (including "just for summaries").
**Archetype notes:** CLIN — sensitivity/specificity at a fixed operating point, PPV/NPV at expected prevalence, calibration. RND — enrichment/precision at k, scaffold-split evaluation, applicability domain. BIX — concordance with orthogonal assay/truth sets, per-variant-class performance, batch/platform robustness. LLM — factuality/groundedness rate, harmful-output rate, refusal behaviour, prompt/index versioning, PHI-in-prompt policy.

## 9. Data requirements and governance
**Must have:** data inventory with purpose, custodian, n, consent/lawful basis, agreement; representativeness vs. intended-use population; reference-standard definition and labeller qualifications with agreement targets; QC thresholds; patient-level (or equivalent) split to prevent leakage; de-identification method; lineage/versioning/retention; access and publication policy.
**Often missing:** the reference standard's own limitations; genomic re-identification risk; consent-withdrawal handling.
**Archetype notes:** BIX/RND — deposition plans (ENA/SRA/GEO/EGA/dbGaP, ChEMBL-style releases) and controlled-access tiers. CLIN — Safe Harbor vs. Expert Determination choice.

## 10. Clinical and scientific validation plan
**Must have:** three-tier framing (scientific validity, analytical validation, clinical validation) mapped to study types, datasets, endpoints; per-study details with sample-size justification and pre-registration; external/temporal validation; reporting guidelines selected; ethics approvals; publication plan.
**Often missing:** external validation on an independent site or platform; usability/human-factors as a validation tier; a plan for real-world performance after release.
**Archetype notes:** CLIN — reader studies, silent deployment, prospective study or RCT depending on claim. RND — prospective experimental validation of predictions (wet-lab confirmation rate). BIX — truth-set benchmarking (e.g., reference-material samples) plus real-sample concordance. LLM — expert-adjudicated factuality evaluation with inter-rater agreement.

## 11. Regulatory and compliance
**Must have:** classification determination per market with date and decider; pathway table; standards list with editions; privacy regimes table; labelling/claims process; post-market surveillance.
**Often missing:** the date of the determination; EU AI Act high-risk assessment; GxP scope when the tool is used in drug development (21 CFR Part 11 / Annex 11); national rules for the user's own market.
**Honesty note:** name frameworks; do not assert a class or pathway for the user's product; direct to Regulatory Affairs and the issuing authority. Indonesian users: point to Kemenkes/BPOM and UU No. 27/2022 (PDP) and say current AI-specific guidance must be checked.

## 12. Safety, risk management, ethics
**Must have:** ISO 14971-style register including AI-specific hazards (silent degradation, automation bias, mis-calibration, adversarial input, data shift, spurious correlation, hallucinated citations); safety-case summary; human-oversight model; change management for updates; ethical impact table; AI-incident response with kill switch and CAPA.
**Often missing:** automation-bias controls in the UI; who is accountable when the AI is wrong; dual-use consideration (re-identification, biosecurity-relevant capability).

## 13. Security and privacy
**Must have:** threat model including model inversion, membership inference, poisoning, adversarial examples, prompt injection; encryption, IAM, testing, artefact integrity, SBOM, patch SLA; data minimisation, data-subject rights, no PHI to third-party APIs without BAA/DPA; BC/DR with degraded-mode operation.
**Often missing:** what clinicians do when the AI is unavailable; PHI leakage through logs and LLM context windows.

## 14. Non-functional requirements
**Must have:** latency/throughput at percentile under load; availability; interoperability standards (FHIR, DICOM, OMOP, GA4GH, terminologies); usability targets (summative testing, WCAG); deployability (cloud/on-prem/air-gapped, IaC, containers); data residency and retention; cost.
**Often missing:** air-gapped or on-premise constraint common in hospitals and core facilities; resumable/idempotent batch jobs for pipelines.

## 15. Technical architecture
**Must have:** context diagram with data classification on flows; component table with safety-relevance flag; environments; storage zones separating identifiable and de-identified data; SDLC aligned with IEC 62304 where applicable.
**Often missing:** separation of identifiable and de-identified zones; GPU/compute needs; validation environment distinct from test.

## 16. UX and human factors
**Must have:** UX principles (confidence at point of decision, easy override, AI-generated content clearly marked, visible failure); key flows including abstention and degraded states; human-factors plan; training/IFU; accessibility.
**Often missing:** abstention/empty/error states; competency assessment for users.

## 17. Model lifecycle and MLOps
**Must have:** lifecycle gates with entry/exit criteria and approvers; versioning of data, code, weights, prompts, indexes, config; monitoring table with metric, threshold, frequency, owner, response (drift, prevalence, delayed-label performance, subgroup, abstention/override, latency, feedback, LLM-specific); retraining/update policy aligned with PCCP; retirement.
**Often missing:** thresholds and owners; how ground truth is obtained post-deployment; rollback procedure.

## 18. Success metrics and KPIs
**Must have:** categories — clinical/scientific outcome, production model quality, safety, adoption, trust, operational, business/academic — each with baseline, target, data source, cadence.
**Often missing:** safety KPIs; baselines.

## 19. Commercialisation / adoption
**Must have:** segments and value proposition; business model or funding model; reimbursement and health-economic plan where relevant; GTM/deployment; IP and licences; sustainability of validation and monitoring.
**Archetype notes:** academic/internal tools — replace commercial items with funding, maintenance and community plan; do not delete the section.

## 20. Release plan and resourcing
**Must have:** phased roadmap with evidence/regulatory gate per phase; RACI; budget summary including validation studies and regulatory fees.

## 21. Project risks, open questions, decisions
**Must have:** delivery risks (distinct from patient-safety risks in 12); open questions with owner and needed-by; decision log with options considered.

## Appendices
A glossary · B model card · C dataset datasheet · D traceability matrix (requirement → story → design → risk control → test → verification → validation) · E completeness checklist (every "No" needs a justification) · F reference frameworks (verify editions before citing).

---

## Minimum viable PRD (when the user wants a short version)
If asked for a "lite" or "one-pager" PRD for a health-AI product, do not drop below these: 1 executive summary, 5.1 intended use with non-goals, 8.2 primary metric with minimum and comparator, 9.1 data inventory with lawful basis, 10.1 evidence strategy table, 11.1 classification determination, 12.1 top hazards, 17.3 monitoring table. Everything else can be deferred; these cannot without making the product unreviewable.
