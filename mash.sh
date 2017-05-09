#!/bin/bash
set -xe

k=21
s=10000
samples=$(find data/reads -type f | grep -vi blank)

mkdir -p data/mash

mash sketch -k $k -s $s -p 16 -o data/mash/euc_k${k}_s${s} $samples

mash dist -p 16 data/mash/euc_k${k}_s${s}.msh data/mash/euc_k${k}_s${s}.msh \
    > data/mash/euc_k${k}_s${s}.mashdist

mash2kwipdist.py data/mash/euc_k${k}_s${s}.mashdist \
    > data/mash/euc_k${k}_s${s}.dist

