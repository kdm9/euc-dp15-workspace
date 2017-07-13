#!/bin/bash
#PBS -q express
#PBS -l ncpus=1
#PBS -l walltime=24:00:00
#PBS -l mem=8G
#PBS -l jobfs=300G
#PBS -l other=gdata1
#PBS -l wd
#PBS -M kevin@kdmurray.id.au
#PBS -m abe
#PBS -P xe2

logdir=raijin/log
if [ -d $logdir ]
then
  pushd $logdir >/dev/null
  if [ -n "$(ls *.ER *.OU 2>/dev/null)" ]
  then
    tar cf `date +%y%m%d_%H%M%S`.tar *.OU *.ER 2>/dev/null
    rm *.OU *.ER
  fi
  popd >/dev/null
else
  mkdir -p $logdir
fi

# if [ -d ".kdmwrappers/.git" ]
# then
#     cd .kdmwrappers && git pull && cd ..
# else
#     git clone 'https://github.com/kdmurray91/snakemake-wrappers.git' .kdmwrappers
# fi

QSUB="qsub -q {cluster.queue} -l ncpus={threads} -l jobfs={cluster.jobfs}"
QSUB="$QSUB -l walltime={cluster.time} -l mem={cluster.mem} -N {cluster.name}"
QSUB="$QSUB -l wd -o $logdir -e $logdir -P xe2"
torun="${2:-all}"

snakemake --unlock

snakemake                                \
    -j 500                               \
    --cluster-config raijin/cluster.yaml \
    --js raijin/jobscript.sh             \
    --rerun-incomplete                   \
    --keep-going                         \
    --cluster "$QSUB" $torun
