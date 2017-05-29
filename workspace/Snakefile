import yaml
configfile: "config.yml"

SAMPLES = yaml.load(open("rawdata/samples.yml"))
SAMPLES_NOBLANK = [s for s in SAMPLES if not s.lower().startswith("blank")]

rule all:
    input:
        expand("data/reads/{sample}.fastq.gz", sample=SAMPLES),
        expand("data/alignments/ngm/{ref}/{sample}.bam", ref=config["mapping"]["ref"],
               sample=SAMPLES),
        expand("data/alignments/ngm/{ref}_merged.bam", ref=config["mapping"]["ref"]),
        expand("data/variants/freebayes/{ref}.bcf", ref=config["mapping"]["ref"]),
        "data/readstats/readnum.tsv",
        "data/readstats/unique-kmers.tsv",

rule qcreads:
    input:
        r1=lambda wc: SAMPLES[wc.sample]["R1"],
        r2=lambda wc: SAMPLES[wc.sample]["R2"],
    output:
        reads="data/reads/{sample}.fastq.gz",
        settings="data/log/adapterremoval/{sample}_settings.txt",
    log:
        "data/log/adapterremoval/{sample}.log",
    threads:
        2
    params:
        adp1=config["qc"]["adapter1"],
        adp2=config["qc"]["adapter2"],
    shell:
        "AdapterRemoval"
        "   --file1 <(cat {input.r1})"
        "   --file2 <(cat {input.r2})"
        "   --adapter1 {params.adp1}"
        "   --adapter2 {params.adp2}"
        "   --combined-output"
        "   --interleaved-output"
        "   --gzip"
        "   --collapse"
        "   --trimns"
        "   --trimqualities"
        "   --threads {threads}"
        "   --settings {output.settings}"
        "   --output1 {output.reads}"
        " >{log} 2>&1"

rule read_count:
    input:
        expand("data/reads/{sample}.fastq.gz", sample=SAMPLES),
    output:
        "data/readstats/readnum.tsv",
    threads:
        16
    log:
        "data/log/readstats/seqhax-stats.log",
    shell:
        "( seqhax stats"
        "    -t {threads}"
        "    {input}"
        "    >{output}"
        " ) 2>{log}"

rule unique_kmers:
    input:
        expand("data/reads/{sample}.fastq.gz", sample=SAMPLES),
    output:
        "data/readstats/unique-kmers.tsv",
    threads:
        16
    params:
        kmersize=31,
    log:
        "data/log/readstats/unique-kmers.log",
    shell:
        "( kdm-unique-kmers.py"
        "    -t {threads}"
        "    -k {params.kmersize}"
        "    {input}"
        "    >{output}"
        " ) 2>{log}"

rule ngmap:
    input:
        reads="data/reads/{sample}.fastq.gz",
        ref=lambda wc: config['refs'][wc.ref]
    output:
        bam="data/alignments/ngm/{ref}/{sample}.bam",
        bai="data/alignments/ngm/{ref}/{sample}.bam.bai",
    log:
        "data/log/ngm/{ref}_{sample}.log"
    threads:
        16
    shell:
        "( ngm"
        "   -q {input.reads}"
        "   -p" # paired input
        "   -r {input.ref}"
        "   -t {threads}"
        "   --rg-id {wildcards.sample}"
        "   --rg-sm {wildcards.sample}"
        "   --very-sensitive"
        " | samtools view -Suh -"
        " | samtools sort"
        "   -T ${{TMPDIR:-/tmp}}/{wildcards.sample}"
        "   -@ {threads}"
        "   -m 1G"
        "   -o {output.bam}"
        "   -" # stdin
        " && samtools index {output.bam}"
        " ) >{log} 2>&1"

rule mergebam:
    input:
        expand("data/alignments/ngm/{{ref}}/{sample}.bam", sample=SAMPLES),
    output:
        bam="data/alignments/ngm/{ref}_merged.bam",
        bai="data/alignments/ngm/{ref}_merged.bam.bai",
    log:
        "data/log/mergebam/{ref}.log"
    threads: 16
    shell:
        "( samtools merge"
        "   -@ {threads}"
        "   {output.bam}"
        "   {input}"
        " && samtools index {output.bam}"
        " ) >{log} 2>&1"

rule freebayes:
    input:
        bam="data/alignments/ngm/{ref}_merged.bam",
        bai="data/alignments/ngm/{ref}_merged.bam.bai",
        ref=lambda wc: config['refs'][wc.ref],
    output:
        bcf="data/variants/freebayes/{ref}.bcf",
    log:
        "data/log/freebayes/{ref}.log"
    threads: 16
    shell:
        "( freebayes-parallel"
        "   {input.ref}"
        "   {threads}"
        "   -f {input.ref}"
        "   {input.bam}"
        " | bcftools view"
        "   -O b"
        "   -o {output.bcf}"
        " ) >{log} 2>&1"


rule angsd_plink:
    input:
        bams=expand("data/alignments/{{aligner}}/{{ref}}/{sample}.bam", sample=SAMPLES_NOBLANK),
        ref=lambda wc: config['refs'][wc.ref],
    output:
        tped="data/angsd/plink/{aligner}/{ref}/all-samples.tped"
    threads: 16
    shell:
        "angsd "
        "   -nThreads {threads}"
        "   -bam <(echo {input})"
        "   -out $(basename {output.tped} .tped)"
        "   -ref {input.ref}"
        "   -anc {input.ref}"
        "   -GL 2 -doMajorMinor 1 -doGlf 2 -doMaf 2 -doGeno 4 -doPlink 2"
        "   -skipTriallelic 1 -C 50 -baq 1 -minMapQ 30 -minQ 20 -SNP_pval 1e-3 -doPost 1"

