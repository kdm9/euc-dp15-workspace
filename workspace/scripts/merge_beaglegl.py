import gzip
from tempfile import mktemp
from subprocess import Popen, PIPE, STDOUT, check_output
import os

infiles = list(sorted(snakemake.input))
output = snakefile.output.beaglegl
nsites_file = snakefile.output.nsites
threads = snakemake.threads
wcfile = mktemp()

with Popen("pigz -p {} >{}".format(threads, output), shell=T, stdin=PIPE) as outproc:
    out = outproc.stdin
    # Grab header
    hdr = check_output("zcat {} | head -n 1".format(infiles[0]), shell=T)
    out.write(hdr)
    # Grab all but header for remainder of files
    for infile in infiles:
        Popen("zcat {} | tail -n +2 | tee >(wc -l >>{})".format(infile, wcfile),
              executable="/bin/bash", shell=T, stdout=out).wait()

with open(nsites_file, "w") as ofh:
    nsites = sum([int(l.strip()) for l in open(wcfile)])
    print(nsites, file=ofh)
os.unlink(wcfile)
