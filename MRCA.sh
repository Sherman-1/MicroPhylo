#!/usr/bin/bash

#PBS -N UniMicroLCA
#PBS -q bim 
#PBS -l ncpus=8
#PBS -l mem=32Gb 
#PBS -l walltime=72:00:00
#PBS -koed

total=$(wc -l < Uniprot_micro_taxids.csv)

cat Uniprot_micro_taxids.csv | tqdm --total=$total --unit lines --unit_scale --desc "Processing TaxIDs" | while IFS=";" read -r identifier taxids; do
    if [[ -n "$taxids" ]]; then  
        result=$(echo "$taxids" | taxonkit lca -b 500M --skip-deleted --skip-unfound --threads 4 2> /dev/null)  
        last_field=$(echo "$result" | awk '{print $NF}')  
        echo "$identifier : $last_field" >> lcas.csv  
    fi
done

# For some reason some lines are duplicated ??
sort -u lcas.txt > tmp 
cat tmp > lcas.txt && rm tmp 
