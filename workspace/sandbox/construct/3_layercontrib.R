library(conStruct)

args = commandArgs(T)
outfile = args[1]
inresults = args[2:length(args)]

prefixes = unique(sapply(inresults, function (f) {
                         sub("K\\d+_conStruct.results.Robj", "", f, perl=T)
                  }))


all.layercontrib = NULL
for (prefix in prefixes) {
    runs = Sys.glob(sprintf("%sK*_conStruct.results.Robj", prefix))
    ks = as.numeric(sub(".*K(\\d+).*", "\\1", runs))
    names(ks) = runs
    ks = sort(ks)

    prevk = NULL
    for (kfile in names(ks)) {
        kprefix = sub("_conStruct.results.Robj", "", kfile)
        load(sprintf("%s_conStruct.results.Robj", kprefix))
        load(sprintf("%s_data.block.Robj", kprefix))

        if (is.null(prevk)) {
            layer.order = 1
        } else {
            layer.order <- match.layers.x.runs(prevk, conStruct.results[[1]]$MAP$admix.proportions)
        }
        # calculate layer contributions
        lc = calculate.layer.contribution(conStruct.results=conStruct.results[[1]],
                                          data.block=data.block,
                                          layer.order=layer.order)

        all.layercontrib = rbind(all.layercontrib,
                                 data.frame(csrun=basename(kfile),
                                            layer=1:length(lc),
                                            contrib=lc))
        if (length(layer.order) < 2) {
            prevk = conStruct.results[[1]]$MAP$admix.proportions
        } else {
            prevk = conStruct.results[[1]]$MAP$admix.proportions[,layer.order]
        }
        cat(paste("Done", kfile, "\n"))
    }
}
write.csv(all.layercontrib, outfile, row.names=F)
