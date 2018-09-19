#!/apps/R/3.4.3/bin/Rscript
library(conStruct)
library(foreach)
cores = as.integer(Sys.getenv("PBS_NCPUS", "2"))
cat(paste("Using", cores, "cpus\n"))

library("doParallel")
registerDoParallel(cores)

max.k=4
n.reps=cores

opts = commandArgs(trailingOnly=T)
in.file = opts[1]

out.base = strftime(Sys.time(), "OUT_%Y-%m-%d_construct-out-xvals")
set.name = sub(".Rdata", "", basename(in.file))
out.base = paste0(out.base, "/", set.name, "/")
out.prefix = paste0(out.base, set.name)
if (!dir.exists(out.base)) dir.create(out.base, recursive=T)

load(file=in.file)

cs = conStruct::x.validation(n.reps=n.reps, K=1:max.k, freqs=geno, geoDist=geo,
			     coords=xy, n.iter=2000, prefix=out.prefix,
			     make.figs=T, save.files=T, parallel=T, n.nodes=cores)
save(cs, file=paste0(out.prefix, "_cs-xval-list.Rdata"))
