const fs = require("fs");
const args = process.argv.slice(2);
const OUT = args.find(a => !a.startsWith("--")) || "PRD_Template_AI_Life_Sciences_Health.docx";
const flag = (n) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : null; };
const PRODUCT = flag("--product") || "Product name";
const ORG = flag("--org") || "Organisation / business unit";
const AUTHOR = flag("--author") || "Product owner / author";
const VERSION = flag("--version") || "Document version (e.g., v0.1 DRAFT)";
const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, Table, TableRow, TableCell,
  WidthType, ShadingType, AlignmentType, BorderStyle, LevelFormat, TableOfContents,
  PageBreak, Header, Footer, PageNumber, TabStopType, VerticalAlign
} = require("docx");

// ---------- palette ----------
const NAVY = "1F3A5F";
const TEAL = "0E7C7B";
const GREY = "6B7280";
const LIGHT = "EEF3F8";
const HEADFILL = "1F3A5F";
const FONT = "Calibri";

// ---------- helpers ----------
const p = (text, opts = {}) =>
  new Paragraph({
    spacing: { after: 120, line: 276 },
    ...opts.para,
    children: Array.isArray(text) ? text : [new TextRun({ text, font: FONT, size: 22, ...opts.run })],
  });

const guide = (text) =>
  new Paragraph({
    spacing: { after: 120, line: 276 },
    children: [new TextRun({ text, italics: true, color: GREY, font: FONT, size: 20 })],
  });

const placeholder = (label) =>
  new Paragraph({
    spacing: { after: 160, line: 276 },
    shading: { type: ShadingType.CLEAR, fill: "FFF8E1", color: "auto" },
    children: [new TextRun({ text: `[${label}]`, color: "8A6D00", font: FONT, size: 22 })],
  });

const h1 = (t) => new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun({ text: t })] });
const h2 = (t) => new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun({ text: t })] });
const h3 = (t) => new Paragraph({ heading: HeadingLevel.HEADING_3, children: [new TextRun({ text: t })] });

const bullet = (t, level = 0) =>
  new Paragraph({
    numbering: { reference: "bullets", level },
    spacing: { after: 60, line: 276 },
    children: typeof t === "string" ? [new TextRun({ text: t, font: FONT, size: 22 })] : t,
  });

const boldLead = (lead, rest) => [
  new TextRun({ text: lead, bold: true, font: FONT, size: 22 }),
  new TextRun({ text: rest, font: FONT, size: 22 }),
];

const pageBreak = () => new Paragraph({ children: [new PageBreak()] });

const cellBorders = {
  top: { style: BorderStyle.SINGLE, size: 4, color: "BFC7D1" },
  bottom: { style: BorderStyle.SINGLE, size: 4, color: "BFC7D1" },
  left: { style: BorderStyle.SINGLE, size: 4, color: "BFC7D1" },
  right: { style: BorderStyle.SINGLE, size: 4, color: "BFC7D1" },
};

function table(headers, rows, widths) {
  const total = widths.reduce((a, b) => a + b, 0);
  const mk = (txt, w, isHead, shade) =>
    new TableCell({
      width: { size: w, type: WidthType.DXA },
      borders: cellBorders,
      shading: isHead
        ? { type: ShadingType.CLEAR, fill: HEADFILL, color: "auto" }
        : shade
        ? { type: ShadingType.CLEAR, fill: LIGHT, color: "auto" }
        : undefined,
      verticalAlign: VerticalAlign.CENTER,
      margins: { top: 60, bottom: 60, left: 100, right: 100 },
      children: [
        new Paragraph({
          spacing: { after: 0, line: 260 },
          children: [
            new TextRun({
              text: txt,
              bold: isHead,
              color: isHead ? "FFFFFF" : "1F2937",
              font: FONT,
              size: isHead ? 19 : 19,
            }),
          ],
        }),
      ],
    });
  return new Table({
    width: { size: total, type: WidthType.DXA },
    columnWidths: widths,
    rows: [
      new TableRow({ tableHeader: true, children: headers.map((h, i) => mk(h, widths[i], true)) }),
      ...rows.map((r, ri) => new TableRow({ children: r.map((c, i) => mk(c, widths[i], false, ri % 2 === 1)) })),
    ],
  });
}

const spacer = () => new Paragraph({ spacing: { after: 120 }, children: [] });

// Requirement table used repeatedly
const reqTable = (prefix, rows) =>
  table(
    ["ID", "Requirement", "Priority (MoSCoW)", "Acceptance criteria / verification", "Trace"],
    rows.map((r, i) => [`${prefix}-${String(i + 1).padStart(3, "0")}`, ...r]),
    [1100, 3300, 1300, 2660, 1000]
  );

const W = 9360; // full text width (A4 with 1" margins ≈ 9360 DXA)

// ---------- content ----------
const children = [];

// Title page
children.push(
  new Paragraph({ spacing: { before: 2400, after: 200 }, children: [new TextRun({ text: "PRODUCT REQUIREMENTS DOCUMENT", bold: true, size: 56, color: NAVY, font: FONT })] }),
  new Paragraph({ spacing: { after: 200 }, children: [new TextRun({ text: "Template for AI Products in Life Sciences and Health", size: 32, color: TEAL, font: FONT })] }),
  new Paragraph({ spacing: { after: 600 }, border: { bottom: { style: BorderStyle.SINGLE, size: 12, color: TEAL, space: 4 } }, children: [new TextRun({ text: "Covers clinical AI / SaMD, drug discovery and R&D AI, bioinformatics and omics platforms, digital health, and LLM-based health applications", size: 22, color: GREY, italics: true, font: FONT })] }),
  placeholder(PRODUCT),
  placeholder("Product codename / internal ID"),
  placeholder(VERSION),
  placeholder("Date"),
  placeholder(AUTHOR),
  placeholder(ORG),
  placeholder("Confidentiality classification (e.g., Internal, Confidential, Restricted)"),
  spacer(),
  guide("How to use this template: text in [square brackets] is a fill-in field. Grey italic text is guidance and should be deleted from the final document. Sections that do not apply to your product (e.g., regulatory device classification for a purely internal research tool) should be marked 'Not applicable' with a one-line justification rather than deleted, so reviewers can see the decision was made deliberately."),
  guide("Regulatory and standards references in this template were current to the author's knowledge as of the template date. Regulations, guidances and standard editions change frequently; verify every citation against the primary source (FDA, EMA, EU Official Journal, ISO, national ministry of health, etc.) before relying on it."),
  pageBreak()
);

// TOC
children.push(
  h1("Table of Contents"),
  new TableOfContents("Table of Contents", { hyperlink: true, headingStyleRange: "1-2" }),
  guide("Right-click and choose 'Update Field' (or press F9) in Word to populate the table of contents."),
  pageBreak()
);

