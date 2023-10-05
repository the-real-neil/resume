# resume/Makefile

.PHONY: all
all: resume.pdf resume.html resume.txt

.PHONY: check
check: resume.tex email.txt
	chktex $<

public/index.html: resume.pdf resume.html resume.txt
	install -vDt public $^
	( cd public && tree -H . -o index.html )

%.pdf: %.tex
	pdflatex -halt-on-error $<

# %.html: %.tex
# 	latex2html -info "" -no_antialias -no_antialias_text -no_auto_link		\
# 	-no_footnode -no_images -no_math -no_navigation -no_subdir -no_tex_defs	\
# 	-nolatex -nouse_pdftex -split 0 -unsegment $<

%.html: %.pdf
	pdftohtml -enc ASCII7 -s -i -stdout - - <$< >$@

%.txt: %.pdf
	pdftotext -nopgbrk -enc ASCII7 -eol unix  - - <$< >$@

.PHONY: clean
clean:
	rm -vrf public
	find . \
		-type f \
		! -path './.git/*' \
		\( -false \
		-o -name '*.aux' \
		-o -name '*.css' \
		-o -name '*.html' \
		-o -name '*.log' \
		-o -name '*.old' \
		-o -name '*.pdf' \
		-o -name '*.pl' \
		-o -name '*.png' \
		-o -name '*.svg' \
		-o -name '*.txt' \
		-o -name '*~' \
		\) \
		-exec rm -vf {} +
