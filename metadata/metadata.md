# 2017-05-22 -- Series-level metadata

```
library(tidyverse)

collection = read.csv("cleaned/collection_metadata.csv", stringsAsFactors=F)

series = read.csv("orig/pop_IDs_noreps.csv", stringsAsFactors=F)

series = series %>%
        mutate(indiv = sub('^(\\d+)', 'J\\1', indiv),
                species = sub(' ', '', species),
                sp.short = sub(' ', '', sp.short),
                indiv = sub('_', '-', indiv))

joined = right_join(collection, series, by=c("ID"="indiv")) %>%
        select(-stampy, -bwa)

# joined = full_join(collection, series, by=c("ID"="indiv")) %>%
#         select(-stampy, -bwa)

write.csv(joined, "cleaned/metadata.csv", row.names=F)
```



# 2017-05-01 -- Original metadata

```R
library(tidyverse)
library(readxl)
library(Cairo)
```

# Jasmine's collection data

```R
d= readxl::read_excel("orig/Collection_Eucs_2015.xlsx", skip = 1, sheet = "RawField")
# remove trailing duplicate columns for associated spp, and duplicated lat/lon
d =  d[c(1:9, 12:18)]
```

There are a whole bunch of typos or such like in that spreadsheet, the
following fixes that.

```R
cleaned = d %>% select(ID, Species, Latitude, Longitude, Location) %>%
    rename(Species.orig = Species) %>%
    mutate(Species = gsub(' *(\\?|\\(.*\\))*$', '', Species.orig),
           Species = sub('^Eucalyptus alben$', 'Eucalyptus albens', Species),
           Species = gsub('Eucalptus', 'Eucalyptus', Species),
           Species = gsub('Eucalpyptus', 'Eucalyptus', Species)
          )
write.csv(cleaned, "cleaned/collection_metadata.csv", row.names=F)
```

# Read number


```R
rfile2samp = function (x) {gsub('.*\\/(\\S+)\\.fastq.gz', x)}
```


```R
rnum = read.delim("orig/readnum.tsv", stringsAsFactors=F) %>%
    mutate(coverage = bases / 600000000,
           sample = gsub('.*\\/(\\S+)\\.fastq.gz', '\\1', filename))

write.csv(rnum, 'cleaned/readnum.csv', row.names=F)
```
