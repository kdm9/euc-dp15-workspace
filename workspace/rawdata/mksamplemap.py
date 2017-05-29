#!/usr/bin/env python3
import glob
from collections import defaultdict
import re
import yaml
from sys import stderr

files = glob.glob("./plate*/*.fastq.gz")

filemap = defaultdict(lambda : defaultdict(list))
for f in files:
    m = re.search(r"(plate[\d.]+)\/(.+)_(S\d+)_(R\d)_\d+\.", f)
    if m is None:
        print("WARN:", f, file=stderr)
    lane, sample, sid, mate = m.groups()
    if sample.endswith("-NextRAD"):
        continue
    if sample.endswith("-WGS"):
        sample = sample[:-4]
    fpath = "rawdata" + f[1:]
    filemap[sample][mate].append(fpath)

with open("samples.yml", "w") as fh:
    for samp, data in filemap.items():
        print(samp, ":", file=fh, sep='')
        for pair, files in data.items():
            print("  ", pair, ":", file=fh, sep='', end=" ")
            print("[\"", "\", \"".join(files), "\"]", file=fh, sep='')


