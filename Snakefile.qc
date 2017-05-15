import yaml
configfile: "config.yml"

SAMPLES = yaml.load(open("rawdata/samples.yml"))

rule all:
    input:
        expand("data/reads/{sample}.fastq.gz", sample=SAMPLES),
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
