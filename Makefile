# resume/Makefile

.PHONY: all
all: resume.pdf resume.html resume.txt

%.pdf: %.tex
	pdflatex -halt-on-error $<

# %.html: %.tex
# 	latex2html -info "" -no_antialias -no_antialias_text -no_auto_link		\
# 	-no_footnode -no_images -no_math -no_navigation -no_subdir -no_tex_defs	\
# 	-nolatex -nouse_pdftex -split 0 -unsegment $<

%.html: %.pdf
	pdftohtml -enc ASCII7 -s -i -stdout - - <$< >$@

%.txt: %.pdf
	pdftotext -enc ASCII7 -eol unix  - - <$< >$@

.PHONY: clean
clean:
	rm -vrf \
		*.aux \
		*.css \
		*.html \
		*.log \
		*.old \
		*.pdf \
		*.pl \
		*.png \
		*.svg \
		*.txt \
		*~ \
		;
