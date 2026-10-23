---
name: structure-based-drug-discovery-with-ANM
description: Structure-based drug discovery pipeline for a protein target using Vina docking, OpenMM MD, ADMET descriptors, Anisotropic Network Model (ANM, ProDy) pocket dynamics, and MCDA ranking. Use whenever the user wants to screen compounds against a PDB target, prepare a receptor or ligand library, run ANM normal-mode analysis of a binding pocket, or rank hit candidates, even if they only say "dock these compounds", "ANM on my protein", "pocket flexibility", or "rank my hits". Also use when asked to review, run, or fix these scripts. The full source code is included in Appendix A, so no external files are needed.
compatibility: Python 3.10+, rdkit, pandas, numpy, matplotlib, prody (ANM and PDB stages), openmm (MD stage), AutoDock Vina and ADFR prepare_ligand4.py (docking stage). MM-PBSA needs AmberTools.
---

# Structure-based drug discovery with ANM

This skill runs an eight-stage pipeline: library prep, Vina docking, MD, ANM pocket dynamics, ADMET descriptors, and MCDA ranking. The complete source is in Appendix A. Recreate the files from the appendix, then run them.

The pipeline produces hypotheses. Docking scores and ANM values do not measure binding affinity or drug activity. Every hit needs experimental validation.

## Setup: recreate the files

1. Save the extraction script from Appendix B as `extract_files.py`.
2. Extract every source file from this skill file into a new folder (this skill file is the input):

```bash
python extract_files.py structure-based-drug-discovery-with-ANM.md drug_discovery_scripts
```

Each file from Appendix A is written into that folder under its own name. Nothing else is needed.

4. Run the self-check (needs rdkit and pandas only):

```bash
cd drug_discovery_scripts && python test_pipeline_fixes.py
```

Expect `8 checks passed.` If it fails, do not run the pipeline until you know why.

Files extracted from this skill:

| File | Stage | Role |
|---|---|---|
| `01_prepare_protein.py` | 1 | PDB download, binding box (needs ProDy) |
| `02_prepare_library.py` | 2 | SMILES to 3D SDF with `compound_id` (RDKit) |
| `03_run_docking.py` | 3 | Vina screening (needs Vina, ADFR) |
| `04_run_md_simulation.py` | 4 | OpenMM MD, optional (needs OpenMM) |
| `05_binding_energy.py` | 5 | Placeholder energy estimate. Do not rank with it. |
| `06_anm_analysis.py` | 6 | ANM pocket fluctuations (needs ProDy) |
| `07_admet_profiling.py` | 7 | Drug-likeness descriptors (RDKit) |
| `08_rank_candidates.py` | 8 | MCDA ranking (pandas) |
| `smiles_io.py` | shared | Stable compound IDs for stages 2 and 7 |
| `test_pipeline_fixes.py` | check | Self-check for the fixed logic |
| `sample_compounds.smi` | input | Test SMILES |

## Pipeline map

| Stage | Script | Input | Output | Verified here |
|---|---|---|---|---|
| 1 | `01_prepare_protein.py` | PDB ID, optional pocket residues | `<ID>_prepared.pdb`, box centre and size | Compiles only (needs ProDy) |
| 2 | `02_prepare_library.py` | `.smi` file | `library_prepared.sdf` with `compound_id` | Run end to end (RDKit) |
| 3 | `03_run_docking.py` | receptor `.pdbqt`, ligand SDF, box | `docking_results.csv` | Vina parser unit-tested; Vina not run |
| 4 | `04_run_md_simulation.py` | protein PDB | `trajectory.dcd`, `energy.log` | Compiles only (needs OpenMM) |
| 5 | `05_binding_energy.py` | protein PDB, SMILES | `binding_energy.csv` | Compiles only; placeholder, not ΔG |
| 6 | `06_anm_analysis.py` | protein PDB, ligand centre | `anm_rmsf.csv`, `anm_analysis.png` | Compiles only (needs ProDy) |
| 7 | `07_admet_profiling.py` | `.smi` file | `admet_results.csv` | Run end to end (RDKit) |
| 8 | `08_rank_candidates.py` | docking CSV, ADMET CSV, optional dynamics CSV | `ranked_candidates.csv` | Run end to end with simulated docking energies |

Run the stages in order. `smiles_io.py` must sit beside scripts 02 and 07.

## Workflow

### Stage 1: Protein preparation

```bash
python 01_prepare_protein.py --pdb_id 3ODU --binding_residues 110,114,121,125 --output_dir ./work
```

- Downloads the PDB, keeps protein atoms plus ZN and MG, writes `<ID>_prepared.pdb`.
- Targeted docking: pass pocket residues. Blind docking: omit them, and the whole protein sets the box.
- Box = bounding box of the pocket atoms + 6 Å per axis.
- Not done here: protonation (the `ph` argument is unused) and PDBQT conversion. Protonate at pH 7.4 and prepare the receptor PDBQT with ADFR `prepare_receptor4.py` or Open Babel before stage 3.

### Stage 2: Library preparation

```bash
python 02_prepare_library.py --smiles_file sample_compounds.smi --output_sdf library_prepared.sdf
```

- Drops invalid SMILES, applies Lipinski RO5 (MW ≤ 500, cLogP ≤ 5, HBD ≤ 5, HBA ≤ 10), adds hydrogens, embeds 3D, minimises with MMFF, writes SDF.
- Each record carries `compound_id`, the record's position in the SMILES file (comments and blank lines skipped). Keep the same SMILES file for every stage.
- Retention is printed. Zero retention is a bug signal, not a chemistry result.

### Stage 3: Virtual screening with Vina

```bash
python 03_run_docking.py --receptor receptor.pdbqt --ligands library_prepared.sdf \
    --center 12.3,-4.5,20.1 --size 22,22,22 --exhaustiveness 8 --output_dir docking_results
```

- Needs `vina` and `prepare_ligand4.py` on PATH. Exits early with a clear error if either is missing.
- Energy is read from the `REMARK VINA RESULT` line of each output PDBQT (mode 1).
- Skipped compounds are counted by reason and printed. Check the counts before trusting the table.
- Vina timeout default: 600 s per ligand (`--vina_timeout`).
- Validate by re-docking the co-crystal ligand. The reproduced pose should be within about 2 Å RMSD of the crystal pose. The scripts do not do this step.

### Stage 4: MD (optional, pose validation)

```bash
python 04_run_md_simulation.py --pdb protein.pdb --output_dir md_output --production_time_ns 200
```

- amber14 with TIP3P-FB, PME (1.0 nm cutoff), HBonds constraints, Langevin at 300 K, 2 fs step.
- Protocol: minimise, NVT 50 ps (no barostat), NPT 100 ps (barostat added, simulation rebuilt from the current state), then production.
- Protein-only input. A ligand-containing PDB raises a clear error. Parametrise ligands with GAFF or OpenFF first if you need a complex.
- 200 ns is about 10^8 steps. Use a GPU platform. The script has no checkpointing.

### Stage 5: Binding energy (do not use for ranking)

- `05_binding_energy.py` is an empirical placeholder: `ΔG ≈ -10 - 0.01·MW + 0.5·LogP - 0.5·HBA`. It ignores the protein.
- Do not report its output as a binding free energy. Stage 8 does not read it.
- For a real estimate, run MM-PBSA (`MMPBSA.py`, AmberTools) on the stage 4 trajectory. `--mmpbsa_template` writes `mmpbsa.in`. Validate against a known binder and a known non-binder first.

### Stage 6: ANM pocket dynamics

```bash
python 06_anm_analysis.py --pdb 3ODU_prepared.pdb --ligand_xyz 12.3,-4.5,20.1 \
    --pocket_radius 8.0 --n_modes 20 --output_dir anm_results
```

