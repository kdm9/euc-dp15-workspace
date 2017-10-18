# 2017-09-15 -- Merge of vcfs, checking that everything works

Two vcfs copied to `./data`, one is the result of the reference-based GBS pipeline on Megan's E. melliodora data (plates lb1-lb4) and Tim Collins' E. magnificata et al GBS data. The other is the WGS vcf from the project 1 data.


```
bcftools merge -m both -o data/all-data-merged.bcf -Ob --threads 16 --force-samples \
        data/emag-emel-gbs-defaultfiltered.bcf \
        data/proj1-wgs-defaultfiltered.bcf
bcftools index data/all-data-merged.bcf
```

Because bcftools is broken with regards to filtering missing values from float/int fields, we need to use awk. We use bcftools query to make a simple condensed format of the BCF, then remove any site not assayed in both vcfs. This is then used to filter the bcf

```
bcftools query -f '%CHROM\t%POS\t[%DP]\n' data/all-data-merged.bcf \
    | awk '$3 !~ /\./{printf("%s\t%s\n", $1, $2);}' \
    | gzip > data/common-sites.tsv.gz

bcftools view -R data/common-sites.tsv.gz -Oz -o data/common-variants-all-data.vcf.gz \
    data/all-data-merged.bcf
bcftools index data/common-variants-all-data.vcf.gz
```