// 0 Document control
children.push(
  h1("0. Document Control"),
  h2("0.1 Revision history"),
  table(["Version", "Date", "Author", "Summary of changes", "Status"], [["0.1", "[YYYY-MM-DD]", "[Name]", "Initial draft", "Draft"], ["", "", "", "", ""], ["", "", "", "", ""]], [1000, 1400, 1800, 3660, 1500]),
  spacer(),
  h2("0.2 Approvals and sign-off"),
  guide("List everyone whose sign-off is required before the PRD is baselined. For regulated products this typically includes Quality/Regulatory Affairs and a clinical or scientific lead in addition to product and engineering."),
  table(["Role", "Name", "Responsibility", "Signature / date"], [["Product Owner", "", "Owns requirements and prioritisation", ""], ["Clinical / Scientific Lead", "", "Intended use, clinical validity, safety", ""], ["Engineering Lead", "", "Technical feasibility, architecture", ""], ["Data Science / ML Lead", "", "Model design, validation plan", ""], ["Regulatory Affairs", "", "Classification, submission strategy", ""], ["Quality Assurance", "", "QMS alignment, design controls", ""], ["Data Protection / Privacy Officer", "", "Lawful basis, DPIA, de-identification", ""], ["Information Security", "", "Threat model, controls", ""], ["Ethics / IRB liaison", "", "Ethical review, consent", ""], ["Commercial / Business Owner", "", "Market fit, pricing, reimbursement", ""]], [2400, 1800, 3360, 1800]),
  spacer(),
  h2("0.3 Reviewers and distribution"),
  placeholder("Names, roles and review dates of non-signing reviewers; distribution list"),
  h2("0.4 Related documents"),
  guide("Link the documents this PRD depends on or feeds into, so traceability is maintained across the design history file / technical file."),
  table(["Document", "ID / link", "Relationship"], [["Business case / opportunity assessment", "", "Input"], ["Intended use / indications for use statement", "", "Input (or Section 5.1)"], ["Clinical evaluation plan / evidence plan", "", "Output"], ["Software requirements specification (SRS)", "", "Derived from this PRD"], ["Data management plan", "", "Companion"], ["Risk management file (ISO 14971)", "", "Companion"], ["Data protection impact assessment (DPIA)", "", "Companion"], ["Predetermined change control plan (PCCP), if applicable", "", "Companion"], ["Model card(s) and dataset datasheet(s)", "", "Appendix / companion"]], [4200, 2500, 2660]),
  spacer(),
  h2("0.5 Glossary and acronyms"),
  guide("A shared vocabulary avoids costly misunderstandings between clinicians, bioinformaticians, ML engineers and regulators. Extend the list in Appendix A."),
  placeholder("Key terms specific to this product (e.g., ‘case’, ‘episode’, ‘variant call’, ‘cohort’) with precise definitions"),
  pageBreak()
);

// 1 Executive summary
children.push(
  h1("1. Executive Summary"),
  guide("One page maximum. A reader who stops here should understand what the product is, who it is for, why now, what it will not do, and what the key risks are."),
  h2("1.1 Product in one paragraph"),
  placeholder("What the product is, the AI capability at its core, the user, the setting, and the outcome it improves"),
  h2("1.2 Problem and opportunity"),
  placeholder("The unmet clinical, scientific or operational need and its magnitude (cite primary sources for any figures)"),
  h2("1.3 Proposed solution and key differentiators"),
  placeholder("Why this approach; what is novel or superior versus standard of care / existing tools"),
  h2("1.4 Target release and milestones"),
  placeholder("Key dates: prototype, internal validation, external validation, regulatory submission (if any), pilot, GA"),
  h2("1.5 Top risks and open questions"),
  placeholder("3–5 items, each with an owner"),
  h2("1.6 Decision requested"),
  placeholder("What the reader is being asked to approve (scope, budget, go/no-go gate)"),
  pageBreak()
);

// 2 Problem
children.push(
  h1("2. Problem Statement and Context"),
  h2("2.1 Current state and unmet need"),
  guide("Describe how the task is done today (standard of care, current pipeline, manual review), its failure modes, and who bears the cost. Distinguish evidence from assumption."),
  placeholder("Current workflow description"),
  placeholder("Evidence of the problem: outcomes data, error rates, turnaround times, cost, workforce shortages — with sources"),
  h2("2.2 Root-cause and jobs-to-be-done analysis"),
  placeholder("What job is the user hiring this product to do? What is the underlying cause of the current gap?"),
  h2("2.3 Why AI, and why now"),
  guide("Be explicit about why an AI/ML approach is justified over rule-based or non-software solutions. Reviewers and regulators will ask. Note enabling factors: data availability, compute, new foundation models, policy changes."),
  placeholder("Justification for an AI-based approach; alternatives considered and rejected"),
  h2("2.4 Landscape and prior art"),
  table(["Solution / competitor", "Type (SaMD, research tool, service…)", "Regulatory status", "Strengths", "Gaps our product addresses"], [["", "", "", "", ""], ["", "", "", "", ""], ["", "", "", "", ""]], [2000, 1900, 1500, 1980, 1980]),
  spacer(),
  guide("Include published models and open-source tools, not only commercial products. Cite peer-reviewed validation where it exists; note when a competitor claims performance without published evidence."),
  h2("2.5 Strategic fit"),
  placeholder("Alignment with organisational strategy, research programme, or portfolio; dependencies on other products"),
  pageBreak()
);

// 3 Vision & goals
children.push(
  h1("3. Vision, Goals and Non-Goals"),
  h2("3.1 Vision statement"),
  placeholder("Aspirational one-to-two sentence statement"),
  h2("3.2 Goals and measurable objectives"),
  guide("Use outcome-oriented objectives with a baseline, a target and a measurement method. Separate clinical/scientific outcomes from operational and business outcomes."),
  table(["Objective", "Type (clinical / scientific / operational / business)", "Baseline", "Target", "Measurement method", "Timeframe"], [["", "", "", "", "", ""], ["", "", "", "", "", ""], ["", "", "", "", "", ""]], [2200, 1700, 1100, 1100, 2000, 1260]),
  spacer(),
  h2("3.3 Non-goals and explicit exclusions"),
  guide("Non-goals are as important as goals in health AI: they bound the intended use, prevent scope creep into higher-risk claims, and are what a regulator will hold you to. Examples: 'This product does not provide a diagnosis'; 'Not intended for paediatric patients'; 'Not intended for germline variant interpretation'."),
  bullet("[Non-goal 1]"),
  bullet("[Non-goal 2]"),
  bullet("[Non-goal 3]"),
  h2("3.4 Guiding principles and design tenets"),
  placeholder("E.g., clinician-in-the-loop by default; no black-box outputs without uncertainty; reproducibility over novelty; privacy by design"),
  pageBreak()
);

// 4 Users & stakeholders
children.push(
  h1("4. Users, Stakeholders and Personas"),
  h2("4.1 Primary and secondary users"),
  table(["User group", "Primary / secondary", "Setting", "Expertise level", "Key needs", "Pain points"], [["e.g., Clinical pathologist", "Primary", "Hospital lab", "Domain expert, low ML literacy", "", ""], ["e.g., Bioinformatician", "Primary", "Core facility / research lab", "High computational literacy", "", ""], ["e.g., Bench scientist / medicinal chemist", "", "", "", "", ""], ["e.g., Patient / study participant", "Secondary / affected party", "", "", "", ""], ["e.g., Hospital IT / lab informatics", "Secondary", "", "", "", ""]], [1800, 1200, 1500, 1500, 1680, 1680]),
  spacer(),
  h2("4.2 Personas"),
  guide("Write 2–4 personas. For each: role, goals, a typical day, tools used, decision authority, what would make them distrust the product, and accessibility needs. Base personas on real user research; note the number of interviews or observations behind each."),
  placeholder("Persona 1"),
  placeholder("Persona 2"),
  h2("4.3 Stakeholder map"),
  table(["Stakeholder", "Interest / influence", "What they need from the product", "Engagement plan"], [["Regulators (e.g., FDA, EMA/notified body, BPOM/Kemenkes, MHRA)", "", "", ""], ["Payers / insurers / reimbursement bodies", "", "", ""], ["Ethics committee / IRB", "", "", ""], ["Data providers / biobanks / consortia", "", "", ""], ["Clinical champions and department heads", "", "", ""], ["Patient advocacy groups", "", "", ""], ["Hospital IT, security and procurement", "", "", ""], ["Academic collaborators / publication partners", "", "", ""]], [3000, 1600, 2860, 1900]),
  spacer(),
  h2("4.4 Affected non-users"),
  guide("Health AI affects people who never touch the interface: patients whose data trained the model, populations excluded from training data, staff whose work is reallocated. Name them and how their interests are protected."),
  placeholder("Affected groups and mitigations"),
  pageBreak()
);