- ANM on the Cα atoms within `pocket_radius` of the ligand centre (cutoff 15 Å, gamma 1.0). Default radius 8 Å. Refuses pockets with fewer than 10 Cα atoms.
- Output is per-residue mean-square fluctuation (`msf_relative`) in ANM's relative units, not Å. Compare residues within one pocket. Do not compare to fixed cutoffs.
- Check the eigenvalue plot: values increase from mode 1. ProDy drops the six trivial translation and rotation modes. Near-zero first eigenvalues mean the network is disconnected.
- ANM is protein-level here. It gives one pocket profile, not one per compound (see stage 8).

### Stage 7: ADMET descriptors

```bash
python 07_admet_profiling.py --smiles_file sample_compounds.smi --output_csv admet_results.csv
```

- Computes MW, cLogP, HBD, HBA, rotatable bonds, TPSA, aromatic rings, Fsp3, RO5 violation count, and rule-of-thumb BBB and solubility labels.
- These are descriptors, not measured ADMET. No hERG, metabolism, toxicity, or PAINS screen is run.
- `compound_id` matches stage 2. Invalid SMILES are dropped and keep their IDs.

### Stage 8: MCDA ranking

```bash
python 08_rank_candidates.py --docking docking_results/docking_results.csv \
    --admet admet_results.csv --output ranked_candidates.csv
```

Default weights: binding energy 0.25, druggability 0.20, stability 0.20, flexibility 0.15, safety 0.10, synthesis 0.10.

- **Without `--dynamics`:** stability and flexibility are dropped and the other four weights are renormalised.
- **With `--dynamics dynamics.csv`:** the CSV needs `compound_id`, `rmsd` (Å), and `pocket_msf` for every docked compound. Missing compounds raise an error. Stability is 1 − RMSD/3. Flexibility is scored around an unvalidated centre of 0.8 relative units. Calibrate before relying on it.
- Binding energy scales linearly from -12 to 0 kcal/mol and clips outside that range.
- Safety is a LogP proxy and synthesis is a ring and rotor proxy. Neither is a validated screen.
- Report the weights, and check sensitivity by perturbing each weight ±20%. Report whether the top 5 change.

## Fixed in this revision

Verified by running code (RDKit 2026.09, pandas 3.x) or by compiling every script.

