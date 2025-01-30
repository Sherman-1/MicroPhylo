#!/bin/bash
#PBS -q bim 
#PBS -l host=node04
#PBS -l ncpus=32
#PBS -l mem=128Gb 
#PBS -l walltime=10000:00:00
#PBS -koed 



if [ ! -d "/datas" ]; then
  echo "Datas directory not found"
  exit
fi


fasta="/store/EQUIPES/BIM/MEMBERS/simon.herman/Uniprot/trembl_20_100_sample_simple_headers.faa"



diamond_2.0.13 blastp --query "$fasta" --db /datas/NR/nr_2.0.13.dmnd --ultra-sensitive --out Uniprot_micro_vs_NR_tsv --outfmt 6 qseqid sseqid qlen slen qstart sstart qcovhsp scovhsp length pident nident mismatch staxids --max-target-seqs 0 --max-hsps 0 --tmpdir /datas/SIMON/tmp --threads 32