// 5 Intended use, use cases
children.push(
  h1("5. Intended Use, Use Cases and User Stories"),
  h2("5.1 Intended use / indications for use statement"),
  guide("This is the single most important paragraph for any product that may be a medical device. It drives risk classification, the evidence required, and marketing claims. State: what the product does, for whom (patient population), in what setting, by which user, for what clinical or scientific purpose, and how the output is meant to be used (e.g., ‘to inform, not replace, clinician judgement’). Keep research-use-only (RUO) and clinical claims strictly separate."),
  placeholder("Intended use statement"),
  placeholder("Indications for use (patient population, disease/condition, specimen/data type, care setting)"),
  placeholder("Contraindications, limitations and populations in which the product has not been validated"),
  h2("5.2 Clinical / scientific workflow integration"),
  guide("Describe the before/after workflow. Where exactly does the AI output enter the decision process? What does the user do with it? What happens when the model abstains or fails?"),
  placeholder("As-is workflow"),
  placeholder("To-be workflow with the product embedded"),
  placeholder("Decision points, human oversight points and escalation paths"),
  h2("5.3 Use cases"),
  table(["ID", "Use case", "Actor", "Trigger", "Main flow (summary)", "Success outcome", "Alternative / failure flows"], [["UC-01", "", "", "", "", "", ""], ["UC-02", "", "", "", "", "", ""], ["UC-03", "", "", "", "", "", ""]], [800, 1500, 1100, 1200, 1900, 1400, 1460]),
  spacer(),
  h2("5.4 User stories"),
  guide("Format: As a [user], I want [capability] so that [outcome]. Each story must have testable acceptance criteria (Given / When / Then)."),
  table(["ID", "User story", "Acceptance criteria", "Priority", "Linked requirement(s)"], [["US-01", "", "", "", ""], ["US-02", "", "", "", ""], ["US-03", "", "", "", ""]], [900, 3200, 3000, 1000, 1260]),
  spacer(),
  h2("5.5 Out-of-scope use cases and foreseeable misuse"),
  guide("List plausible ways the product could be used outside its intended use (e.g., a triage tool used as a diagnostic; a research-only variant predictor used to return results to patients) and the controls that prevent or detect this."),
  placeholder("Foreseeable misuse scenarios and controls"),
  pageBreak()
);

// 6 Scope
children.push(
  h1("6. Scope, Assumptions, Constraints and Dependencies"),
  h2("6.1 In scope (this release)"),
  bullet("[Capability 1]"),
  bullet("[Capability 2]"),
  h2("6.2 Out of scope (this release) and future roadmap candidates"),
  bullet("[Deferred capability, with reason and target release]"),
  h2("6.3 Assumptions"),
  guide("Each assumption should have an owner and a plan to validate it. Health AI projects commonly fail on unvalidated data-access and integration assumptions."),
  table(["ID", "Assumption", "Impact if false", "Validation approach", "Owner", "Status"], [["A-01", "e.g., Retrospective access to N de-identified cases is approved by month 3", "", "", "", ""], ["A-02", "e.g., Site EHR exposes FHIR R4 endpoints", "", "", "", ""], ["A-03", "", "", "", "", ""]], [800, 2900, 1700, 1800, 1100, 1060]),
  spacer(),
  h2("6.4 Constraints"),
  table(["Category", "Constraint"], [["Regulatory", ""], ["Data access / consent", ""], ["Budget and timeline", ""], ["Compute / infrastructure (e.g., on-premise only, GPU availability)", ""], ["Data residency / sovereignty", ""], ["Interoperability with legacy systems", ""], ["Staffing and expertise", ""]], [3500, 5860]),
  spacer(),
  h2("6.5 Dependencies"),
  table(["Dependency", "Type (internal / external / vendor)", "Owner", "Needed by", "Risk if late"], [["", "", "", "", ""], ["", "", "", "", ""]], [2600, 1900, 1500, 1500, 1860]),
  pageBreak()
);

// 7 Functional requirements
children.push(
  h1("7. Functional Requirements"),
  guide("Every requirement must be unique, unambiguous, testable and traceable. Use ‘shall’ for mandatory requirements. Group by feature area. Each requirement is later traced to a design element, a test case and (for regulated products) a risk control — see Appendix D for the traceability matrix."),
  h2("7.1 Data ingestion and input handling"),
  reqTable("FR-ING", [["The system shall accept [data types, e.g., FASTQ/BAM/VCF, DICOM, HL7 FHIR resources, CSV clinical extracts] via [interfaces]", "Must", "", ""], ["The system shall validate inputs against [schema/standard] and reject or flag non-conforming inputs with a human-readable reason", "Must", "", ""], ["The system shall detect and handle missing, duplicate and out-of-range values according to [policy]", "Should", "", ""]]),
  spacer(),
  h2("7.2 Core AI/ML inference and analysis"),
  reqTable("FR-INF", [["The system shall produce [output type] for each [unit of analysis] within [time]", "Must", "", ""], ["The system shall attach a calibrated confidence/uncertainty estimate to each output", "Must", "", ""], ["The system shall abstain / route to human review when [conditions, e.g., out-of-distribution input, low confidence]", "Must", "", ""]]),
  spacer(),
  h2("7.3 Results presentation, explainability and reporting"),
  reqTable("FR-OUT", [["The system shall present outputs with the intended-use statement, limitations and model version visible to the user", "Must", "", ""], ["The system shall provide [explanation type, e.g., feature attribution, evidence highlighting, retrieved sources] for each output", "Should", "", ""], ["The system shall generate exportable reports in [format] conforming to [reporting standard]", "Should", "", ""]]),
  spacer(),
  h2("7.4 Human-in-the-loop, review and override"),
  reqTable("FR-HIL", [["Users with [role] shall be able to accept, modify or reject any AI output, and the system shall record the action and rationale", "Must", "", ""], ["The system shall never auto-execute [clinically consequential action] without explicit user confirmation", "Must", "", ""]]),
  spacer(),
  h2("7.5 User, role and access management"),
  reqTable("FR-IAM", [["The system shall enforce role-based access control with least privilege for [roles]", "Must", "", ""], ["The system shall integrate with institutional SSO / identity provider ([protocol])", "Should", "", ""]]),
  spacer(),
  h2("7.6 Audit trail and provenance"),
  reqTable("FR-AUD", [["The system shall maintain an immutable, time-stamped audit log of inputs, model version, parameters, outputs and user actions for every analysis", "Must", "", ""], ["The system shall record full data and software provenance sufficient to reproduce any result (e.g., container digest, workflow version, reference genome build, random seeds)", "Must", "", ""]]),
  spacer(),
  h2("7.7 Integration and interoperability"),
  reqTable("FR-INT", [["The system shall exchange data with [EHR / LIS / PACS / LIMS / ELN] using [HL7 FHIR R4 / HL7 v2 / DICOM / OMOP CDM / GA4GH APIs]", "Must", "", ""], ["The system shall use standard terminologies ([SNOMED CT, LOINC, ICD-10/11, HGNC, HGVS, HPO, ATC]) for coded fields", "Should", "", ""]]),
  spacer(),
  h2("7.8 Administration, configuration and monitoring"),
  reqTable("FR-ADM", [["Administrators shall be able to configure [thresholds, site-specific settings] within validated bounds without code changes", "Should", "", ""], ["The system shall expose operational and model-performance metrics to the monitoring stack (Section 17)", "Must", "", ""]]),
  spacer(),
  h2("7.9 Feedback and incident reporting"),
  reqTable("FR-FBK", [["Users shall be able to report a suspected erroneous output or safety concern in ≤ [N] clicks; reports shall be routed to [owner] within [time]", "Must", "", ""]]),
  pageBreak()
);

