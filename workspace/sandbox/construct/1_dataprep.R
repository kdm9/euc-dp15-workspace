library(fossil)
library(foreach)
library(doMC)
cores = as.integer(Sys.getenv("PBS_NCPUS", "2"))
registerDoMC(cores)
cat(paste("Using", cores, "cpus\n"))

outdir = "DAT_construct-inputs/"
if(!dir.exists(outdir)) dir.create(outdir, recursive=T)

#for (genofile in Sys.glob("../../data/angsd/pcangsd/bwa~grandisv2chl~*~100000snps~*0.geno.gz")) {
d = foreach(genofile = Sys.glob("../../data/angsd/pcangsd/bwa~grandisv2chl~*~100000snps~*.geno.gz"), .errorhandling="pass") %dopar% {
    library(dplyr)

    filetag = sub('.geno.gz$', '', basename(genofile))
    outprefix = paste0(outdir, "/", filetag)
    sampleset = sub(".*(Project[^~]+).*", "\\1", filetag)
    sampfile = paste0("../../../metadata/samplesets/", sampleset, ".txt")
    samp = read.delim(sampfile, header=F, stringsAsFactors=F)[,1]
    goodsamps =  read.delim(paste0("../../../metadata/samplesets/", sampleset, "-no-outlier.txt"),
                            header=F, stringsAsFactors=F)[,1]
    # Geno
    geno = read.delim(genofile, header=F)
    geno = t(as.matrix(geno))
    geno[geno==9] = NA
    geno = geno / 2 # 012 coded, want allele freq per sample
    rownames(geno) = samp
    geno = geno[goodsamps,]

    # metadata
    meta = read.csv("../../../metadata/sample-metadata.csv",  stringsAsFactors=F)
    my.meta = meta[match(goodsamps, meta$ID),]
    write.csv(my.meta, paste0(outprefix, "_metadata.csv"), row.names=F)

    # Remove the samples with no Lat/long
    samp.keep = my.meta %>%
        filter(!is.na(Latitude), !is.na(Longitude)) %>%
        pull(ID)
    geno = geno[samp.keep,]

    xy = as.matrix(my.meta[match(samp.keep, my.meta$ID), c("Longitude", "Latitude")])
    geo = as.matrix(fossil::earth.dist(xy))

    # Genotype stats
    pdf(paste0(outprefix, "_genostats.pdf"))
    hist(geno, main="Genotype frequencies")
    hist(colMeans(geno, na.rm=T), main="per-snp mean genotypes", breaks=40)
    snp.het = colMeans(geno==0.5, na.rm=T)
    hist(snp.het, main="per-snp observed heterozygosity", breaks=40)
    snp.missing = colMeans(is.na(geno))
    hist(snp.missing, main="per-snp missing rate", breaks=40)
    samp.het = rowMeans(geno==0.5, na.rm=T)
    hist(samp.het, main="per-indiv observed heterozygosity", breaks=40)
    samp.missing = rowMeans(is.na(geno))
    hist(samp.missing, main="per-indiv missing rate", breaks=40)
    maf = colMeans(geno, na.rm=T) / 2
    maf = ifelse(maf > 0.5, 1-maf, maf)
    hist(maf, main="per-snp minor allle freq", breaks=40)


    # distances
    genodist = as.matrix(dist(geno, method="manhattan")) / nrow(geno)
    plot(hclust(as.dist(genodist)), cex=0.5)

    # geno filtering
    no.excess.hets = snp.het < 0.8
    no.missing = snp.missing < 0.6
    no.maf = maf > 0.01
    geno = geno[, no.excess.hets & no.missing & no.maf]
    cat(paste("Filtered out", sum(!no.excess.hets), "SNPs due to excess heterozygosity\n"))
    cat(paste("Filtered out", sum(!no.missing), "SNPs due to excess missingness\n"))
    cat(paste("Filtered out", sum(!no.maf), "SNPs due to insufficient maf\n"))

    writeLines(samp.keep, paste0(outprefix, "_kept-samples.txt"))
    geno = geno[samp.keep,]

    # Post-filtering stats
    snp.het = colMeans(geno==0.5, na.rm=T)
    hist(snp.het, main="per-snp observed heterozygosity (post)", breaks=40)
    snp.missing = colMeans(is.na(geno))
    hist(snp.missing, main="per-snp missing rate (post)", breaks=40)
    samp.het = rowMeans(geno==0.5, na.rm=T)
    hist(samp.het, main="per-indiv observed heterozygosity (post)", breaks=40)
    samp.missing = rowMeans(is.na(geno))
    hist(samp.missing, main="per-indiv missing rate (post)", breaks=40)
    dev.off()

    # Output per-indiv data
    set.name = paste0("perindiv_", filetag)
    save(set.name, geno, geo, xy, file=paste0(outprefix, "_perindiv.Rdata"))

    # per-site aggregation
    sites = cutree(hclust(as.dist(geo)), h=1) # 1km is within site
    geno = apply(geno, 2, tapply, sites, mean, na.rm=T)
    xy = apply(xy, 2, tapply, sites, mean, na.rm=T)
    geo = as.matrix(fossil::earth.dist(xy))

    # Output per-location data
    set.name = paste0("perlocation_", filetag)
    save(set.name, geno, geo, xy, file=paste0(outprefix, "_perlocation.Rdata"))
    invisible(NULL)
}

save(d, file="dump.Rdat")
