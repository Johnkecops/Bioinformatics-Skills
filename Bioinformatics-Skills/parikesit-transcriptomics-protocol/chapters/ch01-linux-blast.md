# Chapter 1: BLAST Tutorial in Linux Ubuntu

## Core Idea
Learn the minimal Linux shell toolkit, then build local BLAST protein databases from RefSeq proteomes and run query-vs-database and all-vs-all BLASTP comparisons (zebrafish vs mouse).

## Frameworks Introduced
- **Ubuntu Command List**: the 15 commands a student needs before any bioinformatics tool (see table).
- **Download → Uncompress → Format DB → Query** workflow for local BLAST
  - When to use: any local homology search against a custom proteome
  - How: `wget` FASTA → `gunzip` → `makeblastdb -dbtype prot` → `blastp`
- **Background-and-monitor**: run long jobs with `&`, estimate progress by counting processed queries vs total queries.

## Key Concepts
- **.faa**: FASTA amino-acid file; **.gz** is single-file compression (`gunzip *.gz`).
- **makeblastdb**: converts a FASTA into an indexed BLAST database (`-dbtype prot` for proteins).
- **blastp**: protein query vs protein database.
- **-evalue**: significance threshold; e.g. `1e-6` keeps only strong hits.
- **Pipe `|`**: sends output of one command to another.
- **`wc -l`**: counts lines only.
- **`&`**: run command in background, returning the prompt.
- **`more`**: pager — Enter to advance, `q` to quit.

## Reference Tables

| Command | Function |
|---|---|
| `mkdir dir` | create directory |
| `touch file` | create file |
| `mv old new` | rename |
| `sudo gedit path/file` | edit in gedit |
| `ls` / `ls -a` | list files / include hidden |
| `rm -r dir` | delete directory |
| `rm file` / `rm *` | delete file / all files in cwd |
| `clear` | clear terminal |
| `pwd` | print current path |
| `cd ~` / `cd dir` | home / change directory |
| `grep` | search text in file |
| `cp src dst` | copy file/dir |

## Code Examples
```bash
mkdir BlastData && cd BlastData
wget ftp://ftp.ncbi.nlm.nih.gov/refseq/M_musculus/mRNA_Prot/mouse.1.protein.faa.gz
wget ftp://ftp.ncbi.nlm.nih.gov/refseq/D_rerio/mRNA_Prot/zebrafish.1.protein.faa.gz
gunzip *.gz
makeblastdb -in mouse.1.protein.faa -dbtype prot
makeblastdb -in zebrafish.1.protein.faa -dbtype prot
head -3 zebrafish.1.protein.faa > zebrafish.top          # one complete FASTA record
blastp -query zebrafish.top -db mouse.1.protein.faa -evalue 1e-6 -out xxx.txt
more xxx.txt
# all-vs-all, background
blastp -query zebrafish.1.protein.faa -db mouse.1.protein.faa -out zebrafish.x.mouse &
grep Query= zebrafish.x.mouse | wc -l                    # processed so far (209 → 738 after 5 min)
grep '^>' zebrafish.1.protein.faa | wc -l                # total queries
blastp -query mouse.1.protein.faa -db zebrafish.1.protein.faa -out mouse.x.zebrafish &
```
- **What it demonstrates**: complete local reciprocal BLAST setup with progress monitoring.

## Anti-patterns
- **Copying en-dashes from the PDF** (`–in`, `rm –r`): shell rejects them; retype as `-`.
- **Truncated FASTA query**: `head -N` must cover the full record (header + all sequence lines) or the query is cut.
- **Running all-vs-all in foreground**: blocks terminal for hours; use `&` (or `nohup`/`-num_threads`).
- **Filename drift**: PDF writes `zebrafish.protein.faa` once; real file is `zebrafish.1.protein.faa`.

## Key Takeaways
1. Always `pwd` and `ls` before creating/moving files.
2. Format each proteome with `makeblastdb` before using it as `-db`.
3. Tighten hits with `-evalue 1e-6`.
4. Two all-vs-all runs (A→B and B→A) set up reciprocal-best-hit ortholog inference.
5. Monitor background BLAST by counting `Query=` lines.

## Connects To
- **Ch 2–3**: same shell skills for Bowtie/TopHat.
- **Reciprocal best hits (RBH)**: standard ortholog method built on the two all-vs-all outputs.