// 8 AI/ML requirements
children.push(
  h1("8. AI / ML Model Requirements"),
  guide("This section is what distinguishes a health-AI PRD from a generic software PRD. Complete one sub-section per model or model component if the product uses several (e.g., a segmentation model plus an LLM summariser)."),
  h2("8.1 Model overview"),
  table(["Attribute", "Specification"], [["Model / component name and version", ""], ["ML task type (classification, regression, segmentation, detection, ranking, generation, retrieval, structure prediction, etc.)", ""], ["Learning paradigm (supervised, self-supervised, RL, foundation model fine-tuning, RAG, rules + ML hybrid)", ""], ["Architecture family", ""], ["Locked vs. adaptive / continuously learning (and if adaptive, the change-control approach — see 12.4 and 17.4)", ""], ["Inputs (modalities, resolution, formats, pre-processing)", ""], ["Outputs (type, format, units, ranges, categories)", ""], ["Operating point(s) and how they are chosen", ""], ["Third-party / open-source models used, licences and provenance", ""]], [3800, 5560]),
  spacer(),
  h2("8.2 Performance requirements and acceptance criteria"),
  guide("Define the primary metric and minimum acceptable performance before training, with justification tied to clinical or scientific consequence (e.g., a screening tool prioritises sensitivity; a research prioritisation tool may prioritise precision at k). Always report confidence intervals and compare to a pre-specified baseline (standard of care, existing tool, or clinician performance)."),
  table(["Metric", "Why it matters for this use", "Minimum acceptable", "Target", "Baseline / comparator", "Evaluation dataset"], [["Primary: e.g., sensitivity at fixed specificity", "", "", "", "", ""], ["Secondary: e.g., AUROC / AUPRC", "", "", "", "", ""], ["Calibration (e.g., ECE, calibration slope)", "", "", "", "", ""], ["Positive / negative predictive value at expected prevalence", "", "", "", "", ""], ["Segmentation / localisation (e.g., Dice, IoU)", "", "", "", "", ""], ["Generation quality (e.g., factuality, groundedness, harmful-output rate)", "", "", "", "", ""], ["Latency / throughput", "", "", "", "", ""], ["Robustness (site, scanner, batch, ancestry shift)", "", "", "", "", ""]], [2300, 1700, 1200, 1000, 1500, 1660]),
  spacer(),
  h2("8.3 Subgroup and fairness requirements"),
  guide("Pre-specify subgroups (sex, age band, ancestry/ethnicity, site, device/assay, disease stage, comorbidity, socio-economic proxies where lawful) and the maximum acceptable performance gap. State how subgroups with insufficient sample size will be handled and disclosed."),
  table(["Subgroup", "Rationale", "Minimum n in test set", "Max acceptable gap vs. overall", "Mitigation if gap exceeded"], [["", "", "", "", ""], ["", "", "", "", ""], ["", "", "", "", ""]], [1900, 2200, 1500, 1800, 1960]),
  spacer(),
  h2("8.4 Uncertainty, abstention and out-of-distribution handling"),
  placeholder("How uncertainty is quantified (e.g., ensembles, conformal prediction, MC dropout); abstention rules; OOD detection method; expected abstention rate and its workflow impact"),
  h2("8.5 Explainability and interpretability"),
  placeholder("Explanation methods, their intended audience, known limitations (e.g., saliency maps are not causal), and how explanations are validated with users"),
  h2("8.6 Requirements specific to LLM / generative components"),
  guide("Complete if the product uses an LLM, multimodal foundation model or other generative component, including for summarisation, chat, report drafting, literature retrieval or code generation."),
  table(["Topic", "Requirement / specification"], [["Base model, version pinning and provider (self-hosted vs. API); data-use terms of the provider", ""], ["Grounding strategy (RAG over curated corpus, tool use, citations); required source-attribution behaviour", ""], ["Hallucination / factuality evaluation method and acceptable rate; clinical fact-checking protocol", ""], ["Prompt-injection, jailbreak and data-exfiltration defences", ""], ["Refusal and safe-completion behaviour for out-of-scope medical queries", ""], ["PHI/PII handling in prompts, context windows and logs (no PHI to third-party APIs unless a BAA/DPA is in place)", ""], ["Determinism / reproducibility settings and versioning of prompts, system messages and retrieval indexes", ""], ["Human review requirements before any generated content reaches a patient record or a publication", ""]], [4200, 5160]),
  spacer(),
  h2("8.7 Reproducibility and scientific rigour"),
  placeholder("Fixed seeds, containerised environments, workflow manager (e.g., Nextflow, Snakemake, WDL), pinned reference data (genome build, annotation release, ontology version), and how results are re-run for audit"),
  h2("8.8 Model documentation deliverables"),
  bullet("Model card (Appendix B) for every deployed model version"),
  bullet("Dataset datasheet (Appendix C) for every training, tuning and test dataset"),
  bullet("Evaluation report with pre-registered analysis plan and full subgroup results"),
  bullet("Known-limitations and failure-mode register"),
  pageBreak()
);

// 9 Data
children.push(
  h1("9. Data Requirements and Governance"),
  h2("9.1 Data inventory"),
  table(["Dataset", "Purpose (train / tune / test / external validation / reference)", "Source & custodian", "Modality & format", "n (patients / samples / images / sequences)", "Consent & lawful basis", "Agreement (DUA / MTA / DTA)"], [["", "", "", "", "", "", ""], ["", "", "", "", "", "", ""], ["", "", "", "", "", "", ""]], [1400, 1500, 1400, 1200, 1300, 1300, 1260]),
  spacer(),
  h2("9.2 Representativeness and bias assessment"),
  guide("Compare the demographic, clinical, geographic and technical (site, device, assay, sequencing platform) distribution of the data with the intended-use population. Document gaps explicitly; they become labelling limitations."),
  placeholder("Comparison of dataset composition vs. intended-use population; identified gaps; mitigation (additional data, weighting, restricted claims)"),
  h2("9.3 Ground truth / reference standard and labelling"),
  table(["Item", "Specification"], [["Definition of the reference standard (e.g., histopathology, orthogonal assay, adjudicated clinical outcome, expert consensus)", ""], ["Annotator qualifications, number, training and blinding", ""], ["Inter-/intra-rater agreement targets and adjudication process", ""], ["Labelling protocol version and tooling", ""], ["Known limitations of the reference standard", ""]], [4200, 5160]),
  spacer(),
  h2("9.4 Data quality requirements"),
  placeholder("Completeness, accuracy, timeliness and consistency thresholds; QC pipeline (e.g., FastQC/MultiQC for sequencing, image QC, EHR extract validation); handling of duplicates and leakage between train and test (patient-level splits)"),
  h2("9.5 De-identification, pseudonymisation and privacy-enhancing technologies"),
  placeholder("Method (e.g., HIPAA Safe Harbor / Expert Determination, GDPR pseudonymisation, k-anonymity), genomic-data re-identification risk assessment, use of federated learning, differential privacy or synthetic data where applicable"),
  h2("9.6 Data lineage, versioning and retention"),
  placeholder("Data versioning tool, lineage tracking from raw to model-ready, retention and deletion schedule, handling of consent withdrawal"),
  h2("9.7 Data access, sharing and publication"),
  placeholder("Access-control model, controlled-access repository policy, open-data commitments (e.g., deposition to ENA/SRA/GEO/dbGaP/EGA where permitted), embargoes"),
  pageBreak()
);

