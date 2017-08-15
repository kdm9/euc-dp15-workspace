RESOURCES = /home/kevin/.vim/bundle/kdm801-vim/resources/
TARGETS = $(patsubst %.md,%.html,$(wildcard *.md))
UPLOAD_TO = edmund.anu.edu.au:~/public_html/euc-nb/

.PHONY: all clean upload

all: $(TARGETS)

clean:
	rm -f $(TARGETS)

upload:
	scp $(TARGETS) $(UPLOAD_TO)

%.html: %.md $(shell find data/)
	pandoc --to html5 --smart --standalone --toc --toc-depth 1 --self-contained -c $(RESOURCES)/kultiad-serif.css --katex=$(RESOURCES)/katex/dist/katex.min.js --katex-stylesheet=$(RESOURCES)/katex/dist/katex.min.css --output $@ $<
