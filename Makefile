NAME=redis

include .config
ESCAPED_BUILDDIR = $(shell echo '${BUILDDIR}' | sed 's%/%\\/%g')
TARGET=$(BUILDDIR)/$(NAME)
SRCS=redis.nim
BUILDSCRIPT=redis.nimble redis.nim.cfg
FSMS=lexer_fsm.nim syntax_fsm.nim

vpath %.nim $(BUILDDIR)
vpath %.nim $(BUILDDIR)/$(NAME)
vpath %.nimble $(BUILDDIR)
vpath %.txt $(BUILDDIR)
vpath %.cfg $(BUILDDIR)
vpath %.org .

all: $(BUILDSCRIPT) $(SRCS) $(FSMS)

$(SRCS): %.nim: %.org
	sed 's/$$$\{BUILDDIR}/$(ESCAPED_BUILDDIR)/g' $< | org-tangle -

$(BUILDSCRIPT): build.org
	sed 's/$$$\{BUILDDIR}/$(ESCAPED_BUILDDIR)/g' $< | org-tangle -

$(FSMS): %.nim: %.txt
	naive-fsm-generator.py $(addprefix $(BUILDDIR)/, $(notdir $<)) --lang=nim -d $(BUILDDIR)/$(NAME) $(FSMFLAGS)
	sed -i '1a\\import logging' $(addprefix $(BUILDDIR)/$(NAME)/, $(notdir $@))
	sed -i 's/echo/info/g' $(addprefix $(BUILDDIR)/$(NAME)/, $(notdir $@))

$(subst nim,txt,$(FSMS)): redis.org
	sed 's/$$$\{BUILDDIR}/$(ESCAPED_BUILDDIR)/g' $< | org-tangle -

install: $(BUILDSCRIPT) $(SRCS) $(FSMS)
	cd $(BUILDDIR); nimble install; cd -

clean:
	rm -rf $(BUILDDIR)

.PHONY: all clean install