// 10 Validation & evidence
children.push(
  h1("10. Clinical and Scientific Validation Plan"),
  guide("Match the evidence to the claim and the risk. A three-tier framing is widely used: (1) valid scientific/clinical association between the output and the target condition; (2) analytical validation — the software correctly and reliably processes inputs to outputs; (3) clinical validation — the output achieves the intended purpose in the target population in real use. Pre-register analysis plans wherever feasible."),
  h2("10.1 Evidence strategy overview"),
  table(["Validation tier", "Question answered", "Study type", "Dataset / site(s)", "Primary endpoint", "Status / timeline"], [["Scientific validity", "", "Literature review / mechanistic evidence", "", "", ""], ["Analytical validation", "", "Retrospective, held-out & external test sets; software verification", "", "", ""], ["Clinical validation (retrospective)", "", "Multi-site retrospective, reader study, silent deployment", "", "", ""], ["Clinical validation (prospective)", "", "Prospective cohort / RCT / pragmatic trial", "", "", ""], ["Usability / human factors", "", "Formative and summative usability testing", "", "", ""], ["Real-world performance", "", "Post-market surveillance", "", "", ""]], [1700, 1700, 1900, 1400, 1400, 1260]),
  spacer(),
  h2("10.2 Study design details (per study)"),
  placeholder("Objectives; design; population and eligibility; sample-size justification with power calculation; endpoints; comparator; blinding; statistical analysis plan; handling of missing data; pre-registration ID"),
  h2("10.3 External and multi-site validation"),
  placeholder("Number and diversity of external sites; temporal validation; sequencing-platform / scanner / assay diversity"),
  h2("10.4 Reporting guidelines to follow"),
  guide("Select those applicable and confirm the current version with the EQUATOR Network or the guideline's publication. Examples: TRIPOD+AI (prediction models), CONSORT-AI and SPIRIT-AI (trials and protocols involving AI interventions), DECIDE-AI (early-stage clinical evaluation), STARD-AI (diagnostic accuracy; verify publication status), CLAIM (medical imaging AI), MI-CLAIM (minimum information about clinical AI modelling), MINSEQE / MIAME-type minimum-information standards for omics, and PRISMA for any systematic reviews used as evidence."),
  placeholder("Guidelines selected and rationale"),
  h2("10.5 Ethics, consent and oversight"),
  placeholder("IRB / ethics committee approvals (reference numbers), consent model, data-monitoring committee if applicable, plan for returning or not returning results to participants"),
  h2("10.6 Publication and disclosure plan"),
  placeholder("Planned peer-reviewed publications, preprints, code and model release policy, conflict-of-interest disclosure"),
  pageBreak()
);

// 11 Regulatory
children.push(
  h1("11. Regulatory and Compliance Requirements"),
  guide("Confirm every item with Regulatory Affairs and counsel. Regulatory pathways for AI in health are changing quickly; the frameworks named here are starting points, not conclusions. Record the date each determination was made."),
  h2("11.1 Product classification determination"),
  table(["Question", "Determination", "Rationale / reference", "Date & decider"], [["Is the product a medical device / IVD / SaMD in each target market? (e.g., FDA 21 CFR device definition and CDS criteria; EU MDR 2017/745 or IVDR 2017/746 qualification and Rule 11; local ministry-of-health rules)", "", "", ""], ["Risk class per market (e.g., FDA Class I/II/III; EU Class I/IIa/IIb/III; IMDRF SaMD categories)", "", "", ""], ["Is it a ‘high-risk AI system’ under the EU AI Act (Regulation (EU) 2024/1689) and what obligations and timelines follow?", "", "", ""], ["Research-use-only (RUO) / investigational-use status and labelling", "", "", ""], ["Applicable GxP scope if used in drug development (GLP / GCP / GMP; 21 CFR Part 11 and EU Annex 11 for electronic records)", "", "", ""]], [3800, 1500, 2400, 1660]),
  spacer(),
  h2("11.2 Regulatory strategy per market"),
  table(["Market", "Authority", "Pathway (e.g., 510(k), De Novo, PMA; CE marking via notified body; national registration)", "Predicate / reference device", "Predetermined change control plan (PCCP) planned?", "Target submission date"], [["United States", "FDA", "", "", "", ""], ["European Union", "Notified body / competent authority", "", "", "", ""], ["Indonesia", "Kemenkes / BPOM (verify current AI-in-health guidance)", "", "", "", ""], ["[Other]", "", "", "", "", ""]], [1300, 1700, 2200, 1500, 1500, 1160]),
  spacer(),
  h2("11.3 Standards and quality management"),
  guide("Tick applicable standards and record the edition used. Common set for health software and AI: ISO 13485 (QMS), ISO 14971 (risk management), IEC 62304 (software life cycle), IEC 62366-1 (usability engineering), IEC 82304-1 (health software), ISO 14155 (clinical investigations), ISO/IEC 42001 (AI management system), ISO/IEC 23894 (AI risk management), ISO/IEC 27001 and 27701 (information security and privacy), IEC 81001-5-1 (health software security). Also consider FDA/Health Canada/MHRA Good Machine Learning Practice (GMLP) guiding principles and related transparency principles."),
  table(["Standard / guidance", "Applicable?", "Edition / year", "Evidence of conformance"], [["", "", "", ""], ["", "", "", ""], ["", "", "", ""], ["", "", "", ""]], [3600, 1200, 1500, 3060]),
  spacer(),
  h2("11.4 Privacy and data-protection obligations"),
  table(["Jurisdiction / regime", "Applies?", "Key obligations for this product", "Artefacts (DPIA, BAA, DPA, records of processing)"], [["HIPAA (US)", "", "", ""], ["GDPR (EU/EEA), incl. Article 9 special-category health and genetic data", "", "", ""], ["Indonesia Personal Data Protection Law (UU No. 27/2022) and health-data rules", "", "", ""], ["Genomic-data-specific rules (e.g., GINA in the US; national biobank laws)", "", "", ""], ["[Other national / state laws]", "", "", ""]], [3000, 1000, 2900, 2460]),
  spacer(),
  h2("11.5 Labelling, claims and transparency"),
  placeholder("Required labelling content (intended use, limitations, training-data summary, performance, model version); marketing-claim review process; user-facing transparency statements; AI-Act-style transparency obligations where applicable"),
  h2("11.6 Post-market surveillance and vigilance"),
  placeholder("Complaint handling, adverse-event / malfunction reporting timelines, periodic safety update reports, real-world performance monitoring feeding into Section 17"),
  pageBreak()
);

// 12 Risk & ethics
children.push(
  h1("12. Safety, Risk Management and Ethics"),
  h2("12.1 Hazard analysis and risk register"),
  guide("Use the ISO 14971 structure: hazard → hazardous situation → harm → severity × probability → risk control → residual risk. Include AI-specific hazards: silent performance degradation, automation bias, over-reliance, mis-calibration, adversarial inputs, data-shift, spurious correlations, hallucinated citations."),
  table(["ID", "Hazard", "Hazardous situation", "Potential harm", "Sev.", "Prob.", "Risk control(s)", "Residual risk", "Verif."], [["R-01", "", "", "", "", "", "", "", ""], ["R-02", "", "", "", "", "", "", "", ""], ["R-03", "", "", "", "", "", "", "", ""]], [700, 1300, 1400, 1200, 700, 700, 1500, 1000, 860]),
  spacer(),
  h2("12.2 Safety case summary"),
  placeholder("Top-level safety claim, argument and evidence; safety-assurance approach; who signs the safety case"),
  h2("12.3 Human oversight and automation-bias controls"),
  placeholder("Oversight model (human-in-the-loop / on-the-loop / in-command); UI measures to reduce automation bias; training requirements for users; periodic competency checks"),
  h2("12.4 Change management for adaptive or updated models"),
  placeholder("What model changes are permitted without new validation; re-validation triggers; regulatory notification thresholds; rollback plan"),
  h2("12.5 Ethical impact assessment"),
  table(["Principle", "Considerations for this product", "Controls / evidence"], [["Beneficence and non-maleficence", "", ""], ["Justice and equity (fair performance and access across populations)", "", ""], ["Autonomy and informed consent (patients and users)", "", ""], ["Transparency and contestability of AI outputs", "", ""], ["Accountability (who is responsible when the AI is wrong)", "", ""], ["Environmental impact of training and inference (compute footprint)", "", ""], ["Dual-use and misuse potential (e.g., genomic re-identification, biosecurity-relevant capabilities)", "", ""]], [3300, 3200, 2860]),
  spacer(),
  h2("12.6 Incident response for AI-related harm"),
  placeholder("Detection, triage, containment (e.g., kill switch / feature flag), user and regulator notification, root-cause analysis, corrective and preventive actions (CAPA)"),
  pageBreak()
);

