#!/bin/bash
source /g/data1/xe2/.profile
set -ue


for input in DAT_construct-inputs/bwa~grandisv2chl~Project2*~100000snps~rep0*_perindiv.Rdata
do

    qsub -P xe2 -N csP2indivs -l ncpus=8,walltime=24:00:00,mem=15G,jobfs=100G,wd -q express <<END
module load R/3.4.3
Rscript 2_runone-xval.R $input
END
done
