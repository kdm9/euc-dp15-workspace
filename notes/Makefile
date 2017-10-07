RESPATH = $(realpath data/resources)
RESARGS = --css $(RESPATH)/kultiad-serif.css --katex=$(RESPATH)/katex/katex.min.js --katex-stylesheet=$(RESPATH)/katex/katex.min.css
TARGETS = $(patsubst %.md,%.html,$(shell find -name \*.md -not -path \*data\*)) \
          $(patsubst %.Rmd,%.html,$(shell find -name \*.Rmd -not -path \*data\*))
UPLOAD_TO = edmund.anu.edu.au:~/public_html/euc-nb/

.PHONY: all clean upload

all: $(TARGETS)

clean:
	rm -f $(TARGETS)

upload: $(TARGETS)
	scp $(TARGETS) $(UPLOAD_TO)

%.html: %.md $(shell find -path \*/data/*)
	@pandoc --to html5 --smart --standalone --toc --toc-depth 1 --self-contained $(RESARGS) --output $@ $<
	@echo "   PANDOC\t$<"

%.html: %.Rmd
	@Rscript -e 'rmarkdown::render("$<", output_file="$(@F)", output_format="html_document")'
	@echo "   KNIT\t$<"
