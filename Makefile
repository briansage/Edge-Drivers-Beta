# Verification targets for the Edge driver repo.
# No build chain: luacheck and stylua are installed via Homebrew.
#   brew install luacheck stylua

# Drivers the gate covers: the ones being worked on, not the whole fork. Adding one
# means re-measuring both baselines below with it included, in the same change.
DRIVERS := zigbee-light-multifunction-sage

# Known warning count across DRIVERS. `make lint` fails if the count goes UP, so new
# code cannot add problems, while the existing backlog does not keep the gate
# permanently red. Lower this number as you burn the backlog down -- it should only
# ever move one direction.
BASELINE := 25

# Known fingerprint problems across DRIVERS (3 duplicate ids). Same ratchet rule.
FP_BASELINE := 3

# CHANNEL and HUB for `make deploy`, one KEY=value per line. Kept out of git: the IDs
# belong to one SmartThings account, not to the fork.
-include .env

.PHONY: check lint lint-report lint-summary lint-signal fingerprints fmt-check test deploy help

help:
	@echo "make lint          - the gate: fails if warnings exceed BASELINE ($(BASELINE)) or any error appears"
	@echo "make lint-report   - full warning list"
	@echo "make lint-summary  - warning counts grouped by code"
	@echo "make lint-signal   - only the high-value classes (undefined globals, shadowing, dead branches)"
	@echo "make fingerprints  - validate each driver's fingerprints.yml against its profiles"
	@echo "make check         - lint + fingerprints, over DRIVERS ($(DRIVERS))"
	@echo "make fmt-check     - formatting drift for ONE file: make fmt-check FILE=path/to.lua"
	@echo "make test          - plain-Lua unit tests in each DRIVERS src/test/"
	@echo "make deploy        - check, then package DRIVER to CHANNEL and install on HUB: make deploy DRIVER=<dir>"

lint:
	@out=$$(luacheck $(DRIVERS) --no-color --codes -q 2>&1); \
	total=$$(printf '%s\n' "$$out" | sed -n 's/^Total: \([0-9]*\) warnings* \/ \([0-9]*\) errors*.*/\1 \2/p'); \
	warns=$$(echo $$total | cut -d' ' -f1); errs=$$(echo $$total | cut -d' ' -f2); \
	if [ -z "$$warns" ]; then printf '%s\n' "$$out"; echo "luacheck did not report a total; treating as failure"; exit 1; fi; \
	if [ "$$errs" -gt 0 ]; then printf '%s\n' "$$out"; echo "FAIL: $$errs syntax error(s)"; exit 1; fi; \
	case "$$out" in *"couldn't check"*) printf '%s\n' "$$out"; echo "FAIL: luacheck could not read some paths"; exit 1;; esac; \
	if [ "$$warns" -gt "$(BASELINE)" ]; then \
	  printf '%s\n' "$$out"; \
	  echo "FAIL: $$warns warnings, baseline is $(BASELINE) -- this change added $$(($$warns - $(BASELINE)))"; exit 1; \
	fi; \
	if [ "$$warns" -lt "$(BASELINE)" ]; then \
	  echo "PASS: $$warns warnings (baseline $(BASELINE)) -- backlog reduced by $$(($(BASELINE) - $$warns)); lower BASELINE in the Makefile to lock the gain in"; \
	else \
	  echo "PASS: $$warns warnings, at baseline $(BASELINE), 0 errors"; \
	fi

lint-report:
	@luacheck $(DRIVERS) --codes

lint-summary:
	@luacheck $(DRIVERS) --no-color --codes -q 2>/dev/null \
	  | grep -oE '\(W[0-9]+\)' | sort | uniq -c | sort -rn

# W1xx undefined/global misuse, W4xx shadowing, W54x dead branches, W58x suspect logic.
# These are the ones worth reading; W211/W311 are mostly harmless leftovers.
lint-signal:
	@luacheck $(DRIVERS) --no-color --codes -q 2>/dev/null \
	  | grep -E '\(W(1[0-9]{2}|4[0-9]{2}|54[0-9]|58[0-9]|313)\)' || echo "none"

# Deliberately single-file. See the warning in stylua.toml.
fmt-check:
	@test -n "$(FILE)" || { echo "usage: make fmt-check FILE=path/to/file.lua"; exit 2; }
	@stylua --check "$(FILE)"

# Fingerprint entries resolve by the profile's internal `name:` field.
fingerprints:
	@out=$$(python3 scripts/validate_fingerprints.py $(DRIVERS) 2>&1); \
	printf '%s\n' "$$out"; \
	n=$$(printf '%s\n' "$$out" | sed -n 's/^\([0-9]*\) problem(s)$$/\1/p'); \
	if [ -z "$$n" ]; then \
	  printf '%s\n' "$$out" | grep -q '^OK: no problems$$' || { echo "validator did not report a count; treating as failure"; exit 1; }; \
	  n=0; \
	fi; \
	if [ "$$n" -gt "$(FP_BASELINE)" ]; then echo "FAIL: $$n problems, baseline is $(FP_BASELINE)"; exit 1; fi; \
	echo "PASS: $$n problems, baseline $(FP_BASELINE)"

check: lint fingerprints

# Plain-Lua unit tests, run from each driver's src/ so require finds its modules.
# Not part of check: other drivers' src/test/ files need the SmartThings lua_libs.
test:
	@for d in $(DRIVERS); do \
	  for t in $$d/src/test/test_*.lua; do \
	    [ -e "$$t" ] || continue; \
	    echo "$$t"; (cd $$d/src && lua "$${t#$$d/src/}") || exit 1; \
	  done; \
	done

# Only gated drivers ship, so nothing reaches the hub without passing `make check`.
# The Settings screen's first line comes from a "version" preference titled
# "Unreleased build" in each profile. A commit cannot contain its own hash, so the
# commit date and short hash are stamped into a temporary copy at package time.
deploy: check
	@test -n "$(DRIVER)" || { echo "usage: make deploy DRIVER=<dir>"; exit 2; }
	@test -n "$(filter $(DRIVER),$(DRIVERS))" || { echo "$(DRIVER) is not in DRIVERS; add it to the gate first"; exit 2; }
	@test -n "$(CHANNEL)" -a -n "$(HUB)" || { echo "set CHANNEL and HUB in .env"; exit 2; }
	@stage=$$(mktemp -d) && cp -R $(DRIVER) "$$stage/" && \
	find "$$stage/$(DRIVER)" -mindepth 1 -name '.*' -prune -exec rm -rf {} + && \
	dirty=$$(test -z "$$(git status --porcelain -- $(DRIVER))" || echo "-dirty") && \
	stamp="Updated $$(git log -1 --format=%cd --date=short) ($$(git rev-parse --short HEAD)$$dirty)" && \
	perl -pi -e "s/title: \"Unreleased build\"/title: \"$$stamp\"/" "$$stage"/$(DRIVER)/profiles/*.yml && \
	echo "Version line: $$stamp" && \
	smartthings edge:drivers:package "$$stage/$(DRIVER)" --channel $(CHANNEL) --hub $(HUB); \
	rc=$$?; rm -rf "$$stage"; exit $$rc
