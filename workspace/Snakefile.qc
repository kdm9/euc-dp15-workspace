import snkmk
import yaml
configfile: "config.yml"

RUN2FILE = yaml.load(open("rawdata/samples.yml"))
SAMPLE2RUN = snkmk.make_sample2run()

rule reads:
    input:
        expand("data/reads/samples/{sample}.fastq.gz", sample=SAMPLE2RUN),

rule all:
    input:
        expand("data/reads/samples/{sample}.fastq.gz", sample=SAMPLE2RUN),
        "data/readstats/readnum.tsv",
        "data/readstats/unique-kmers.tsv",


def expand_sample_to_files(wc, read):
    files = []
    for run in SAMPLE2RUN[wc.sample]:
        for f in RUN2FILE[run][read]:
            files.append(f)
    return files


rule qcreads:
    input:
        r1=lambda wc: RUN2FILE[wc.run]["R1"],
        r2=lambda wc: RUN2FILE[wc.run]["R2"],
    output:
        reads="data/reads/runs/{run}.fastq.gz",
    log:
        log="data/log/adapterremoval/{run}.log",
        settings="data/stats/adapterremoval/{run}.txt",
    threads:
        8
    params:
        adp1=config["qc"]["adapter1"],
        adp2=config["qc"]["adapter2"],
        minqual=config["qc"]["minqual"],
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
        "   --minquality {params.minqual}"
        "   --threads {threads}"
        "   --settings {log.settings}"
        "   --output1 {output.reads}"
        " >{log.log} 2>&1"

rule poolreads:
    input:
        reads=lambda wc: expand("data/reads/runs/{run}.fastq.gz", run=SAMPLE2RUN[wc.sample]),
    output:
        reads="data/reads/samples/{sample}.fastq.gz",
    threads: 16
    shell:
        "zcat {input} | pigz -p {threads} -7 >{output}"

rule read_count:
    input:
        expand("data/reads/runs/{run}.fastq.gz", run=RUN2FILE),
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
        expand("data/reads/runs/{run}.fastq.gz", run=RUN2FILE),
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