// 13 Security & privacy
children.push(
  h1("13. Security and Privacy Requirements"),
  h2("13.1 Threat model"),
  placeholder("Assets (PHI, genomic data, model weights, training data), threat actors, attack surfaces, trust boundaries; include AI-specific threats such as model inversion, membership inference, data poisoning, adversarial examples and prompt injection"),
  h2("13.2 Security requirements"),
  reqTable("NFR-SEC", [["All PHI/PII and genomic data shall be encrypted in transit ([TLS version]) and at rest ([algorithm]); keys managed via [KMS/HSM]", "Must", "", ""], ["Access shall be authenticated via [SSO/MFA] and authorised by role; all access to identifiable data shall be logged and reviewable", "Must", "", ""], ["The system shall undergo [SAST/DAST, dependency scanning, penetration testing] before each major release; critical findings block release", "Must", "", ""], ["Model artefacts and training data shall be integrity-protected (signed, hashed) and stored with restricted access", "Must", "", ""], ["A software bill of materials (SBOM) shall be maintained for every release", "Should", "", ""], ["Vulnerability disclosure and patching SLA: [timeframes by severity]", "Must", "", ""]]),
  spacer(),
  h2("13.3 Privacy requirements"),
  reqTable("NFR-PRV", [["Data minimisation: only fields listed in [data specification] shall be collected or processed", "Must", "", ""], ["The system shall support data-subject rights workflows (access, rectification, erasure/withdrawal) within [timeframe] where legally required", "Must", "", ""], ["No identifiable data shall leave [jurisdiction / approved environment]; third-party AI APIs shall not receive PHI without an executed BAA/DPA and documented approval", "Must", "", ""], ["Privacy-enhancing technologies used: [federated learning, DP, secure enclaves, synthetic data] with documented utility/privacy trade-offs", "Could", "", ""]]),
  spacer(),
  h2("13.4 Business continuity and disaster recovery"),
  placeholder("RPO/RTO targets, backup strategy, failover, degraded-mode operation (what clinicians do when the AI is unavailable)"),
  pageBreak()
);

// 14 NFRs
children.push(
  h1("14. Non-Functional Requirements"),
  h2("14.1 Performance and scalability"),
  reqTable("NFR-PERF", [["End-to-end turnaround for [unit of work] shall be ≤ [time] at the 95th percentile under [load]", "Must", "", ""], ["The system shall scale to [N concurrent users / samples per day / genomes per week] without degradation beyond [threshold]", "Must", "", ""], ["Batch/pipeline jobs shall be resumable and idempotent", "Should", "", ""]]),
  spacer(),
  h2("14.2 Availability and reliability"),
  reqTable("NFR-AVL", [["Service availability shall be ≥ [99.x]% measured monthly, excluding announced maintenance", "Must", "", ""], ["Mean time to recovery for Sev-1 incidents shall be ≤ [time]", "Should", "", ""]]),
  spacer(),
  h2("14.3 Interoperability and standards"),
  reqTable("NFR-INT", [["Data exchange shall conform to [HL7 FHIR R4 profiles / IHE profiles / DICOM SR / OMOP CDM v5.x / GA4GH htsget, Beacon, Phenopackets]", "Must", "", ""], ["Outputs shall be machine-readable and semantically coded using [terminologies]", "Should", "", ""]]),
  spacer(),
  h2("14.4 Usability and accessibility"),
  reqTable("NFR-USE", [["Summative usability testing shall show [X]% task completion with no critical use errors for [critical tasks]", "Must", "", ""], ["The UI shall conform to WCAG [2.x] level [AA]", "Should", "", ""], ["Localisation: [languages]; units and date formats per locale", "Could", "", ""]]),
  spacer(),
  h2("14.5 Maintainability, portability and deployment"),
  reqTable("NFR-MNT", [["The system shall be deployable on [cloud / on-premise / air-gapped / hybrid] with infrastructure defined as code", "Must", "", ""], ["All components shall be containerised with pinned, reproducible builds", "Must", "", ""], ["Test coverage for safety-relevant code paths shall be ≥ [X]%", "Should", "", ""]]),
  spacer(),
  h2("14.6 Data residency, retention and archival"),
  reqTable("NFR-DAT", [["Data shall reside in [regions]; cross-border transfer only under [mechanism]", "Must", "", ""], ["Records shall be retained for [period] per [regulation]; then securely destroyed", "Must", "", ""]]),
  spacer(),
  h2("14.7 Cost and sustainability"),
  placeholder("Target cost per analysis / per user; compute budget for training and inference; energy and carbon reporting if required"),
  pageBreak()
);

// 15 Architecture
children.push(
  h1("15. Technical Architecture Overview"),
  guide("Keep this at a level a non-engineer can follow; detailed design belongs in the architecture and software design documents. Include a diagram."),
  h2("15.1 System context and high-level architecture"),
  placeholder("Context diagram: users, external systems (EHR, LIS, PACS, LIMS, sequencers, cloud services), the product boundary, and data flows with classification (PHI / de-identified / public)"),
  h2("15.2 Component overview"),
  table(["Component", "Responsibility", "Technology (proposed)", "Owner", "Safety-relevant?"], [["Ingestion & validation", "", "", "", ""], ["Pre-processing / bioinformatics pipeline", "", "", "", ""], ["Model serving / inference", "", "", "", ""], ["Orchestration & workflow engine", "", "", "", ""], ["Results store & API", "", "", "", ""], ["User interface", "", "", "", ""], ["Monitoring & audit", "", "", "", ""], ["Identity & access", "", "", "", ""]], [2300, 2400, 2000, 1300, 1360]),
  spacer(),
  h2("15.3 Deployment topology and environments"),
  placeholder("Dev / test / validation / production environments; on-premise vs. cloud; GPU requirements; edge deployment if applicable; network segmentation"),
  h2("15.4 Data flow and storage"),
  placeholder("Where each class of data is stored, for how long, with what encryption and access; separation of identifiable and de-identified zones"),
  h2("15.5 Software development life cycle and quality practices"),
  placeholder("SDLC model aligned with IEC 62304 (if applicable), code review, CI/CD, test strategy (unit, integration, system, regression, performance), configuration management, documented release procedure"),
  h2("15.6 Technical debt and known limitations"),
  placeholder("Accepted shortcuts and their planned remediation"),
  pageBreak()
);

// 16 UX
children.push(
  h1("16. User Experience and Human-Factors Requirements"),
  h2("16.1 UX principles for this product"),
  bullet("Show the AI's confidence and limitations at the point of decision, not buried in documentation"),
  bullet("Make disagreement with the AI as easy as agreement; never add friction to override"),
  bullet("Clearly distinguish AI-generated content from human-authored and source data"),
  bullet("Fail visibly and safely: never present a silent fallback as a normal result"),
  bullet("[Add product-specific principles]"),
  h2("16.2 Key screens, flows and information architecture"),
  placeholder("Wireframe references; critical-task flows; error and empty states; what the user sees when the model abstains or the service is degraded"),
  h2("16.3 Human-factors and usability engineering plan"),
  placeholder("Use-related risk analysis; critical tasks; formative studies (n, participants, method); summative study design; alignment with IEC 62366-1 if a medical device"),
  h2("16.4 Training, onboarding and documentation"),
  placeholder("User training requirements before access is granted; in-product guidance; instructions for use (IFU) contents; competency assessment"),
  h2("16.5 Accessibility and inclusivity"),
  placeholder("WCAG target, assistive-technology support, language and health-literacy considerations for any patient-facing element"),
  pageBreak()
);

