import glob
from collections import defaultdict
import re
import yaml

files = glob.glob("./run*/*.fastq.gz")

filemap = defaultdict(lambda : defaultdict(list))
for f in files:
    m = re.search(r"(run\d)\/(.+)[-_](WGS|NextRAD)_(S\d+)_(R\d)_\d+\.", f)
    lane, sample, dtype, sid, mate = m.groups()
    if dtype == "WGS":
        filemap[sample][mate].append(f)

with open("samples.yml", "w") as fh:
    for samp, data in filemap.items():
        print(samp, ":", file=fh, sep='')
        for pair, files in data.items():
            print("  ", pair, ":", file=fh, sep='')
            for f in files:
                print("    - ", f, file=fh, sep='')


