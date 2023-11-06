# resume/Makefile

HIDDEN_TEXT_URL ?= https://blank.page/

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

# Prevent 'make' from deleting any/all intermediate targets of the form '*.txt'
# and/or '*.html' after use --- declaring them '.SECONDARY'.
#
# https://www.gnu.org/software/make/manual/html_node/Special-Targets.html#index-secondary-targets
#
#   The targets which .SECONDARY depends on are treated as intermediate files,
#   except that they are never automatically deleted.
#
# https://stackoverflow.com/questions/47447369/gnu-make-removing-intermediate-files/67780778#67780778
#
#   Why is this better than .PRECIOUS? That causes files to be retained even if
#   their recipe fails when using .DELETE_ON_ERROR. The latter is important to
#   avoid failing recipes leaving behind bad outputs that are then treated as
#   current by subsequent make invocations. IMO, you always want
#   .DELETE_ON_ERROR, but .PRECIOUS breaks it.
#
# .SECONDARY: $(%.txt)
# .SECONDARY: $(%.html)

# For each thing that depends on 'resume.tex', add a dependency on
# 'resume.hidden.txt'. Do this because 'resume.tex' "includes"
# 'resume.hidden.txt'.
resume.pdf: resume.hidden.txt
resume.html: resume.hidden.txt

resume.hidden.txt: resume.hidden.html
	html2text <$< \
		| sed -e 's/\x1b\[[0-9;?]*[JKmsu]//g' -e 's/[^\x00-\x7f]//g' \
		| tr -s '[:punct:]' ' ' \
		| tr '[:upper:]' '[:lower:]' \
		| grep -Eo '[[:graph:]]+' \
		| sort -u \
		| xargs \
		| fold -sw79 \
		>$@

################################################################################
#
# This is how you get a target to depend on a variable.
#
# https://stackoverflow.com/questions/11647859/make-targets-depend-on-variables/11649835#11649835
#
# First, create a 'call'-able function that, for a given variable name, returns
# a dynamically-generated filename of the form '$VAR_NAME.$VAR_MD5SUM':
NAME_MD5SUM = $(1).$(firstword $(shell echo $($(1)) | md5sum))
#
# Then, let the target in question depend on the dynamically-generated
# filename:
resume.hidden.html: $(call NAME_MD5SUM,HIDDEN_TEXT_URL)
	curl -fsSLo $@ $(HIDDEN_TEXT_URL)
#
# Finally, teach 'make' how to create the dynamically-generated filename:
$(call NAME_MD5SUM,HIDDEN_TEXT_URL):
	rm -f HIDDEN_TEXT_URL.*
	echo "$(HIDDEN_TEXT_URL)" >$@

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
		-o -name 'HIDDEN_TEXT_URL.*' \
		-o -name 'WARNINGS' \
		\) \
		-exec rm -vf {} +
