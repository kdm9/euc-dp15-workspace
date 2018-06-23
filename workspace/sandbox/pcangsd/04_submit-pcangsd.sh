#for i in $(seq 0 9)
for i in $(seq 10 109)
do
    qsub -v REP=$(printf "%03d\n" $i) 04_pcangsd.pbs
done
