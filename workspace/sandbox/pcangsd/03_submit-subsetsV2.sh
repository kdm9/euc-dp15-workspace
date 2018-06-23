#!/bin/bash
NREPS=100

for i in $(seq 0 10 100)
do
    TO=$(($i + 9))
    qsub -v REPFROM=${i},REPTO=${TO} 03_subsetV2.pbs
done
