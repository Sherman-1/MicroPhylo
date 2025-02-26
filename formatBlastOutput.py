import polars as pl 
from pathlib import Path

def blast_to_taxids(lf : pl.LazyFrame, output_file : Path, eager : bool = False) -> None:

    query = (
        lf
        .group_by(
            "qseqid"
        ).agg(pl.col("staxids")).with_columns(
            pl.col("staxids").list.unique().list.join(" ")
        ).select(["qseqid","staxids"])
    )

    if eager:
        query.collect().write_csv(f"{output_file}.csv", separator = ";", include_header = False)
    else:
        query.collect(streaming=True).write_csv(f"{output_file}.csv", separator = ";", include_header = False)

def format_blast_output(blast_path : Path, bad_taxids : list = None, species_mapping : dict = None) -> pl.LazyFrame:

    if blast_path.suffix == ".tsv":
        lf = pl.scan_csv(blast_path, separator = "\t")
    elif blast_path.suffix == ".csv":
        lf = pl.scan_csv(blast_path)
    elif blast_path.suffix == ".parquet":
        lf = pl.scan_parquet(blast_path)
    else:
        exit("File format not supported")

    return (
        lf.filter(
                (pl.col("evalue") < 1e-4) & 
                (pl.col("qcovhsp") >= 70) & 
                (pl.col("scovhsp") >= 70)
            )
        .with_columns(
            pl.col("staxids").str.split(";")
            )
        .explode("staxids")
        .filter(~pl.col("staxids").is_in(bad_taxids))
        .with_columns(
            staxids = pl.col("staxids").replace_strict(species_mapping)
        )
    )

if __name__ == "__main__":

    import argparse

    parser = argparse.ArgumentParser()

    parser.add_argument("--input", type=str, help = "Blast output")
    parser.add_argument("--output", type=str, help="File to be written")
    parser.add_argument("--species_mapping", type=str, help="Species mapping file", default = None)
    parser.add_argument("--bad_taxids", type=str, help="File with bad taxids", default = None)
    parser.add_argument("--eager", action="store_true", help="Eager evaluation", default = False)

    args = parser.parse_args()

    species_mapping = {}
    if args.species_mapping:
        with open(args.species_mapping, 'r') as f:
            for line in f:
                key, value = line.strip().split(';')
                species_mapping[key] = value

    bad_taxids = []
    if args.bad_taxids:
        with open(args.bad_taxids, 'r') as f:
            bad_taxids = [line.strip() for line in f]

    # Format the blast output
    lf = format_blast_output(Path(args.input), bad_taxids, species_mapping)

    # Convert to taxids and write to output file
    blast_to_taxids(lf, Path(args.output), args.eager)