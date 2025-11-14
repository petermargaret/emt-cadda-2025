#!/usr/bin/env bash
# Paths
receptor="4ey7.pdbqt"
ligand_dir="ligands"
out_dir="poses"
config="config.txt"

mkdir -p "$out_dir"

# Loop over ligands
for ligand in "$ligand_dir"/*.pdbqt; do
    ligand_name=$(basename "$ligand" .pdbqt)
    
    # Print ligand being docked
    echo "Docking ligand: $ligand_name"
    
    # Dock
    vina --receptor "$receptor" \
         --ligand "$ligand" \
         --config "$config" \
         --out "$out_dir/${ligand_name}_out.pdbqt"
done

echo "All ligands docked."