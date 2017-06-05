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
        chroms = []
        scafs = []
        for cname, clen in parsefai(fai):
            if cname.lower().startswith("chr"):
                chroms.append([cname])
            else:
                scafs.append(cname)
        chroms.append(scafs)
        ref = dict()
        for i, w in enumerate(chroms):
            wname = "W{:05d}".format(i)
            ref[wname] = w
        ret[refname] = ref
        print(refname, "has", len(ref), "chromosome sets")
    return ret
