# resume/Makefile

################################################################################

THIS := $(abspath $(lastword $(MAKEFILE_LIST)))
HERE := $(patsubst %/,%,$(dir $(THIS)))

################################################################################

# This is how you do deferred variable expansion.
#
# https://git.dpkg.org/cgit/dpkg/dpkg.git/tree/scripts/mk/pkg-info.mk?id=72c00cf6d914c2f230cf62e34c3e2bebc6a468a1
# https://make.mad-scientist.net/deferred-simple-variable-expansion/
#
resume_late_eval ?= $(or $(value RESUME_CACHE_$(1)),$(eval RESUME_CACHE_$(1) := $(shell $(2)))$(value RESUME_CACHE_$(1)))

################################################################################

.PHONY: all
all: resume.pdf resume.html resume.txt

.PHONY: check
#
# $ chktex resume.tex
# ...
# Warning 29 in resume.hidden.txt line 2: $\times$ may look prettier here.
# 170 176 180 190 2 20 200 2023 21 215 23 230 254 26 269 27 28 298 2x 3 30 31
#                                                                   ^
#
check: resume.tex
	chktex --nowarn 29 $<

public/index.html: TREE_TITLE ?= file://$(HERE)
public/index.html: resume.pdf resume.html resume.txt
	install -vDt public $^
	( cd public && tree -H . -T $(TREE_TITLE) -o index.html )

%.pdf: %.tex
	pdflatex -halt-on-error $<

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

# For each thing that depends on 'resume.tex', add dependencies on
# 'resume.hidden.txt' and 'email.txt'. Do this because 'resume.tex' "includes"
# 'resume.hidden.txt' and 'email.txt'.
resume.pdf: resume.hidden.txt email.txt
resume.html: resume.hidden.txt email.txt

################################################################################
#
# This is how you get a target to depend on a variable.
#
# https://stackoverflow.com/questions/11647859/make-targets-depend-on-variables/11649835#11649835
#

EMAIL ?= $(call resume_late_eval,EMAIL,duck-gen)
EMAIL_MD5 = $(call resume_late_eval,EMAIL_MD5,echo $(EMAIL) | md5sum | grep -Eo '^[[:xdigit:]]{32}')
email.txt: EMAIL.txt.$(EMAIL_MD5)
	cp -v $< $@
EMAIL.txt.$(EMAIL_MD5):
	rm -f EMAIL.*
	echo $(EMAIL) >$@

HIDDEN_TEXT_URL ?= https://blank.page/
HIDDEN_TEXT_URL_MD5 = $(call resume_late_eval,HIDDEN_TEXT_URL_MD5,echo $(HIDDEN_TEXT_URL) | md5sum | grep -Eo '^[[:xdigit:]]{32}')

resume.hidden.txt: HIDDEN_TEXT.dict.$(HIDDEN_TEXT_URL_MD5)
	cp -v $< $@

HIDDEN_TEXT.dict.$(HIDDEN_TEXT_URL_MD5): HIDDEN_TEXT.txt.$(HIDDEN_TEXT_URL_MD5)
	sed -e 's/\x1b\[[0-9;?]*[JKmsu]//g' -e 's/[^\x00-\x7f]//g' <$< \
		| tr -s '[:punct:]' ' ' \
		| tr '[:upper:]' '[:lower:]' \
		| grep -Eo '[[:graph:]]{2,}' \
		| grep -Exv '[[:digit:]]+' \
		| grep -Fxvf block.list \
		| sort -u >$@

HIDDEN_TEXT.txt.$(HIDDEN_TEXT_URL_MD5): HIDDEN_TEXT.html.$(HIDDEN_TEXT_URL_MD5)
	html2text <$< >$@

HIDDEN_TEXT.html.$(HIDDEN_TEXT_URL_MD5): HIDDEN_TEXT.url.$(HIDDEN_TEXT_URL_MD5)
	xargs curl -fsSLo $@ <$<

HIDDEN_TEXT.url.$(HIDDEN_TEXT_URL_MD5):
	rm -f HIDDEN_TEXT.*
	echo "$(HIDDEN_TEXT_URL)" >$@

################################################################################

.PHONY: clean
clean:
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
		-o -name 'HIDDEN_TEXT.*' \
		-o -name 'WARNINGS' \
		\) \
		-exec rm -vf {} +
