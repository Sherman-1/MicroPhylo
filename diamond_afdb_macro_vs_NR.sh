#!/usr/bin/bash 

#PBS -N AFDB_macro_vs_NR
#PBS -k oe
#PBS -q bim 
#PBS -l host=node04
#PBS -l ncpus=32
#PBS -l mem=200gb
#PBS -l walltime=10000:00:00
#PBS -M herman.simon.lm@gmail.com 


if [ ! -d "/datas" ]; then
  echo "Datas directory not found"
  exit 1
fi


if [ ! -d "/datas/SIMON/tmp" ]; then
  mkdir -p /datas/SIMON/tmp
fi

if ! command -v diamond &> /dev/null; then
  echo "diamond could not be found"
  exit 1
fi

# Check if duckdb is available
if ! command -v duckdb &> /dev/null; then
  echo "duckdb could not be found"
  exit 1
fi

cd /store/EQUIPES/BIM/MEMBERS/simon.herman/MicroPhylo

file_paths=(
  "/store/EQUIPES/BIM/MEMBERS/simon.herman/MicroPhylo/afdb_macro_sample.fasta"
)

for fasta in "${file_paths[@]}"; do
  out_file=$(basename "$fasta")
  out_file="${out_file%.*}"
  out_file="${out_file}_vs_NR"

  diamond_2.0.13 blastp --query "$fasta" --db /datas/NR/nr_2.0.13.dmnd \
    --sensitive --evalue 0.001 \
    --out /datas/SIMON/tmp/tmp.tsv \
    --outfmt 6 qseqid sseqid evalue qcovhsp scovhsp length pident staxids \
    --max-target-seqs 0 \
    --tmpdir /datas/SIMON/tmp --threads 32 --log

	# Filter the output file
  awk -F"\t" '{if($4 >= 70 && $5 >= 70 && $7 >= 30) print $0}' /datas/SIMON/tmp/tmp.tsv > /datas/SIMON/tmp/tmp_filtered.tsv


  sed -i '1i qseqid\tsseqid\tevalue\tqcovhsp\tscovhsp\tlength\tpident\tstaxids' /datas/SIMON/tmp/tmp_filtered.tsv
  duckdb -c "COPY (SELECT * FROM read_csv_auto('/datas/SIMON/tmp/tmp_filtered.tsv', delim='\t')) TO '/datas/SIMON/tmp/"$out_file".parquet' (FORMAT 'parquet', COMPRESSION 'gzip');"
  rm /datas/SIMON/tmp/tmp*.tsv
  mv /datas/SIMON/tmp/"$out_file".parquet /store/EQUIPES/BIM/MEMBERS/simon.herman/MicroPhylo

done
