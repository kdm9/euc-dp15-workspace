---
title: Planning notebook for Euc projects
author: Kevin Murray
---

# Current TODOs:

## Re-doing angds

- [ ] Re-map with stampy: http://www.well.ox.ac.uk/bioinformatics/Software/Stampy-latest.tgz (Back-burnered)
- [ ] Re-do the angds with all Rose & Jaz's args (Using NGM for now)
- [ ] Excess het R script work for Rose (feeds into filtering)
- [ ] work w/ rose for SAF -> treemix format conversion
- [ ] Implement variant filtering

## Misc

- [ ] Check input format for mixmapper
- [ ] Work out formulae & method of ANGSD'd abbababa2 multi-pop model
- [ ] Work out raijin angsd spookyness:
    - Why doesn't ABBABABA work on raijin
    - Doubled FST results?

# 2017-06-07 -- SNP filtering plans

![Plan of ANGSD-based site filtering](data/2017-06-07_filtering-plan.jpg)

The filtering pipeline looks like it will be a 2 step process:

1. Run angsd with minimal sample data filters, generate SnpStat output (for
   HWE, Coverage, P value, misc other stats per site).
2. Run angds with `-sites` to select sites passing QC, once for all samples
   and optionally (well, eventually) for each spp or series.


### Step 1: All sample, most sites

1. Run angsd on NGM mapped, AdaperRemoval trimmed BAMs against grandis 297.
    - `-minInd 10` at least 10 samples must have data. 10 chosen as that's
      ~2/3 of the smallest series.
    - `-setMinDepth` and `-setMaxDepth`: total (over all samples) site depth.
      Minimum 2, unsure about maximum. (needs `-doCounts 1`)
    - `SNP_pval`: I don't trust this very much, obviously garbage sites get
      quite significant P values. However, I guess `-SNP_pval 1e-2` wouldn't
      be unreasonable and might remove very poor sites (though at the cost of
      needing to do `-doMaf 1`)
    - `-doSnpStat 1` is required for HWE, major/minor counts etc. These
      filters will be done ouside angsd, returning a list of sites that pass
      QC.
    - `-GL 2` and `-doGlf 2` are required for various purposes, and may as
      well write the GL out as a beagle file
2. External R/Julia script to filter sites based on all outputs of the above:
    - $H_o < 0.7$ (possibly done later at the per spp level, or at least $H_o
      < 0.7$ in X species. 0.7 negotiable. $H_o$ calculatable from $F_is$)
    - SnpStat minor allele counts (on either strand) must be $\ge 5$
    - Possible additional steps here, if we can think of them
    - Generate a sites file (preferably in BED format, if ANGSD can be
      convinced to take that: then it can be used elsewhere).
3. Re-run angsd for all samples with `-sites`, generating the "All samples,
   QC sites" set.

# TODO (Completed)

- [x] Snakemake-ify Jaz's first steps of the ANGSD pipeline
