library(tidyverse)

md = read.csv("sample-metadata.csv", stringsAsFactors=F)

md %>% filter(SpeciesNoHybrid=="albens", Project2=="Y") %>% pull(ID) %>%
    writeLines("samplesets/Project2-albens.txt")

md %>% filter(SpeciesNoHybrid=="sideroxylon", Project2=="Y") %>% pull(ID) %>%
    writeLines("samplesets/Project2-sideroxylon.txt")
