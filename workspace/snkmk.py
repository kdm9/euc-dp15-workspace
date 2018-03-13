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
    return ret


def _iter_metadata():
    with open("../metadata/seq-metadata.csv") as fh:
        for samp in csv.DictReader(fh):
            yield samp


def make_runlib2samp():
    rl2s = {}
    s2rl = defaultdict(list)
    csvf = csv.DictReader(open("../metadata/seq-metadata.csv"))
    for run in csvf:
        if not run["library"] or run["library"].lower().startswith("blank"):
            # Skip blanks
            continue
        rl = (run["run"], run["library"])
        samp = run["sample"]
        rl2s[rl] = samp
        s2rl[samp].append(rl)
    return dict(rl2s), dict(s2rl)


def make_samplesets(sets):
    ssets = defaultdict(list)
    everything = set()
    for run in _iter_metadata():
        for sset in sets:
            if run[sset].upper().startswith('Y'):
                ssets[sset].append(run["sample"])
        everything.add(run["sample"])
    ssets["all_samples"] = everything
    return {n: list(sorted(set(s))) for n, s in ssets.items()}
