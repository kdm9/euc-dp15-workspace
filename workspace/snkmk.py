import csv
from collections import defaultdict


def parsefai(fai):
    with open(fai) as fh:
        for l in fh:
            cname, clen, _, _, _ = l.split()
            clen = int(clen)
            yield cname, clen


def make_regions(rdict, window=1e6):
    window = int(window)
    ret = {}
    for refname, refpath in rdict.items():
        fai = refpath+".fai"
        windows = []
        curwin = []
        curwinlen = 0
        for cname, clen in parsefai(fai):
            if clen < window:
                curwinlen += clen
                reg = "{}:1-{}".format(cname, clen)
                curwin.append(reg)
                if curwinlen > window:
                    windows.append(curwin)
                    curwin = []
                    curwinlen = 0
            else:
                for start in range(0, clen, window):
                    wlen = min(clen - start, window)
                    windows.append(["{}:{}-{}".format(cname, start, start+wlen)])
        if len(curwin) > 0:
            windows.append(curwin)

        ref = dict()
        for i, w in enumerate(windows):
            wname = "W{:05d}".format(i)
            ref[wname] = w
        ret[refname] = ref
        print(refname, "has", len(ref), "windows")
    return ret


def make_chroms(rdict):
    ret = {}
    for refname, refpath in rdict.items():
        fai = refpath+".fai"
        ref = dict()
        scafs = []
        for cname, clen in parsefai(fai):
            if cname.lower().startswith("chr"):
                ref[cname] = [cname]
            else:
                scafs.append(cname)
        ref["scaffolds"] = scafs
        ret[refname] = ref
        print(refname, "has", len(ref), "chromosome sets")
    return ret


def _iter_metadata():
    with open("../metadata/clean_metadata.csv") as fh:
        for samp in csv.DictReader(fh):
            yield samp


def make_lib2sample2lib():
    l2s = {}
    s2l = defaultdict(list)
    tsvf = open("../metadata/lib2sample.tsv")
    next(tsvf)  # Skip header
    for run in tsvf:
        lib, samp = run.strip().split()
        l2s[lib] = samp
        s2l[samp].append(lib)
    return l2s, s2l


def make_samplesets():
    ssets = defaultdict(list)
    everything = set()
    for run in _iter_metadata():
        ssets[run["series"]].append(run["sample"])
        ssets[run["species"]].append(run["sample"])
        everything.add(run["sample"])
    ssets["everything"] = everything
    return {n: list(sorted(set(s))) for n, s in ssets.items()}
