#!/usr/bin/env bash

#PBS -N Hits_Macro
#PBS -koed
#PBS -q bim 
#PBS -l host=node04
#PBS -l ncpus=2
#PBS -l mem=64Gb
#PBS -l walltime=24:00:00
#PBS -M herman.simon.lm@gmail.com 


# Macro hits filtered beforehand for evalue 1e-5, covs 70, iden 30 !!! 

cd /datas/SIMON/tmp

input_file="filtered.tsv"
output_file="Macro_vs_NR_hits.tsv"

awk '
NR == 1 { next } {
  n = split($8, taxarr, ";");
  hits[$1] += n;
}
END {

  for (q in hits) {
    print q, hits[q];
  }
}' "$input_file" > "$output_file"