| Script | Bug | Fix |
|---|---|---|
| 02 | `UMMFFOptimizeMolecule` does not exist in RDKit, so every molecule failed inside a bare `except` | Use `MMFFOptimizeMolecule`; check the `EmbedMolecule` return code; no bare `except` |
| 02 | Rotatable-bond limit labelled as part of RO5 | Removed from the RO5 filter (Veber's rule is separate) |
| 02, 07 | Compound IDs differed between stages (line index vs SDF index, comments counted) | Shared `smiles_io.read_smiles`; IDs stored in SDF as `compound_id` |
| 03 | Energy parser never matched Vina's output | Read `REMARK VINA RESULT` from the output PDBQT |
| 03 | `shell=True` with unquoted paths breaks on paths with spaces | List arguments, no shell |
| 03 | Silent skips on timeout or error | Counted by reason and printed |
| 04 | "NVT" steps ran at constant pressure | NVT stage has no barostat; NPT stage rebuilds the simulation from the current state |
| 04 | Ligand input failed with an unclear error | Clear error pointing to parametrisation |
| 05 | `from prody import *` inside a function is a SyntaxError | Module-level `from prody import parsePDB` |
| 06 | Per-residue values indexed with protein-wide indices | Pocket-local values with residue numbers from the same atoms |
| 06 | Values reported in Å with fixed "RIGID / FLEXIBLE" cutoffs | Relative units; class labels removed |
| 06 | Default pocket radius 5 Å selected too few atoms | Default 8 Å; refuses pockets under 10 Cα atoms |
| 07 | `Descriptors.FractionCsp3` renamed in RDKit | `FractionCSP3` |
| 07 | Docstring claimed PAINS filtering | Docstring corrected; no PAINS screen is run |
| 08 | Missing dynamics defaulted to RMSD 2.0 Å and RMSF 1.0 for every compound | Terms dropped without dynamics; full coverage required with dynamics |
| 08 | Empty docking table crashed or ranked nothing | Explicit errors |
| 01 | Docstring claimed PDBQT conversion | Docstring lists what is not done |
| sample file | Record 5 was an invalid SMILES | Replaced with caffeine (`CN1C=NC2=C1C(=O)N(C)C(=O)N2C`) |

## Still open

- **ProDy and OpenMM scripts (01, 04, 05, 06) are not run.** ProDy failed to build from source in the session environment (C++ header error), and OpenMM was not installed. Run a small test on your machine before a real run.
- **Vina is not run.** The parser is tested against the documented output line format. Run one ligand and check that `docking_results.csv` is non-empty.
- **Protonation and receptor PDBQT** are manual steps (stage 1).
- **MD has no checkpointing** and no ligand support.
- **Flexibility centre (0.8)** in stage 8 is unvalidated.
- **Safety and synthesis** are proxies, not screens.
- **Stage 5** remains a placeholder and is not an input to stage 8.

## Quality gates

1. After stage 2: retention is not 0%; SDF records carry `compound_id`.
2. After stage 3: skip counts are acceptable; `docking_results.csv` is non-empty; the co-crystal re-dock reproduces the pose within about 2 Å.
3. After stage 6: mode eigenvalues increase from mode 1; the pocket Cα atoms are near the ligand when plotted.
4. After stage 8: the top 5 are stable under ±20% weight changes; otherwise report the ranking as sensitive.
5. Before reporting: label each hit as a computational hypothesis, with software versions, parameters, and the SMILES file used.

## Reporting

- Include versions (RDKit, ProDy, Vina, OpenMM, AmberTools), parameters (box, exhaustiveness, ANM cutoff and gamma, pocket radius, weights), the PDB ID and chain.
- State that stage 5 is a placeholder, and that ANM values are relative.
- Cite the method papers. Verify DOIs before citing:
  - ProDy: Bakan, Meireles & Bahar (2011), Bioinformatics, DOI 10.1093/bioinformatics/btr168
  - ProDy 2.0: Zhang et al. (2021), Bioinformatics, DOI 10.1093/bioinformatics/btab187
  - AutoDock Vina: Trott & Olson (2010), J Comput Chem 31:455 (verify DOI)

## When not to use this skill

- The user wants only one step (for example, a PDBQT file). Run that step.
- The target is a membrane protein. The MD setup covers soluble proteins only.
- The user asks for a publishable binding affinity from stage 5. Explain the placeholder and offer MM-PBSA.

---

# Appendix A: Source files

Each block below is one file. Recreate them exactly, or run Appendix B.

### File: `01_prepare_protein.py`

````python
#!/usr/bin/env python3
"""
Script 1: Protein Target Preparation for Molecular Docking

Purpose: Download a PDB structure, strip waters and ligands, and compute the
docking box from the binding-site residues (or the whole protein for blind docking).

Not done here: protonation (the ph argument is unused) and PDBQT conversion.
Prepare the receptor PDBQT separately (ADFR prepare_receptor4.py or Open Babel)
and protonate at pH 7.4 before docking.

Usage:
    python 01_prepare_protein.py --pdb_id 3ODU --binding_residues 110,114,121,125
"""

import argparse
import numpy as np
from prody import *
import os

def prepare_protein(pdb_id, binding_site_residues=None, ph=7.4, output_dir='./'):
    """
    Download and prepare protein structure for docking.
    
    Args:
        pdb_id: PDB identifier (e.g., '3ODU')
        binding_site_residues: List of residue numbers defining pocket (None for blind docking)
        ph: Physiological pH (default 7.4)
        output_dir: Output directory for prepared structures
    
    Returns:
        Prepared PDB filename, box_center, box_size
    """
    os.makedirs(output_dir, exist_ok=True)
    
    print(f"Downloading PDB structure {pdb_id}...")
    pdb = fetchPDB(pdb_id)
    ag = parsePDB(pdb)
    
    print(f"Loaded {ag.numAtoms()} atoms, {ag.numResidues()} residues")
    
    # Remove heteroatoms (water, ligands) except essential cofactors
    ag_cleaned = ag.select('not heteroatm or (resname ZN or resname MG)')
    
    # Save prepared structure
    output_pdb = os.path.join(output_dir, f'{pdb_id}_prepared.pdb')
    writePDB(output_pdb, ag_cleaned)
    print(f"Saved prepared structure: {output_pdb}")
    
    # Define docking grid
    if binding_site_residues:
        # Targeted docking: define pocket
        residue_str = ' or '.join([f'residue {r}' for r in binding_site_residues])
        pocket_atoms = ag_cleaned.select(residue_str)
        if pocket_atoms is None:
            print(f"Warning: Residues {binding_site_residues} not found")
            pocket_atoms = ag_cleaned
    else:
        # Blind docking: use entire protein
        pocket_atoms = ag_cleaned
    
    # Calculate box dimensions
    coords = pocket_atoms.getCoords()
    box_center = coords.mean(axis=0)
    box_size = np.ptp(coords, axis=0) + np.array([6, 6, 6])  # Add padding
    
    print(f"\nDocking Grid Parameters:")
    print(f"Box center: ({box_center[0]:.2f}, {box_center[1]:.2f}, {box_center[2]:.2f})")
    print(f"Box size: ({box_size[0]:.2f}, {box_size[1]:.2f}, {box_size[2]:.2f})")
    
    return output_pdb, box_center, box_size

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Prepare protein structure for docking')
    parser.add_argument('--pdb_id', required=True, help='PDB identifier (e.g., 3ODU)')
    parser.add_argument('--binding_residues', help='Comma-separated list of binding-site residues')
    parser.add_argument('--output_dir', default='./', help='Output directory')
    
    args = parser.parse_args()
    
    binding_residues = None
    if args.binding_residues:
        binding_residues = [int(r.strip()) for r in args.binding_residues.split(',')]
    
    pdb_file, center, size = prepare_protein(args.pdb_id, binding_residues, output_dir=args.output_dir)
    print(f"\n✓ Protein preparation complete: {pdb_file}")
````

### File: `02_prepare_library.py`

````python
#!/usr/bin/env python3
"""
Script 2: Chemical Library Preparation and Drug-Likeness Filtering

Purpose: Standardise SMILES, add hydrogens, apply Lipinski's Rule of Five,
generate 3D structures for docking. Each output record carries the stable
'compound_id' property (see smiles_io.py) used by later stages.

Usage:
    python 02_prepare_library.py --smiles_file compounds.smi --output_sdf library_prepared.sdf
"""

import argparse
import os
from rdkit import Chem
from rdkit.Chem import Descriptors, Crippen, AllChem

from smiles_io import read_smiles


def prepare_ligand_library(smiles_file, output_sdf, apply_ro5=True, verbose=True):
    """
    Prepare ligand library: standardise SMILES, add hydrogens, apply filters.

    Args:
        smiles_file: Text file with SMILES strings (one per line)
        output_sdf: Output SDF file with prepared 3D structures
        apply_ro5: Apply Lipinski's Rule of Five filtering
        verbose: Print progress messages

    Returns:
        Output SDF filename, number of retained compounds, statistics dict
    """
    records = read_smiles(smiles_file)
    total = len(records)
    mols = []
    rejected_counts = {'invalid_smiles': 0, 'ro5_violation': 0, 'other': 0}

    if verbose:
        print(f"Reading {total} SMILES from {smiles_file}...")

    for cid, smiles in records:
        mol = Chem.MolFromSmiles(smiles)
        if mol is None:
            rejected_counts['invalid_smiles'] += 1
            continue

        # Lipinski's Rule of Five. Rotatable bonds are not part of RO5 (Veber's rule).
        if apply_ro5:
            mw = Descriptors.MolWt(mol)
            logp = Crippen.MolLogP(mol)
            hbd = Descriptors.NumHDonors(mol)
            hba = Descriptors.NumHAcceptors(mol)
            if mw > 500 or logp > 5 or hbd > 5 or hba > 10:
                rejected_counts['ro5_violation'] += 1
                continue

        mol = Chem.AddHs(mol)
        # EmbedMolecule returns -1 when no 3D conformer can be generated.
        if AllChem.EmbedMolecule(mol, randomSeed=42) != 0:
            rejected_counts['other'] += 1
            continue
        AllChem.MMFFOptimizeMolecule(mol)

        mol.SetIntProp('compound_id', cid)
        mols.append(mol)

    if verbose:
        print(f"Writing {len(mols)} compounds to {output_sdf}...")

    writer = Chem.SDWriter(output_sdf)
    for mol in mols:
        writer.write(mol)
    writer.close()

    stats = {
        'input_compounds': total,
        'output_compounds': len(mols),
        'invalid_smiles': rejected_counts['invalid_smiles'],
        'ro5_violations': rejected_counts['ro5_violation'],
        'other_errors': rejected_counts['other'],
        'retention_rate': 100 * len(mols) / total if total > 0 else 0
    }

    if verbose:
        print(f"\n✓ Library preparation complete:")
        print(f"  Input compounds: {stats['input_compounds']}")
        print(f"  Output compounds: {stats['output_compounds']}")
        print(f"  Retention rate: {stats['retention_rate']:.1f}%")
        print(f"  Invalid SMILES: {stats['invalid_smiles']}")
        print(f"  RO5 violations: {stats['ro5_violations']}")
        print(f"  Embedding failures: {stats['other_errors']}")

    return output_sdf, len(mols), stats


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Prepare chemical library for docking')
    parser.add_argument('--smiles_file', required=True, help='Input SMILES file')
    parser.add_argument('--output_sdf', required=True, help='Output SDF file')
    parser.add_argument('--no_ro5', action='store_true', help='Skip Lipinski RO5 filtering')

    args = parser.parse_args()

    sdf_file, n_mols, stats = prepare_ligand_library(
        args.smiles_file,
        args.output_sdf,
        apply_ro5=not args.no_ro5
    )
````

### File: `03_run_docking.py`

````python
#!/usr/bin/env python3
"""
Script 3: Virtual Screening with AutoDock Vina

Purpose: Perform high-throughput docking to identify hit compounds.
Requires: AutoDock Vina and prepare_ligand4.py (from ADFR) on PATH.

Usage:
    python 03_run_docking.py --receptor protein.pdbqt --ligands library.sdf \\
                             --center 0,0,0 --size 30,30,30
"""

import argparse
import os
import shutil
import subprocess
from collections import Counter

import pandas as pd
from rdkit import Chem


def read_vina_affinity(out_pdbqt):
    """Return the best (mode 1) affinity in kcal/mol from a Vina output PDBQT, or None."""
    with open(out_pdbqt) as f:
        for line in f:
            # Format: "REMARK VINA RESULT:  -7.2  0.000  0.000"
            if line.startswith('REMARK VINA RESULT:'):
                return float(line.split()[3])
    return None


def run_vina_docking(receptor_pdbqt, ligand_sdf, grid_center, grid_size,
                     output_dir='docking_results', exhaustiveness=8,
                     prep_timeout=60, vina_timeout=600, verbose=True):
    """
    Run AutoDock Vina for ligand library screening.

    Args:
        receptor_pdbqt: Prepared receptor in PDBQT format
        ligand_sdf: Ligand library SDF file (from 02_prepare_library.py)
        grid_center: Tuple (x, y, z) for docking box center
        grid_size: Tuple (sx, sy, sz) for docking box dimensions
        exhaustiveness: Search intensity (1-32; default 8)
        prep_timeout: Seconds allowed for prepare_ligand4.py per ligand
        vina_timeout: Seconds allowed for vina per ligand
        verbose: Print progress

    Returns:
        DataFrame with docking results (compound_id, smiles, binding_energy_kcal_mol)
    """
    for tool in ('vina', 'prepare_ligand4.py'):
        if shutil.which(tool) is None:
            raise FileNotFoundError(f"'{tool}' not found on PATH; install AutoDock Vina / ADFR")

    os.makedirs(output_dir, exist_ok=True)

    if verbose:
        print(f"Starting virtual screening with AutoDock Vina...")
        print(f"Receptor: {receptor_pdbqt}")
        print(f"Grid center: {grid_center}")
        print(f"Grid size: {grid_size}")

    results = []
    skipped = Counter()
    suppl = Chem.SDMolSupplier(ligand_sdf)
    total = len(suppl)

    if verbose:
        print(f"Screening {total} compounds...\n")

    for i, mol in enumerate(suppl):
        if mol is None:
            skipped['unreadable_sdf_record'] += 1
            continue

        # Stable ID from stage 2; fall back to record index for hand-made SDFs
        cid = mol.GetIntProp('compound_id') if mol.HasProp('compound_id') else i

        if verbose and (i + 1) % 1000 == 0:
            print(f"  Processed {i+1}/{total} compounds...")

        ligand_pdb = os.path.join(output_dir, f'lig_{cid}.pdb')
        ligand_pdbqt = os.path.join(output_dir, f'lig_{cid}.pdbqt')
        output_pdbqt = os.path.join(output_dir, f'lig_{cid}_out.pdbqt')

        Chem.MolToPDBFile(mol, ligand_pdb)

        # List arguments, not shell=True: the project path contains spaces.
        try:
            prep = subprocess.run(
                ['prepare_ligand4.py', '-l', ligand_pdb, '-o', ligand_pdbqt],
                capture_output=True, text=True, timeout=prep_timeout)
        except subprocess.TimeoutExpired:
            skipped['prepare_ligand_timeout'] += 1
            continue
        if prep.returncode != 0 or not os.path.exists(ligand_pdbqt):
            skipped['prepare_ligand_failed'] += 1
            continue

        try:
            subprocess.run(
                ['vina', '--receptor', receptor_pdbqt, '--ligand', ligand_pdbqt,
                 '--center_x', str(grid_center[0]), '--center_y', str(grid_center[1]),
                 '--center_z', str(grid_center[2]),
                 '--size_x', str(grid_size[0]), '--size_y', str(grid_size[1]),
                 '--size_z', str(grid_size[2]),
                 '--out', output_pdbqt, '--exhaustiveness', str(exhaustiveness)],
                capture_output=True, text=True, timeout=vina_timeout, check=True)
        except subprocess.TimeoutExpired:
            skipped['vina_timeout'] += 1
            continue
        except subprocess.CalledProcessError:
            skipped['vina_failed'] += 1
            continue

        energy = read_vina_affinity(output_pdbqt) if os.path.exists(output_pdbqt) else None
        if energy is None:
            skipped['no_vina_result'] += 1
            continue

        results.append({
            'compound_id': cid,
            'smiles': Chem.MolToSmiles(Chem.RemoveHs(mol)),
            'binding_energy_kcal_mol': energy
        })

    df = pd.DataFrame(results, columns=['compound_id', 'smiles', 'binding_energy_kcal_mol'])
    if len(df) > 0:
        df = df.sort_values('binding_energy_kcal_mol')

    if verbose:
        print(f"\n✓ Docking complete!")
        print(f"  Successful poses: {len(df)}/{total}")
        if skipped:
            print(f"  Skipped: {dict(skipped)}")
        if len(df) > 0:
            print(f"  Best binding energy: {df['binding_energy_kcal_mol'].min():.2f} kcal/mol")
            print(f"  Worst binding energy: {df['binding_energy_kcal_mol'].max():.2f} kcal/mol")
            print(f"\nTop 10 hits:")
            print(df.head(10).to_string(index=False))

    csv_output = os.path.join(output_dir, 'docking_results.csv')
    df.to_csv(csv_output, index=False)
    if verbose:
        print(f"\nResults saved: {csv_output}")

    return df


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Run AutoDock Vina screening')
    parser.add_argument('--receptor', required=True, help='Receptor PDBQT file')
    parser.add_argument('--ligands', required=True, help='Ligand library SDF file')
    parser.add_argument('--center', required=True, help='Grid center (x,y,z)')
    parser.add_argument('--size', required=True, help='Grid size (sx,sy,sz)')
    parser.add_argument('--output_dir', default='docking_results', help='Output directory')
    parser.add_argument('--exhaustiveness', type=int, default=8, help='Search exhaustiveness')
    parser.add_argument('--vina_timeout', type=int, default=600,
                        help='Seconds allowed per ligand for Vina')

    args = parser.parse_args()

    center = tuple(float(x) for x in args.center.split(','))
    size = tuple(float(x) for x in args.size.split(','))

    results = run_vina_docking(args.receptor, args.ligands, center, size,
                               args.output_dir, args.exhaustiveness,
                               vina_timeout=args.vina_timeout)
````

### File: `04_run_md_simulation.py`

````python
#!/usr/bin/env python3
"""
Script 4: Molecular Dynamics Simulation with OpenMM

Purpose: Run MD simulations to validate docking poses and assess binding stability.
Covers: System preparation, energy minimisation, equilibration, production MD.

Usage:
    python 04_run_md_simulation.py --pdb complex.pdb --output_dir md_output \\
                                   --production_time_ns 200
"""

import argparse
import os
from openmm.app import *
from openmm import *
from openmm.unit import *

def run_md_simulation(protein_pdb, output_dir='md_output', 
                      production_time_ns=200, verbose=True):
    """
    Run molecular dynamics simulation of a protein (protein-only input).

    Args:
        protein_pdb: Protein structure (prepared PDB). Ligands are not parametrised here.
        output_dir: Output directory for trajectory and logs
        production_time_ns: Production MD duration in nanoseconds
        verbose: Print progress
    
    Returns:
        Trajectory filename, energy log filename
    """
    os.makedirs(output_dir, exist_ok=True)
    
    if verbose:
        print(f"Setting up MD simulation ({production_time_ns} ns production)...")
    
    # Load structure
    pdb = PDBFile(protein_pdb)
    forcefield = ForceField('amber14-all.xml', 'amber14/tip3pfb.xml')
    
    if verbose:
        print(f"Loaded {pdb.topology.getNumAtoms()} atoms, "
              f"{pdb.topology.getNumResidues()} residues")
    
    # Add hydrogens and solvate
    modeller = Modeller(pdb.topology, pdb.positions)
    modeller.addHydrogens(forcefield)
    modeller.addSolvent(forcefield, model='tip3p', padding=10*angstroms,
                        ionicStrength=0.15*molar)
    
    if verbose:
        print(f"Solvated system: {modeller.topology.getNumAtoms()} atoms total")
    
    # Create system. No barostat yet: the NVT stage must run at constant volume.
    try:
        system = forcefield.createSystem(
            modeller.topology,
            nonbondedMethod=PME,
            nonbondedCutoff=1.0*nanometer,
            constraints=HBonds,
            rigidWater=True
        )
    except ValueError as err:
        raise ValueError(f"{err}. This script takes protein-only input; "
                         "parametrise ligands (GAFF or OpenFF) before running MD.") from err

    integrator = LangevinIntegrator(300*kelvin, 1/picosecond, 2*femtoseconds)
    simulation = Simulation(modeller.topology, system, integrator)
    simulation.context.setPositions(modeller.positions)

    # Energy minimisation
    if verbose:
        print("Energy minimisation...")
    simulation.minimizeEnergy(maxIterations=1000)
    state = simulation.context.getState(getEnergy=True)
    if verbose:
        print(f"  Final energy: {state.getPotentialEnergy()/kilojoule_per_mole:.2f} kJ/mol")

    # NVT equilibration (50 ps)
    if verbose:
        print("NVT equilibration (50 ps)...")
    simulation.context.setVelocitiesToTemperature(300*kelvin)
    simulation.step(25000)  # 50 ps at 2 fs/step

    # NPT equilibration (100 ps). Add the barostat, then rebuild the simulation
    # from the current state: forces cannot be added to a live context.
    if verbose:
        print("NPT equilibration (100 ps)...")
    system.addForce(MonteCarloBarostat(1*atmosphere, 300*kelvin))
    state = simulation.context.getState(getPositions=True, getVelocities=True)
    integrator = LangevinIntegrator(300*kelvin, 1/picosecond, 2*femtoseconds)
    simulation = Simulation(modeller.topology, system, integrator)
    simulation.context.setState(state)
    simulation.step(50000)  # 100 ps
    
    # Production MD
    if verbose:
        print(f"Production MD ({production_time_ns} ns)...")
    
    trajectory_file = os.path.join(output_dir, 'trajectory.dcd')
    energy_log = os.path.join(output_dir, 'energy.log')
    
    simulation.reporters.append(
        DCDReporter(trajectory_file, 1000)  # Save every 2 ps
    )
    simulation.reporters.append(
        StateDataReporter(energy_log, 1000, step=True, time=True,
                         potentialEnergy=True, kineticEnergy=True,
                         temperature=True, density=True, progress=True)
    )
    
    # Calculate number of steps
    n_steps = int((production_time_ns * nanosecond) / (2 * femtosecond))
    simulation.step(n_steps)
    
    if verbose:
        print(f"\n✓ MD simulation complete!")
        print(f"  Trajectory: {trajectory_file}")
        print(f"  Energy log: {energy_log}")
    
    return trajectory_file, energy_log

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Run MD simulation with OpenMM')
    parser.add_argument('--pdb', required=True, help='Input PDB file (protein only)')
    parser.add_argument('--output_dir', default='md_output', help='Output directory')
    parser.add_argument('--production_time_ns', type=int, default=200,
                       help='Production MD duration (ns)')
    
    args = parser.parse_args()
    
    traj, energy = run_md_simulation(args.pdb, args.output_dir, 
                                     args.production_time_ns)
````

### File: `05_binding_energy.py`

````python
#!/usr/bin/env python3
"""
Script 5: Binding Free Energy Calculation (MM-PBSA)

Purpose: Calculate binding free energy from MD trajectories.
Uses MMPBSA.py from AmberTools or simplified approximation.

Note: This is a simplified version. For production use, install AmberTools
and use: mmpbsa.py -i mmpbsa.in -o results.dat -cp complex.prmtop \\
                    -lp ligand.prmtop -rp receptor.prmtop -y trajectory.dcd
"""

import argparse
import numpy as np
import pandas as pd
from prody import parsePDB

def estimate_binding_energy_simple(protein_pdb, ligand_smiles, 
                                   output_csv='binding_energy.csv',
                                   verbose=True):
    """
    Simplified binding energy estimation using distance-based approximation.
    
    NOTE: This is a PLACEHOLDER for educational purposes only.
    For accurate ΔG_bind calculations, use:
    - MMPBSA.py (AmberTools)
    - FEP/TI (NAMD, AMBER, Gromacs)
    - MM-GBSA (commercial packages)
    
    Args:
        protein_pdb: Protein structure
        ligand_smiles: Ligand SMILES string
        output_csv: Output CSV file
        verbose: Print progress
    
    Returns:
        Estimated ΔG_bind (kcal/mol)
    """
    from rdkit import Chem

    if verbose:
        print("Calculating binding energy (simplified estimate)...")
        print("WARNING: This is a crude approximation for demonstration only!")
        print("For production use, employ MMPBSA.py, FEP, or MM-GBSA methods.")
    
    # Load protein
    protein = parsePDB(protein_pdb)
    ca = protein.select('ca')
    protein_center = ca.getCoords().mean(axis=0)
    
    # Parse ligand
    mol = Chem.MolFromSmiles(ligand_smiles)
    if mol is None:
        print(f"Invalid SMILES: {ligand_smiles}")
        return None
    
    # Crude approximation: base ΔG on ligand molecular weight and LogP
    from rdkit.Chem import Descriptors, Crippen
    mw = Descriptors.MolWt(mol)
    logp = Crippen.MolLogP(mol)
    hba = Descriptors.NumHAcceptors(mol)
    
    # Empirical correlation (VERY rough)
    # ΔG ≈ -10 - 0.01*MW + 0.5*LogP - 0.5*HBA (kcal/mol)
    dg_bind = -10.0 - 0.01*mw + 0.5*logp - 0.5*hba
    
    results = [{
        'ligand_smiles': ligand_smiles,
        'molecular_weight': mw,
        'logp': logp,
        'hba': hba,
        'dg_bind_kcal_mol_estimate': dg_bind,
        'method': 'simplified_approximation'
    }]
    
    df = pd.DataFrame(results)
    df.to_csv(output_csv, index=False)
    
    if verbose:
        print(f"\n✓ Binding energy estimation complete")
        print(f"  Estimated ΔG_bind: {dg_bind:.2f} kcal/mol (crude estimate)")
        print(f"  Results saved: {output_csv}")
        print(f"\n  IMPORTANT: Use MMPBSA.py for production accuracy!")
    
    return dg_bind

def print_mmpbsa_template(output_file='mmpbsa.in'):
    """
    Print template MMPBSA.py input file for reference.
    
    Args:
        output_file: Filename to save template
    """
    template = """
&general
   endframe=1000, keep_files=0, strip_mask=':WAT:Na+:Cl-',
/
&gb
   igb=5, saltcon=0.15,
/
&decomp
   idecomp=1,
/
"""
    
    with open(output_file, 'w') as f:
        f.write(template)
    
    print(f"MMPBSA.py template saved: {output_file}")
    print(f"Usage: mmpbsa.py -i {output_file} -o results.dat \\")
    print(f"       -cp complex.prmtop -lp ligand.prmtop -rp receptor.prmtop \\")
    print(f"       -y trajectory.dcd")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Estimate binding free energy')
    parser.add_argument('--protein', required=True, help='Protein PDB file')
    parser.add_argument('--ligand_smiles', required=True, help='Ligand SMILES')
    parser.add_argument('--output_csv', default='binding_energy.csv',
                       help='Output CSV file')
    parser.add_argument('--mmpbsa_template', action='store_true',
                       help='Print MMPBSA.py template')
    
    args = parser.parse_args()
    
    if args.mmpbsa_template:
        print_mmpbsa_template()
    else:
        dg = estimate_binding_energy_simple(args.protein, args.ligand_smiles,
                                            args.output_csv)
````

### File: `06_anm_analysis.py`

````python
#!/usr/bin/env python3
"""
Script 6: Anisotropic Network Model (ANM) Analysis with ProDy

Purpose: Analyse binding-pocket flexibility and collective motions with a
coarse-grained elastic network model on Cα atoms.

Output units: per-residue mean-square fluctuation (MSF) in ANM's relative
units, not Å. ANM is not calibrated to absolute B-factors here, so compare
values within one pocket and one protein, not against fixed thresholds.

Usage:
    python 06_anm_analysis.py --pdb protein.pdb --ligand_xyz 12.3,-4.5,20.1 \\
                              --pocket_radius 8.0 --output_dir anm_results
"""

import argparse
import os

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from prody import ANM, calcSqFluct, parsePDB


def analyze_binding_pocket_anm(protein_pdb, ligand_center=None,
                               pocket_radius=8.0, n_modes=20,
                               output_dir='anm_results', verbose=True):
    """
    Perform Anisotropic Network Model (ANM) analysis of a binding pocket.

    ANM is a coarse-grained elastic network model using Cα atoms connected
    by harmonic springs. Diagonalising the Hessian yields normal modes that
    describe collective fluctuations without explicit solvent or force-field
    parametrisation.

    Args:
        protein_pdb: Protein structure (PDB file)
        ligand_center: Ligand centre coordinates (x, y, z), or None for the whole protein
        pocket_radius: Radius (Å) around the ligand centre that defines the pocket
        n_modes: Number of slowest modes to use
        output_dir: Directory for output files and plots
        verbose: Print progress messages

    Returns:
        ANM object, per-residue DataFrame, summary metrics dict
    """
    os.makedirs(output_dir, exist_ok=True)

    if verbose:
        print(f"Loading protein structure from {protein_pdb}...")

    protein = parsePDB(protein_pdb)
    ca = protein.select('ca')
    if verbose:
        print(f"Found {ca.numAtoms()} Cα atoms")

    if ligand_center is not None:
        distances = np.linalg.norm(ca.getCoords() - np.asarray(ligand_center), axis=1)
        pocket_atoms = ca[np.where(distances < pocket_radius)[0]]
        if verbose:
            print(f"Binding pocket: {pocket_atoms.numAtoms()} Cα atoms within {pocket_radius} Å")
    else:
        pocket_atoms = ca
        if verbose:
            print("Analysing entire protein (no pocket defined)")

    if pocket_atoms.numAtoms() < 10:
        raise ValueError(f"Only {pocket_atoms.numAtoms()} Cα atoms in the pocket; "
                         "increase --pocket_radius (8 to 10 Å is typical)")

    if verbose:
        print("Building Anisotropic Network Model (cutoff=15.0 Å, gamma=1.0)...")
    anm = ANM('pocket')
    anm.buildHessian(pocket_atoms, cutoff=15.0, gamma=1.0)
    anm.calcModes(n_modes=n_modes)

    # calcSqFluct on the pocket ANM returns one value per pocket Cα, in pocket order.
    # Use pocket-local positions; residue numbers come from the same atoms.
    msf = calcSqFluct(anm[:n_modes])
    resnums = pocket_atoms.getResnums()

    metrics = {
        'mean_msf_relative': float(msf.mean()),
        'std_msf_relative': float(msf.std()),
        'min_msf_relative': float(msf.min()),
        'max_msf_relative': float(msf.max()),
        'n_pocket_calpha': int(pocket_atoms.numAtoms()),
        'n_modes': n_modes,
        'pocket_radius': pocket_radius,
    }

    if verbose:
        print(f"\n✓ ANM analysis complete ({n_modes} modes, relative units):")
        for key, value in metrics.items():
            print(f"  {key}: {value:.4g}" if isinstance(value, float) else f"  {key}: {value}")

    fig, axes = plt.subplots(2, 1, figsize=(12, 8))

    axes[0].plot(resnums, msf, 'o-', linewidth=2, markersize=4)
    axes[0].axhline(msf.mean(), color='r', linestyle='--',
                    label=f"Mean: {msf.mean():.3g} (relative)")
    axes[0].set_xlabel('Residue number')
    axes[0].set_ylabel('MSF (ANM relative units)')
    axes[0].set_title('Pocket Cα fluctuations (ANM)')
    axes[0].legend()
    axes[0].grid(True, alpha=0.3)

    eigvals = [anm[i].getEigval() for i in range(n_modes)]
    axes[1].bar(range(1, n_modes + 1), eigvals, color='steelblue')
    axes[1].set_xlabel('Mode number')
    axes[1].set_ylabel('Eigenvalue')
    axes[1].set_title('ANM mode eigenvalues (increasing = stiffer modes)')
    axes[1].grid(True, alpha=0.3)

    plt.tight_layout()
    plot_file = os.path.join(output_dir, 'anm_analysis.png')
    plt.savefig(plot_file, dpi=150)
    plt.close(fig)

    results_df = pd.DataFrame({'resnum': resnums, 'msf_relative': msf})
    csv_file = os.path.join(output_dir, 'anm_rmsf.csv')
    results_df.to_csv(csv_file, index=False)
    if verbose:
        print(f"\nPlot saved: {plot_file}")
        print(f"Per-residue values saved: {csv_file}")

    return anm, results_df, metrics


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Perform ANM analysis')
    parser.add_argument('--pdb', required=True, help='Protein PDB file')
    parser.add_argument('--ligand_xyz', help='Ligand centre (x,y,z)')
    parser.add_argument('--pocket_radius', type=float, default=8.0,
                        help='Pocket radius (Å); 8 to 10 is typical')
    parser.add_argument('--n_modes', type=int, default=20,
                        help='Number of slowest modes to use')
    parser.add_argument('--output_dir', default='anm_results',
                        help='Output directory')

    args = parser.parse_args()

    ligand_center = None
    if args.ligand_xyz:
        ligand_center = tuple(float(x) for x in args.ligand_xyz.split(','))

    anm, results_df, metrics = analyze_binding_pocket_anm(
        args.pdb, ligand_center, args.pocket_radius, args.n_modes,
        args.output_dir
    )
````

### File: `07_admet_profiling.py`

````python
#!/usr/bin/env python3
"""
Script 7: ADMET Profiling and Drug-Likeness Assessment

Purpose: Compute drug-likeness descriptors (Lipinski's Rule of Five, TPSA,
rule-of-thumb BBB and solubility heuristics). These are not measured ADMET:
no hERG, metabolism, toxicity, or PAINS screen is performed.

Usage:
    python 07_admet_profiling.py --smiles_file compounds.smi \\
                                 --output_csv admet_results.csv
"""

import argparse
import pandas as pd
from rdkit import Chem
from rdkit.Chem import Descriptors, Crippen
import os

from smiles_io import read_smiles

def assess_admet_properties(smiles_list, output_csv='admet_results.csv', 
                           verbose=True):
    """
    Evaluate Lipinski's Rule of Five and ADMET properties for compounds.
    
    Args:
        smiles_list: List of SMILES strings (or filename)
        output_csv: Output CSV file with ADMET results
        verbose: Print progress messages
    
    Returns:
        DataFrame with ADMET properties and drug-likeness assessment
    """
    results = []

    # Stable compound IDs shared with stages 2 and 3 (see smiles_io.py)
    if isinstance(smiles_list, str) and os.path.isfile(smiles_list):
        if verbose:
            print(f"Reading SMILES from {smiles_list}...")
        records = read_smiles(smiles_list)
    else:
        records = list(enumerate(smiles_list))

    if verbose:
        print(f"Assessing {len(records)} compounds...")

    for i, smiles in records:
        mol = Chem.MolFromSmiles(smiles)
        if mol is None:
            continue
        
        # Lipinski's Rule of Five
        mw = Descriptors.MolWt(mol)
        logp = Crippen.MolLogP(mol)
        hbd = Descriptors.NumHDonors(mol)
        hba = Descriptors.NumHAcceptors(mol)
        rotatable_bonds = Descriptors.NumRotatableBonds(mol)
        
        # Count RO5 violations
        ro5_violations = 0
        if mw > 500:
            ro5_violations += 1
        if logp > 5:
            ro5_violations += 1
        if hbd > 5:
            ro5_violations += 1
        if hba > 10:
            ro5_violations += 1
        
        # Drug-likeness classification
        drug_like = 'YES' if ro5_violations <= 1 else 'NO'
        
        # Additional ADMET properties
        tpsa = Descriptors.TPSA(mol)  # Polar surface area (BBB penetration)
        aromatic_rings = Descriptors.NumAromaticRings(mol)
        sp3_fraction = Descriptors.FractionCSP3(mol)
        
        # BBB penetrance prediction (TPSA < 60 and LogP 1-5)
        bbb_penetrant = 'YES' if (tpsa < 60 and 1 < logp < 5) else 'NO'
        
        # Aqueous solubility class (simplified)
        if logp > 5:
            solubility = 'LOW'
        elif logp < 0:
            solubility = 'HIGH'
        else:
            solubility = 'MODERATE'
        
        results.append({
            'compound_id': i,
            'SMILES': smiles,
            'MW_Da': mw,
            'LogP': logp,
            'HBD': hbd,
            'HBA': hba,
            'RotBonds': rotatable_bonds,
            'TPSA_A2': tpsa,
            'AromaRings': aromatic_rings,
            'Sp3Frac': sp3_fraction,
            'RO5_Violations': ro5_violations,
            'Drug_Like': drug_like,
            'BBB_Penetrant': bbb_penetrant,
            'Solubility': solubility
        })
    
    df = pd.DataFrame(results)
    
    # Save results
    df.to_csv(output_csv, index=False)
    
    if verbose:
        print(f"\n✓ ADMET Assessment Complete!")
        print(f"\nSummary Statistics:")
        print(f"  Total compounds evaluated: {len(df)}")
        print(f"  Drug-like (RO5 ≤ 1): {(df['Drug_Like']=='YES').sum()} "
              f"({100*(df['Drug_Like']=='YES').sum()/len(df):.1f}%)")
        print(f"  BBB penetrant: {(df['BBB_Penetrant']=='YES').sum()} "
              f"({100*(df['BBB_Penetrant']=='YES').sum()/len(df):.1f}%)")
        print(f"\nRO5 Violation Distribution:")
        print(df['RO5_Violations'].value_counts().sort_index())
        print(f"\nResults saved: {output_csv}")
    
    return df

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Assess ADMET properties')
    parser.add_argument('--smiles_file', required=True, 
                       help='Input SMILES file or list')
    parser.add_argument('--output_csv', default='admet_results.csv',
                       help='Output CSV file')
    
    args = parser.parse_args()
    
    df = assess_admet_properties(args.smiles_file, args.output_csv)
````

### File: `08_rank_candidates.py`

````python
#!/usr/bin/env python3
"""
Script 8: Multi-Criteria Decision Analysis (MCDA) for Candidate Ranking

Purpose: Combine docking energy, drug-likeness descriptors, and (optionally)
per-compound dynamics into one weighted score.

Terms and default weights:
- Binding energy (0.25): docking score, linearly scaled from -12 to 0 kcal/mol
- Druggability (0.20): Lipinski RO5 violations
- Safety (0.10): LogP proxy only (not a hERG or PAINS screen)
- Synthesis (0.10): ring and rotor count proxy (not SAscore)
- Stability (0.20): RMSD per compound. Needs --dynamics.
- Flexibility (0.15): pocket MSF per compound. Needs --dynamics.

Without --dynamics, stability and flexibility are dropped and the remaining
weights are renormalised. With --dynamics, every docked compound needs a row.

Dynamics CSV columns: compound_id, rmsd (Å), pocket_msf (ANM relative units).

Usage:
    python 08_rank_candidates.py --docking docking_results/docking_results.csv \\
                                 --admet admet_results.csv \\
                                 --dynamics dynamics.csv \\
                                 --output ranked_candidates.csv
"""

import argparse
import os

import pandas as pd

DEFAULT_WEIGHTS = {
    'binding_energy': 0.25,
    'stability': 0.20,
    'flexibility': 0.15,
    'druggability': 0.20,
    'safety': 0.10,
    'synthesis': 0.10,
}
DYNAMICS_TERMS = ('stability', 'flexibility')


def rank_candidates_mcda(docking_df, admet_df, dynamics_dict=None,
                         weights=None, output_csv='ranked_candidates.csv',
                         verbose=True):
    """
    Multi-Criteria Decision Analysis: rank candidates by composite score.

    Args:
        docking_df: DataFrame with compound_id, binding_energy_kcal_mol
        admet_df: DataFrame with compound_id, SMILES, LogP, RO5_Violations, AromaRings, RotBonds
        dynamics_dict: Dict compound_id -> {'rmsd': float, 'pocket_msf': float}, or None
        weights: Dict of criterion weights (defaults above if None)
        output_csv: Output CSV file
        verbose: Print progress

    Returns:
        Ranked DataFrame
    """
    if docking_df.empty:
        raise ValueError("Docking results are empty; nothing to rank. "
                         "Check the skip counts printed by 03_run_docking.py.")

    dynamics_dict = dynamics_dict or {}
    weights = dict(DEFAULT_WEIGHTS if weights is None else weights)

    if dynamics_dict:
        missing = [int(c) for c in docking_df['compound_id'] if int(c) not in dynamics_dict]
        if missing:
            raise ValueError(f"Dynamics missing for {len(missing)} compounds "
                             f"(first few: {missing[:5]}). Provide every compound or omit --dynamics.")
    else:
        for term in DYNAMICS_TERMS:
            weights.pop(term)

    total_weight = sum(weights.values())
    weights = {k: v / total_weight for k, v in weights.items()}

    if verbose:
        print(f"Merging datasets...")
        print(f"  Docking: {len(docking_df)} compounds")
        print(f"  ADMET: {len(admet_df)} compounds")
        print(f"  Dynamics: {len(dynamics_dict)} compounds")
        print(f"  Active terms: {', '.join(weights)}")

    admet_by_id = admet_df.drop_duplicates('compound_id').set_index('compound_id')

    candidates = []
    for _, dock_row in docking_df.iterrows():
        cid = int(dock_row['compound_id'])
        if cid not in admet_by_id.index:
            continue
        admet_row = admet_by_id.loc[cid]

        be = float(dock_row['binding_energy_kcal_mol'])
        be_norm = max(0.0, min(1.0, (be + 12) / 12))

        ro5_viol = int(admet_row['RO5_Violations'])
        druggability = 1.0 if ro5_viol <= 1 else max(0.0, 1.0 - ro5_viol / 3)

        # LogP above 5 is penalised as a crude proxy for hERG risk
        logp = float(admet_row['LogP'])
        safety = 1.0 if logp <= 5 else max(0.3, 1.0 - (logp - 5) / 5)

        # Ring and rotor count as a rough synthesis-effort proxy
        synthesis = max(0.2, min(1.0, 1.0 - (int(admet_row['AromaRings']) + int(admet_row['RotBonds'])) / 20))

        terms = {
            'binding_energy': be_norm,
            'druggability': druggability,
            'safety': safety,
            'synthesis': synthesis,
        }
        row = {
            'compound_id': cid,
            'smiles': admet_row.get('SMILES', ''),
            'binding_energy_kcal_mol': be,
            'logp': logp,
            'ro5_violations': ro5_viol,
        }

        if dynamics_dict:
            dyn = dynamics_dict[cid]
            rmsd = float(dyn['rmsd'])
            msf = float(dyn['pocket_msf'])
            terms['stability'] = max(0.0, 1.0 - rmsd / 3.0)  # assumes RMSD of 3 Å is the worst case
            # Centre 0.8 is unvalidated. Calibrate on your own pocket before relying on this term.
            terms['flexibility'] = 1.0 - abs(msf - 0.8) / 1.5
            row.update({'rmsd': rmsd, 'pocket_msf': msf})

        row.update({f'{k}_score': v for k, v in terms.items()})
        row['composite_score'] = sum(weights[k] * terms[k] for k in weights)
        candidates.append(row)

    if not candidates:
        raise ValueError("No docked compound has a matching ADMET row. Check that compound IDs "
                         "come from the same SMILES file (see smiles_io.py).")

    df_ranked = pd.DataFrame(candidates).sort_values('composite_score', ascending=False)
    df_ranked.insert(0, 'rank_order', range(1, len(df_ranked) + 1))
    df_ranked.to_csv(output_csv, index=False)

    if verbose:
        print(f"\n✓ Ranking complete ({len(df_ranked)} compounds):")
        print(df_ranked[['rank_order', 'compound_id', 'binding_energy_kcal_mol',
                         'composite_score']].head(10).to_string(index=False))
        print(f"\nResults saved: {output_csv}")

    return df_ranked


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Rank candidates via MCDA')
    parser.add_argument('--docking', required=True, help='Docking results CSV')
    parser.add_argument('--admet', required=True, help='ADMET results CSV')
    parser.add_argument('--dynamics', help='Per-compound dynamics CSV (compound_id, rmsd, pocket_msf)')
    parser.add_argument('--output', default='ranked_candidates.csv', help='Output CSV file')

    args = parser.parse_args()

    docking_df = pd.read_csv(args.docking)
    admet_df = pd.read_csv(args.admet)

    dynamics_dict = None
    if args.dynamics:
        if not os.path.isfile(args.dynamics) or not args.dynamics.endswith('.csv'):
            raise ValueError(f"--dynamics must be an existing .csv file: {args.dynamics}")
        dyn_df = pd.read_csv(args.dynamics)
        dynamics_dict = {int(row['compound_id']): row.to_dict() for _, row in dyn_df.iterrows()}

    rank_candidates_mcda(docking_df, admet_df, dynamics_dict, output_csv=args.output)
````

### File: `smiles_io.py`

````python
"""
Shared SMILES reader. Gives every compound one stable ID across pipeline stages.

Stages 2 (library prep), 3 (docking) and 7 (ADMET) must agree on compound IDs,
or stage 8 joins the wrong rows. The ID is the 0-based position among SMILES
records, after skipping blank lines and '#' comments.
"""


def read_smiles(path):
    """Return [(compound_id, smiles), ...] for each record in a .smi file."""
    records = []
    with open(path) as f:
        for line in f:
            text = line.strip()
            if not text or text.startswith('#'):
                continue
            records.append((len(records), text.split()[0]))
    return records
````

### File: `test_pipeline_fixes.py`

````python
#!/usr/bin/env python3
"""
Self-check for the pipeline fixes. Run from this folder:
    python test_pipeline_fixes.py

Covers logic that does not need ProDy, OpenMM, or Vina: compound IDs,
library prep, Vina output parsing, ADMET IDs, and MCDA weighting.
"""

import importlib
import os
import tempfile

import pandas as pd
from rdkit import Chem

from smiles_io import read_smiles

HERE = os.path.dirname(os.path.abspath(__file__))
SAMPLE = os.path.join(HERE, 'sample_compounds.smi')

lib = importlib.import_module('02_prepare_library')
admet = importlib.import_module('07_admet_profiling')
docking = importlib.import_module('03_run_docking')
ranking = importlib.import_module('08_rank_candidates')


def test_read_smiles_skips_comments_and_numbers_stably():
    records = read_smiles(SAMPLE)
    assert records, "sample file produced no records"
    assert [cid for cid, _ in records] == list(range(len(records)))
    assert all(not s.startswith('#') for _, s in records)


def test_library_prep_keeps_stable_ids():
    ids = {cid for cid, _ in read_smiles(SAMPLE)}
    with tempfile.TemporaryDirectory() as tmp:
        sdf = os.path.join(tmp, 'lib.sdf')
        _, n_out, stats = lib.prepare_ligand_library(SAMPLE, sdf, verbose=False)
        assert n_out > 0, f"nothing retained: {stats}"
        seen = [int(m.GetIntProp('compound_id')) for m in Chem.SDMolSupplier(sdf) if m]
    assert len(seen) == n_out
    assert set(seen) <= ids


def test_vina_affinity_parsed_from_remark_line():
    with tempfile.TemporaryDirectory() as tmp:
        out = os.path.join(tmp, 'out.pdbqt')
        with open(out, 'w') as f:
            f.write("MODEL 1\nREMARK VINA RESULT:    -7.2      0.000      0.000\nENDMDL\n")
        assert docking.read_vina_affinity(out) == -7.2
        empty = os.path.join(tmp, 'empty.pdbqt')
        open(empty, 'w').close()
        assert docking.read_vina_affinity(empty) is None


def test_docking_refuses_to_run_without_vina():
    saved = os.environ.get('PATH', '')
    os.environ['PATH'] = ''
    try:
        raised = False
        try:
            docking.run_vina_docking('r.pdbqt', SAMPLE, (0, 0, 0), (20, 20, 20),
                                     output_dir=tempfile.mkdtemp(), verbose=False)
        except FileNotFoundError:
            raised = True
        assert raised, "expected FileNotFoundError when vina is missing"
    finally:
        os.environ['PATH'] = saved


def test_admet_ids_match_library_ids():
    with tempfile.TemporaryDirectory() as tmp:
        out = os.path.join(tmp, 'admet.csv')
        df = admet.assess_admet_properties(SAMPLE, out, verbose=False)
    valid = [cid for cid, s in read_smiles(SAMPLE) if Chem.MolFromSmiles(s) is not None]
    assert list(df['compound_id']) == valid


def _toy_inputs():
    docking_df = pd.DataFrame({'compound_id': [0, 1],
                               'binding_energy_kcal_mol': [-9.0, -7.0]})
    admet_df = pd.DataFrame({'compound_id': [0, 1], 'SMILES': ['C', 'CC'],
                             'LogP': [1.0, 2.0], 'RO5_Violations': [0, 0],
                             'AromaRings': [1, 0], 'RotBonds': [0, 1]})
    return docking_df, admet_df


def test_ranking_drops_dynamics_terms_without_dynamics():
    docking_df, admet_df = _toy_inputs()
    with tempfile.TemporaryDirectory() as tmp:
        df = ranking.rank_candidates_mcda(docking_df, admet_df, None,
                                          output_csv=os.path.join(tmp, 'r.csv'), verbose=False)
    assert 'stability_score' not in df.columns
    assert 'flexibility_score' not in df.columns
    assert df['composite_score'].between(0, 1).all()


def test_ranking_requires_full_dynamics_coverage():
    docking_df, admet_df = _toy_inputs()
    dyn = {0: {'rmsd': 1.0, 'pocket_msf': 0.8}}  # compound 1 missing
    try:
        ranking.rank_candidates_mcda(docking_df, admet_df, dyn,
                                     output_csv=os.devnull, verbose=False)
    except ValueError as err:
        assert 'missing' in str(err)
    else:
        raise AssertionError("expected ValueError for incomplete dynamics")


def test_ranking_rejects_empty_docking():
    _, admet_df = _toy_inputs()
    try:
        ranking.rank_candidates_mcda(pd.DataFrame(columns=['compound_id', 'binding_energy_kcal_mol']),
                                     admet_df, output_csv=os.devnull, verbose=False)
    except ValueError:
        return
    raise AssertionError("expected ValueError for empty docking results")


if __name__ == '__main__':
    tests = [v for k, v in dict(globals()).items() if k.startswith('test_')]
    for t in tests:
        t()
        print(f"PASS {t.__name__}")
    print(f"\n{len(tests)} checks passed.")
````

### File: `sample_compounds.smi`

````text
# Sample SMILES File for Testing
# Example compounds for testing the pipeline
# File: sample_compounds.smi

# Anti-inflammatory drugs (test set)
CC(C)Cc1ccc(cc1)C(C)C(O)=O
CC(=O)Oc1ccccc1C(=O)O
CN1C(=O)CC(c2ccc(cc2)S(=O)(=O)N)C1=O
c1ccc2c(c1)cc(cn2)S(=O)(=O)N
C1=CC=C(C=C1)C2=CC(=NN2C3=CC=C(C=C3)S(=O)(=O)N)C(F)(F)F

# Known kinase inhibitors (for positive control)
CN1C=NC2=C1C(=O)N(C)C(=O)N2C
CC(C)Cc1ccc(cc1)c2ccc(Cl)c(Cl)c2
c1cc2ncccc2[nH]1

# GPCR ligands (for CXCR4/CCR5 screening)
CC(C)Nc1ccc(cc1)c2cccnc2
Cl.Cl.c1cc(ccc1)CCN
CC(C)NCC(O)COc1ccc(cc1)c2cccnc2
````


---

# Appendix B: Extraction script

Save as `extract_files.py`. Usage: `python extract_files.py skill.md <target_folder>`.

````python
import re
import pathlib
import sys

src = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
dst = pathlib.Path(sys.argv[2])
dst.mkdir(parents=True, exist_ok=True)
for name, body in re.findall(r"### File: `([^`]+)`\n\n````\w*\n(.*?)\n````", src, re.S):
    (dst / name).write_text(body + "\n", encoding="utf-8")
    print("wrote", dst / name)
````
