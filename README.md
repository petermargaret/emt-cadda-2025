## Automating Multi-Ligand Docking Using Bash and AutoDock Vina(training purpose)
_Author: Peter Margaret_  
_Email: petermargaret25@gmail.com_  
_Phone: +254104095206_  
_Field: Bioinformatics_  
_Institution: University of Nairobi_
## How to use
_Note: Ensure that bash script is located in the directory as given architecture below_
_copy to editor or download and save the first script as: **singlerec.sh (this is for docking multiple ligands on single receptor)**_
_copy to editor or download and save the second script as: **multierec.sh (this is for docking multiple ligands on multiple receptors)**_
_incase of any error, please feel free to contact me_



**Prerequisites**

- PyMOL (requires Schrodinger account)
- ChimeraX-1.8 — https://www.rbvi.ucsf.edu/chimera/download.html
- MGLTools — https://ccsb.scripps.edu/mgltools/downloads/
- Maestro (requires Schrodinger account)
- AutoDock Vina — https://vina.scripps.edu/downloads/
- AutoDock4 and AutoGrid — https://autodock.scripps.edu/download-autodock4/
- PDBFixer — install via Conda:
  ```
  conda install -c conda-forge pdbfixer
  ```
- Compatible OS: Windows, Linux, Unix

---

**Workflow Overview**

```
        ┌──────────────┐
        │   PROT-PREP   │
        └──────┬────────┘
               │
        ┌──────▼──────┐
        │  LIG-PREP    │
        └──────┬───────┘
               │
     ┌─────────▼─────────┐
     │   BATCH DOCKING    │
     └─────────┬─────────┘
               │
     ┌─────────▼─────────┐
     │  RESULTS SUMMARY   │
     └────────────────────┘
```

---
**Protein Preparation**

- Download PDB from RCSB
- Check chains present
- Inspect HETATM
- Add polar hydrogens
- Add/distribute charges
- Save as `.pdbqt`

---

**Ligand Preparation**

- Add charges
- Check rotatable bonds
- Save as `.pdbqt`

---

**Directory Architecture**
```
emt-cadda-2025/
│
├── receptors/(folder where receptors are stored)
│      ├── 4ey7.pdbqt
│      ├── 4ey8.pdbqt
│
├── ligands/(folder where ligands are stored)
│      ├── lig1.pdbqt
│      ├── lig2.pdbqt
│
├── poses/(folder where results will be written - this will automatically be created by the script)
│
├── config.txt(coordinates for active site)
│
├── singlrec.sh
└── multirec.sh
```

---

**config.txt**

```
center_x = -14.1
center_y = -43.8
center_z = 27.7

size_x = 20
size_y = 20
size_z = 20

exhaustiveness = 16
num_modes = 10
energy_range = 3
```

---

## BATCH DOCKING

**1. Single Receptor – Multiple Ligands**

Vina batch command
```
vina --receptor receptor.pdbqt --batch ligands/name_*.pdbqt --config config.txt --dir poses
```

**OR Bash script**
```bash
#!/usr/bin/env bash
# Paths
receptor="4ey7.pdbqt"
ligand_dir="ligands"
out_dir="poses"
config="config.txt"

mkdir -p "$out_dir"

for ligand in "$ligand_dir"/*.pdbqt; do
    ligand_name=$(basename "$ligand" .pdbqt)
    echo "Docking ligand: $ligand_name"

    vina --receptor "$receptor" \
         --ligand "$ligand" \
         --config "$config" \
         --out "$out_dir/${ligand_name}_out.pdbqt"
done

echo "All ligands docked."
```

---

**2. Multiple Receptors – Multiple Ligands**

```bash
#!/usr/bin/env bash
set -e
shopt -s nullglob

mkdir -p poses
summary_file="energies_summary.csv"
echo "Receptor,Ligand,Affinity(kcal/mol)" > "$summary_file"

for receptor in receptors/*.pdbqt; do
    [ -e "$receptor" ] || { echo "No receptor files found"; exit 1; }

    receptor_name=$(basename "$receptor" .pdbqt)
    out_dir="poses/$receptor_name"
    mkdir -p "$out_dir"

    echo "Processing receptor: $receptor_name"

    for ligand in ligands/*.pdbqt; do
        [ -e "$ligand" ] || { echo "No ligands found"; exit 1; }

        ligand_name=$(basename "$ligand" .pdbqt)
        log_file="$out_dir/${ligand_name}_log.txt"

        echo "Docking $ligand_name to $receptor_name ..."
        vina --receptor "$receptor" \
             --ligand "$ligand" \
             --config config.txt \
             --out "$out_dir/${ligand_name}_out.pdbqt" \
             | tee "$log_file"

        if [ -f "$log_file" ]; then
            affinity=$(grep -m 1 "^   1 " "$log_file" | awk '{print $2}')
            if [ -n "$affinity" ]; then
                echo "$receptor_name,$ligand_name,$affinity" >> "$summary_file"
            else
                echo "$receptor_name,$ligand_name,NO_ENERGY" >> "$summary_file"
            fi
        else
            echo "$receptor_name,$ligand_name,FAILED" >> "$summary_file"
        fi
    done
done

echo "Docking complete. Summary written to: $summary_file"
```

---

**VisualizationN**

**PyMOL**
```
load receptor.pdbqt
load poses/receptor1/lig1_out.pdbqt
show cartoon, receptor
show sticks, lig1_out
bg_color white
```

**ChimeraX**
```
open receptor.pdbqt
open poses/receptor1/lig1_out.pdbqt
cartoon
style ligand sticks
color ligand green
save docking_view.png
```

---

**Outpt Files**

- Docked poses: `poses/<receptor>/<ligand>_out.pdbqt`
- Log files: `poses/<receptor>/<ligand>_log.txt`
- Summary table: `energies_summary.csv`

Example:
```
Receptor,Ligand,Affinity(kcal/mol)
4ey7,lig1,-9.3
4ey7,lig2,-8.5
```

---