// 17 MLOps
children.push(
  h1("17. Model Lifecycle, MLOps and Post-Deployment Monitoring"),
  h2("17.1 Lifecycle stages and gates"),
  table(["Stage", "Entry criteria", "Key activities", "Exit criteria / gate", "Approver"], [["Data readiness", "", "", "", ""], ["Model development & internal validation", "", "", "", ""], ["Independent / external validation", "", "", "", ""], ["Verification & validation (software)", "", "", "", ""], ["Regulatory submission / approval (if applicable)", "", "", "", ""], ["Silent / shadow deployment", "", "", "", ""], ["Limited release / pilot", "", "", "", ""], ["General availability", "", "", "", ""], ["Retirement", "", "", "", ""]], [2200, 1800, 2000, 1900, 1460]),
  spacer(),
  h2("17.2 Versioning and reproducibility"),
  placeholder("Versioning scheme for data, code, model weights, prompts, retrieval indexes and configuration; model registry; ability to reproduce any historical output"),
  h2("17.3 Monitoring requirements"),
  table(["Monitor", "Metric(s)", "Threshold / alert", "Frequency", "Owner", "Response"], [["Input data drift (covariate shift)", "", "", "", "", ""], ["Label / outcome drift and prevalence shift", "", "", "", "", ""], ["Model performance (with delayed ground truth)", "", "", "", "", ""], ["Subgroup performance", "", "", "", "", ""], ["Abstention / override rates", "", "", "", "", ""], ["Latency, errors, availability", "", "", "", "", ""], ["User feedback and reported incidents", "", "", "", "", ""], ["LLM-specific: hallucination, refusal, prompt-injection attempts", "", "", "", "", ""]], [2300, 1600, 1500, 1100, 1200, 1660]),
  spacer(),
  h2("17.4 Retraining and update policy"),
  placeholder("Triggers for retraining; data used; validation required before redeployment; PCCP alignment (if regulated); communication to users; rollback procedure"),
  h2("17.5 Model retirement and decommissioning"),
  placeholder("Criteria for retirement; data and record retention after retirement; migration of users"),
  pageBreak()
);

// 18 Metrics
children.push(
  h1("18. Success Metrics and KPIs"),
  guide("Separate leading indicators (adoption, usage) from lagging outcomes (clinical benefit, scientific output, revenue). Every KPI should have a baseline, target, data source and review cadence."),
  table(["Category", "KPI", "Baseline", "Target", "Data source", "Review cadence"], [["Clinical / scientific outcome", "e.g., time-to-diagnosis; diagnostic yield; hit-rate in screening; reduction in manual review time", "", "", "", ""], ["Model quality in production", "e.g., real-world sensitivity; calibration; subgroup gap", "", "", "", ""], ["Safety", "e.g., serious incidents per 10,000 analyses; override rate trend", "", "", "", ""], ["Adoption and engagement", "e.g., active sites, weekly active users, % of eligible cases analysed", "", "", "", ""], ["User trust and satisfaction", "e.g., SUS score; NPS; qualitative feedback themes", "", "", "", ""], ["Operational", "e.g., turnaround time; cost per analysis; uptime", "", "", "", ""], ["Business / academic", "e.g., revenue; contracts; publications; grants; citations", "", "", "", ""]], [1700, 3000, 1000, 1000, 1400, 1260]),
  pageBreak()
);

// 19 GTM
children.push(
  h1("19. Commercialisation, Adoption and Sustainability"),
  guide("For academic or internal products, replace commercial items with an adoption and sustainability plan (funding, maintenance, community)."),
  h2("19.1 Target segments and value proposition"),
  placeholder("Segments, buyer vs. user, value proposition per segment"),
  h2("19.2 Business model, pricing and reimbursement"),
  placeholder("Licensing / SaaS / per-analysis / grant-funded; reimbursement pathway and evidence payers require; health-economic evaluation plan (cost-effectiveness, budget impact)"),
  h2("19.3 Go-to-market and deployment model"),
  placeholder("Pilot sites, channel partners, implementation and integration services, support model and SLAs"),
  h2("19.4 Intellectual property and licensing"),
  placeholder("Patents, trade secrets, open-source licences of dependencies and their obligations, data licences, publication vs. IP timing"),
  h2("19.5 Sustainability and maintenance"),
  placeholder("Funding for ongoing validation, monitoring and updates; staffing; end-of-life obligations to users"),
  pageBreak()
);

// 20 Plan
children.push(
  h1("20. Release Plan, Milestones and Resourcing"),
  h2("20.1 Phased roadmap"),
  table(["Phase", "Scope", "Key deliverables", "Evidence / regulatory gate", "Target date", "Status"], [["0 — Discovery & feasibility", "", "", "", "", ""], ["1 — Prototype / MVP", "", "", "", "", ""], ["2 — Internal & external validation", "", "", "", "", ""], ["3 — Regulatory submission / ethics approvals", "", "", "", "", ""], ["4 — Pilot / limited release", "", "", "", "", ""], ["5 — General availability", "", "", "", "", ""], ["6 — Post-market / continuous improvement", "", "", "", "", ""]], [2200, 1700, 1700, 1600, 1100, 1060]),
  spacer(),
  h2("20.2 Team and roles (RACI)"),
  table(["Activity", "Product", "Clinical / Scientific", "ML / Data Science", "Engineering", "Regulatory / QA", "Security / Privacy"], [["Requirements definition", "", "", "", "", "", ""], ["Data acquisition & governance", "", "", "", "", "", ""], ["Model development", "", "", "", "", "", ""], ["Validation studies", "", "", "", "", "", ""], ["Risk management", "", "", "", "", "", ""], ["Release decision", "", "", "", "", "", ""]], [2400, 1100, 1300, 1300, 1200, 1100, 960]),
  spacer(),
  h2("20.3 Budget summary"),
  placeholder("Personnel, data acquisition, compute, validation studies, regulatory fees, infrastructure, contingency"),
  pageBreak()
);

// 21 Risks, questions, decisions
children.push(
  h1("21. Project Risks, Open Questions and Decision Log"),
  h2("21.1 Project and delivery risks"),
  guide("Distinct from patient-safety risks in Section 12: these are risks to delivering the product (data access, recruitment, key-person dependency, vendor lock-in, regulatory delay)."),
  table(["ID", "Risk", "Likelihood", "Impact", "Mitigation", "Owner", "Status"], [["PR-01", "", "", "", "", "", ""], ["PR-02", "", "", "", "", "", ""], ["PR-03", "", "", "", "", "", ""]], [800, 2700, 1000, 1000, 2000, 1000, 860]),
  spacer(),
  h2("21.2 Open questions"),
  table(["ID", "Question", "Why it matters", "Owner", "Needed by", "Resolution"], [["Q-01", "", "", "", "", ""], ["Q-02", "", "", "", "", ""]], [800, 2800, 2200, 1100, 1100, 1360]),
  spacer(),
  h2("21.3 Decision log"),
  table(["ID", "Date", "Decision", "Options considered", "Rationale", "Decider"], [["D-01", "", "", "", "", ""], ["D-02", "", "", "", "", ""]], [800, 1100, 2400, 2000, 2000, 1060]),
  pageBreak()
);

