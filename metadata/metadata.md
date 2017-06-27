# Final metadata

This is the "final" metadata set including all bits of data

```{r}
library(tidyverse)
library(readxl)

d= readxl::read_excel("orig/Collection_Eucs_2015.xlsx", skip = 1, sheet = "RawField")
# remove trailing duplicate columns for associated spp, and duplicated lat/lon
d =  d[c(1:9, 12:18)]

# There are a whole bunch of typos or such like in that spreadsheet, the
# following fixes that.
collections = d %>% select(ID, Species, Latitude, Longitude, Location) %>%
    rename(Species.orig = Species) %>%
    mutate(Species = gsub(' *(\\?|\\(.*\\))*$', '', Species.orig),
           Species = sub('^Eucalyptus alben$', 'Eucalyptus albens', Species),
           Species = sub('Eucalptus', 'Eucalyptus', Species),
           Species = sub('Eucalpyptus', 'Eucalyptus', Species)) %>%
    rename(binomial.name=Species, binomial.name.orig=Species.orig) %>%
    extract(binomial.name, c("species"), "^Eucalyptus (\\w+)$", remove=F) %>%
    mutate(species = ifelse(!is.na(species), species,
            gsub("Eucalyptus (\\w+) x (\\w+)", "\\1X\\2", binomial.name)))

readnum = read.delim("orig/readnum.tsv", stringsAsFactors=F) %>%
    extract(filename, c("ID"), '.*\\/(\\S+)\\.fastq.gz') %>%
    mutate(coverage = bases / 640000000)

spp2ser = read.csv("spp2series.csv", stringsAsFactors=F)
run2samp = read.csv("run_merging.csv", stringsAsFactors=F)

joined = run2samp %>%
    left_join(readnum, by=c("sample"="ID")) %>%
    left_join(collections, by=c("sample"="ID")) %>%
    # Mosaic tree samples not in collections & therefore don't have a species
    mutate(species=ifelse(grepl("^M\\d.$", sample), "melliodora", species)) %>%
    left_join(spp2ser, by=c("species"="species"))

write.csv(joined, "clean_metadata.csv", row.names=F)
```

# Series mapping

Not all species are in Jaz's table, so the following outputs a table that I then add to by hand

```{r}
series = read.csv("orig/pop_IDs_noreps.csv", stringsAsFactors=F) %>%
        mutate(indiv = sub('^(\\d+)', 'J\\1', indiv),
                species = sub(' ', '', species),
                sp.short = sub(' ', '', sp.short),
                indiv = sub('_', '-', indiv)) %>%
        select(series, species, series, sp.short, ser.short) %>%
        filter(!is.na(species), !is.na(series)) %>%
        unique()
write.csv(series, "spp2series.csv", row.names=F)
```
