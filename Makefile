EMACS = emacs -Q --batch
name = org-link-edit
main_el :=  $(name).el
main_elc =  $(main_el)c
AUTOLOADS_FILE := $(name)-autoloads.el

all: $(main_elc)

.PHONY: autoloads
autoloads: $(AUTOLOADS_FILE)

$(AUTOLOADS_FILE): $(main_el)
	@$(EMACS) --eval \
	"(let (make-backup-files) \
	  (update-file-autoloads \"$(CURDIR)/$<\" t \"$(CURDIR)/$@\"))"

.PHONY: clean
clean:
	$(RM) $(main_elc) $(AUTOLOADS_FILE)

.PHONY: help
help:
	@printf "\nTargets:\n\n"
	@printf "  all                Byte compile $(main_el).\n"
	@printf "  autoloads          Generate $(AUTOLOADS_FILE).\n"
	@printf "  clean              Remove generated files.\n"
	@printf "  help               Print this message.\n"
	@printf "  test               Run tests.\n"

.PHONY: test
test:
	@$(EMACS) -L . -l test-org-link-edit \
	--eval "(ert-run-tests-batch-and-exit '(not (tag interactive)))"

%.elc: %.el
	@$(EMACS) -f batch-byte-compile $<
