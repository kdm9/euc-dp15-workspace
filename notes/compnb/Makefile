RESOURCES = /home/kevin/.vim/bundle/kdm801-vim/resources/
TARGETS = $(patsubst %.md,%.html,$(wildcard *.md))

.PHONY: all clean

all: $(TARGETS)

clean:
	rm -f $(TARGETS)

%.html: %.md $(shell find data/)
	pandoc --to html5 --smart --standalone --toc --toc-depth 1 --self-contained -c $(RESOURCES)/kultiad-serif.css --katex=$(RESOURCES)/katex/dist/katex.min.js --katex-stylesheet=$(RESOURCES)/katex/dist/katex.min.css --output $@ $<
