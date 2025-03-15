#!/bin/bash
#PBS -q bim 
#PBS -l host=node04
#PBS -l ncpus=48
#PBS -l mem=250Gb 
#PBS -l walltime=100:00:00
#PBS -koed


if [ ! -d "/datas" ]; then
  echo "Datas directory not found"
  exit 1
fi


if [ ! -d "/datas/SIMON/tmp" ]; then
  mkdir -p /datas/SIMON/tmp
fi

if ! command -v diamond_2.0.13 &> /dev/null; then
  echo "diamond_2.0.13 could not be found"
  exit 1
fi

# Check if duckdb is available
if ! command -v duckdb &> /dev/null; then
  echo "duckdb could not be found"
  exit 1
fi

cd /store/EQUIPES/BIM/MEMBERS/simon.herman/MicroPhylo

file_paths=(
  "/store/EQUIPES/BIM/MEMBERS/simon.herman/Uniprot/Swissprot_microproteins_simple_header.faa"
  "/store/EQUIPES/BIM/MEMBERS/simon.herman/Uniprot/Trembl_microproteins_sample_simple_header.faa"
)

for fasta in "${file_paths[@]}"; do
  out_file=$(basename "$fasta")
  out_file="${out_file%.*}"
  out_file="${out_file}_vs_NR"

  diamond_2.0.13 blastp --query "$fasta" --db /datas/NR/nr_2.0.13.dmnd \
    --sensitive --evalue 0.001 \
    --out /datas/SIMON/tmp/"$out_file".tsv \
    --outfmt 6 qseqid sseqid evalue qcovhsp scovhsp length pident staxids \
    --max-target-seqs 0 \
    --tmpdir /datas/SIMON/tmp --threads 48 --log

  sed -i '1i qseqid\tsseqid\tevalue\tqcovhsp\tscovhsp\tlength\tpident\tstaxids' /datas/SIMON/tmp/"$out_file".tsv
  duckdb -c "COPY (SELECT * FROM read_csv_auto('/datas/SIMON/tmp/"$out_file".tsv', delim='\t')) TO '/datas/SIMON/tmp/"$out_file".parquet' (FORMAT 'parquet', COMPRESSION 'gzip');"
  rm /datas/SIMON/tmp/"$out_file".tsv
  mv /datas/SIMON/tmp/"$out_file".parquet /store/EQUIPES/BIM/MEMBERS/simon.herman/MicroPhylo

done
