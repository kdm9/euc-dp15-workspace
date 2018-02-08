#!/bin/bash
#PBS -q expressbw
#PBS -l ncpus=28
#PBS -l walltime=8:00:00
#PBS -l mem=20G
#PBS -l jobfs=400G
#PBS -l other=gdata1
#PBS -l wd
#PBS -M kevin@kdmurray.id.au
#PBS -m abe
#PBS -P xe2

source /g/data1/xe2/.profile

export TMPDIR=$PBS_JOBFS

module load mash seqhax parallel

mkdir -p sketches/
dir=/g/data/xe2/datasets/rose-andrew/rawdata/runs/
( for pl in $(ls $dir)
do
    for lib in $(ls $dir/$pl/*_R1.fastq.gz)
    do
        lib=$(basename $lib _R1.fastq.gz)
        echo -e "$pl\t$lib"
    done
done ) | parallel --colsep '\t' -j $PBS_NCPUS bash ./runmash.sh {1} {2}

mash paste all-runs.msh sketches/*

mash dist -p $PBS_NCPUS -t all-runs.msh all-runs.msh > all-runs-mash.dist
