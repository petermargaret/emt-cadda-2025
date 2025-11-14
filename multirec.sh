#!/usr/bin/env bash
set -e
shopt -s nullglob  # ensures no literal wildcards if folder is empty

mkdir -p poses
summary_file="energies_summary.csv"
echo "Receptor,Ligand,Affinity(kcal/mol)" > "$summary_file"

# Loop through receptor files
for receptor in receptors/*.pdbqt; do
    [ -e "$receptor" ] || { echo "❌ No receptor files found in receptors/"; exit 1; }

    receptor_name=$(basename "$receptor" .pdbqt)
    out_dir="poses/$receptor_name"
    mkdir -p "$out_dir"

    echo "============================================="
    echo "Processing receptor: $receptor_name"
    echo "============================================="

    # Loop through ligand files
    for ligand in ligands/*.pdbqt; do
        [ -e "$ligand" ] || { echo "❌ No ligands found in ligands/"; exit 1; }

        ligand_name=$(basename "$ligand" .pdbqt)
        log_file="$out_dir/${ligand_name}_log.txt"

        echo "→ Docking $ligand_name to $receptor_name ..."
        vina --receptor "$receptor" \
             --ligand "$ligand" \
             --config config.txt \
             --out "$out_dir/${ligand_name}_out.pdbqt" \
             | tee "$log_file"

        if [ -f "$log_file" ]; then
            affinity=$(grep -m 1 "^   1 " "$log_file" | awk '{print $2}')
            if [ -n "$affinity" ]; then
                echo "$receptor_name,$ligand_name,$affinity" >> "$summary_file"
                echo "✅  $ligand_name: $affinity kcal/mol"
            else
                echo "$receptor_name,$ligand_name,NO_ENERGY" >> "$summary_file"
                echo "⚠️  $ligand_name: no energy found"
            fi
        else
            echo "$receptor_name,$ligand_name,FAILED" >> "$summary_file"
            echo "⚠️  $ligand_name: log not created"
        fi
    done
done

echo "============================================="
echo " Docking complete!"
echo " Summary written to: $summary_file"
echo "============================================="