// Appendices
children.push(
  h1("Appendix A. Glossary"),
  table(["Term", "Definition"], [["SaMD", "Software as a Medical Device — software intended for medical purposes that performs these purposes without being part of a hardware medical device (IMDRF definition)"], ["PCCP", "Predetermined Change Control Plan — a pre-authorised plan describing anticipated model modifications and how they will be validated"], ["GMLP", "Good Machine Learning Practice — guiding principles jointly published by FDA, Health Canada and the UK MHRA"], ["Analytical validation", "Evidence that the software correctly and reliably generates the intended output from the input data"], ["Clinical validation", "Evidence that the output achieves the intended clinical purpose in the target population and setting"], ["Calibration", "Agreement between predicted probabilities and observed frequencies"], ["Drift", "Change over time in input data (covariate), outcome (label/prior) or the input–output relationship (concept) that degrades model performance"], ["RAG", "Retrieval-augmented generation — grounding an LLM's output in retrieved documents"], ["[Add product-specific terms]", ""]], [2400, 6960]),
  pageBreak(),

  h1("Appendix B. Model Card Template"),
  guide("Complete one per deployed model version and keep under version control alongside the model."),
  table(["Field", "Content"], [["Model name, version, date, owner", ""], ["Intended use and intended users", ""], ["Out-of-scope uses", ""], ["Architecture, size, training approach, base model (if any)", ""], ["Training data summary (source, size, period, demographics, labelling)", ""], ["Evaluation data summary (held-out, external, temporal)", ""], ["Performance: primary and secondary metrics with 95% CI", ""], ["Subgroup performance", ""], ["Calibration and uncertainty behaviour", ""], ["Known limitations and failure modes", ""], ["Ethical considerations and fairness assessment", ""], ["Environmental / compute footprint", ""], ["Caveats, recommendations and change history", ""]], [3800, 5560]),
  pageBreak(),

  h1("Appendix C. Dataset Datasheet Template"),
  table(["Field", "Content"], [["Dataset name, version, custodian, contact", ""], ["Motivation: why was it created and by whom", ""], ["Composition: instances, features, labels, missing data, sensitive attributes", ""], ["Collection process: how, by whom, over what period, with what instruments/assays/platforms", ""], ["Pre-processing, cleaning and labelling applied; raw data availability", ""], ["Consent, lawful basis, ethics approvals, de-identification method", ""], ["Recommended uses and known unsuitable uses", ""], ["Distribution: access mechanism, licence, agreements, restrictions", ""], ["Maintenance: update policy, versioning, erratum process", ""]], [3800, 5560]),
  pageBreak(),

  h1("Appendix D. Requirements Traceability Matrix"),
  guide("Maintain in a tool where possible; this table is the minimum view for reviewers."),
  table(["Requirement ID", "User story / use case", "Design element", "Risk control (Section 12)", "Test case(s)", "Verification result", "Validation evidence"], [["", "", "", "", "", "", ""], ["", "", "", "", "", "", ""], ["", "", "", "", "", "", ""]], [1400, 1400, 1300, 1400, 1300, 1300, 1260]),
  pageBreak(),

  h1("Appendix E. PRD Completeness Checklist"),
  guide("Use before requesting sign-off. Every ‘No’ needs a written justification."),
  table(["Check", "Yes / No / N/A", "Comment"], [["Intended use statement reviewed by clinical lead and regulatory affairs", "", ""], ["Non-goals and contraindicated populations explicitly listed", "", ""], ["Primary performance metric, minimum acceptable value and comparator pre-specified", "", ""], ["Subgroups and maximum acceptable performance gaps pre-specified", "", ""], ["Data inventory complete with lawful basis and agreements for every dataset", "", ""], ["Train/test leakage prevented by patient-level (or equivalent) splits", "", ""], ["Reference-standard definition and labeller qualifications documented", "", ""], ["External validation planned on at least one independent site / platform", "", ""], ["Reporting guideline(s) selected", "", ""], ["Device / AI-Act classification determination recorded with date", "", ""], ["Applicable standards listed with editions", "", ""], ["Hazard analysis includes AI-specific hazards", "", ""], ["Human oversight and override behaviour specified as requirements", "", ""], ["LLM-specific requirements completed (if applicable)", "", ""], ["Monitoring metrics, thresholds and owners defined", "", ""], ["Retraining / change-control policy defined", "", ""], ["Threat model includes AI-specific attacks", "", ""], ["No PHI to third-party services without BAA/DPA", "", ""], ["Success metrics have baselines and data sources", "", ""], ["All assumptions have owners and validation plans", "", ""], ["Every requirement is testable and traceable", "", ""]], [5200, 1400, 2760]),
  pageBreak(),

  h1("Appendix F. Reference Frameworks to Consult"),
  guide("This list names frameworks by their common titles so that you can locate the primary source. Editions, publication status and applicability change; confirm each against the issuing body before citing it in a submission. Do not treat this appendix as legal or regulatory advice."),
  h2("Regulatory and policy"),
  bullet("FDA: guidance on Clinical Decision Support software; AI/ML-enabled device programme materials; Predetermined Change Control Plan guidance; Good Machine Learning Practice guiding principles (with Health Canada and MHRA)"),
  bullet("EU: Medical Device Regulation (EU) 2017/745; In Vitro Diagnostic Regulation (EU) 2017/746; Artificial Intelligence Act (Regulation (EU) 2024/1689); MDCG guidance on software qualification and classification"),
  bullet("IMDRF: SaMD key definitions, risk categorisation and clinical evaluation documents"),
  bullet("WHO: guidance on ethics and governance of AI for health, including large multimodal models"),
  bullet("Indonesia: Ministry of Health (Kemenkes) and BPOM regulations on medical devices, health data and digital health; Personal Data Protection Law (UU No. 27/2022)"),
  h2("Standards"),
  bullet("ISO 13485; ISO 14971; IEC 62304; IEC 62366-1; IEC 82304-1; ISO 14155; IEC 81001-5-1"),
  bullet("ISO/IEC 42001; ISO/IEC 23894; ISO/IEC 27001; ISO/IEC 27701"),
  h2("Reporting guidelines (check EQUATOR Network for current versions)"),
  bullet("TRIPOD+AI; CONSORT-AI; SPIRIT-AI; DECIDE-AI; STARD-AI; CLAIM; MI-CLAIM; PRISMA"),
  h2("Interoperability and data standards"),
  bullet("HL7 FHIR; HL7 v2; DICOM; IHE profiles; OMOP Common Data Model; GA4GH standards (htsget, Beacon, Phenopackets, DRS/WES/TES); SNOMED CT; LOINC; ICD-10/11; HGNC/HGVS; HPO; minimum-information standards for omics (e.g., MIAME, MINSEQE)"),
  h2("Documentation practices"),
  bullet("Model cards and datasheets for datasets (widely adopted documentation formats originating in the ML fairness literature); FAIR data principles")
);

// ---------- document ----------
const doc = new Document({
  creator: "PRD Template",
  title: "Product Requirements Document Template — AI in Life Sciences and Health",
  styles: {
    default: { document: { run: { font: FONT, size: 22 } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true, run: { size: 32, bold: true, color: NAVY, font: FONT }, paragraph: { spacing: { before: 360, after: 200 }, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true, run: { size: 26, bold: true, color: TEAL, font: FONT }, paragraph: { spacing: { before: 240, after: 120 }, outlineLevel: 1 } },
      { id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true, run: { size: 23, bold: true, color: "374151", font: FONT }, paragraph: { spacing: { before: 180, after: 100 }, outlineLevel: 2 } },
    ],
  },
  numbering: {
    config: [
      {
        reference: "bullets",
        levels: [
          { level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } },
          { level: 1, format: LevelFormat.BULLET, text: "\u2013", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 1440, hanging: 360 } } } },
        ],
      },
    ],
  },
  features: { updateFields: true },
  sections: [
    {
      properties: { page: { margin: { top: 1440, bottom: 1440, left: 1440, right: 1440 } } },
      headers: {
        default: new Header({
          children: [
            new Paragraph({
              border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: "BFC7D1", space: 2 } },
              tabStops: [{ type: TabStopType.RIGHT, position: W }],
              children: [
                new TextRun({ text: "PRD Template — AI in Life Sciences and Health", size: 18, color: GREY, font: FONT }),
                new TextRun({ text: "\t[Product name] · [Version] · [Confidentiality]", size: 18, color: GREY, font: FONT }),
              ],
            }),
          ],
        }),
      },
      footers: {
        default: new Footer({
          children: [
            new Paragraph({
              alignment: AlignmentType.CENTER,
              children: [
                new TextRun({ text: "Page ", size: 18, color: GREY, font: FONT }),
                new TextRun({ children: [PageNumber.CURRENT], size: 18, color: GREY, font: FONT }),
                new TextRun({ text: " of ", size: 18, color: GREY, font: FONT }),
                new TextRun({ children: [PageNumber.TOTAL_PAGES], size: 18, color: GREY, font: FONT }),
              ],
            }),
          ],
        }),
      },
      children,
    },
  ],
});

Packer.toBuffer(doc).then((buf) => {
  fs.writeFileSync(OUT, buf);
  console.log("written " + OUT);
});
