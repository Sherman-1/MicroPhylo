#!/usr/bin/bash 


## csv to flag all eukaryotes if needed
taxonkit list --ids 2759 --indent "" | awk '$1 != "" {print $1";1"}' > eukaryotes.csv


## csv to map all ranks below species to their species
taxonkit list --ids 1 --indent "" | taxonkit filter -L species --discard-noranks \
    | taxonkit reformat -I 1 --format "{s}" --show-lineage-taxids \
    | cut -f 1,3 | awk '{print $1";"$2}' > strain2species.csv

# Don't forget that species are mapping to themselves !
taxonkit list --ids 1 --indent "" | taxonkit filter -E species \
    | awk '{print $1";"$1}' >> strain2species.csv

## List all taxids belonging to others and unclassified 
taxonkit list --indent "" --ids "28384,12908" > badTaxids.txt