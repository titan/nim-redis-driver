NAME=redis

include .config
ESCAPED_BUILDDIR = $(shell echo '${BUILDDIR}' | sed 's%/%\\/%g')
TARGET=$(BUILDDIR)/$(NAME)
SRCS=redis.nim
BUILDSCRIPT=redis.nimble redis.nim.cfg
FSMS=lexer.nim syntax.nim
TESTSRC=tester.nim
TESTER=$(BUILDDIR)/tester

vpath %.nim $(BUILDDIR)
vpath %.nim $(BUILDDIR)/$(NAME)
vpath %.nimble $(BUILDDIR)
vpath %.txt $(BUILDDIR)
vpath %.cfg $(BUILDDIR)
vpath %.org .

all: $(BUILDSCRIPT) $(SRCS) $(FSMS)

$(SRCS) $(TESTSRC): %.nim: %.org
	sed 's/$$$\{BUILDDIR}/$(ESCAPED_BUILDDIR)/g' $< | org-tangle -

$(BUILDSCRIPT): build.org
	sed 's/$$$\{BUILDDIR}/$(ESCAPED_BUILDDIR)/g' $< | org-tangle -

$(FSMS): %.nim: %.txt
	fsmc.py $(addprefix $(BUILDDIR)/, $(notdir $<)) -o $(addprefix $(BUILDDIR)/$(NAME)/, $(notdir $@)) $(FSMFLAGS)
	sed -i '1a\\import logging' $(addprefix $(BUILDDIR)/$(NAME)/, $(notdir $@))
	sed -i 's/echo/info/g' $(addprefix $(BUILDDIR)/$(NAME)/, $(notdir $@))

$(subst nim,txt,$(FSMS)): redis.org
	sed 's/$$$\{BUILDDIR}/$(ESCAPED_BUILDDIR)/g' $< | org-tangle -

install: all
	cd $(BUILDDIR); nimble install; cd -

test: $(TESTER)

$(TESTER): $(TESTSRC) $(SRCS) $(FSMS)
	cd $(BUILDDIR); nim c $(TESTSRC); cd -

clean:
	rm -rf $(BUILDDIR)

.PHONY: all clean install test
