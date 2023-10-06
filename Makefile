# resume/Makefile

.PHONY: all
all: resume.pdf resume.html resume.txt

.PHONY: check
check: resume.tex
	chktex $<

public/index.html: resume.pdf resume.html resume.txt
	install -vDt public $^
	( cd public && tree -H . -T "$${CI_PAGES_URL:-file://$$PWD}" -o index.html )

%.pdf: %.tex
	pdflatex -halt-on-error $<

# # Using 'htlatex' is not easy. The 'charset=ascii' seems to have no effect.
# %.html: %.tex
# 	htlatex $< "html,charset=ascii,NoFonts,-css"

%.html: %.tex
	latex2html \
		-ascii_mode \
		-info "" \
		-no_antialias \
		-no_antialias_text \
		-no_auto_link \
		-no_footnode \
		-no_images \
		-no_math \
		-no_navigation \
		-no_subdir \
		-no_tex_defs	\
		-nolatex \
		-nouse_pdftex \
		-split 0 \
		-unsegment \
		$<

%.txt: %.html
	html2text -ascii -o $@ $<

# %.html: %.pdf
# 	pdftohtml -enc ASCII7 -s -i -stdout - - <$< >$@

# %.txt: %.pdf
# 	pdftotext -nopgbrk -enc ASCII7 -eol unix  - - <$< >$@

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
		-o -name 'WARNINGS' \
		\) \
		-exec rm -vf {} +
