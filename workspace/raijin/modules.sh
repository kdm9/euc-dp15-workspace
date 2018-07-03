module load adapterremoval nextgenmap/0.5.5 samtools bcftools htslib freebayes/v1.2.0 snakemake
module load bwa angsd plink19 mash khmer kwip pigz seqhax R/3.4.3 stampy sra-toolkit vt sourmash gatk4
export TMPDIR=${PBS_JOBFS:-/tmp}
