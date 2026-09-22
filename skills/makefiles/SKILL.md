---
name: makefiles
description: Use when writing or editing a Makefile, or when the user asks for one — sets the GNU Make header block, phony/real target rules, variable and recipe conventions used in this user's repos
---

# Makefiles

GNU Make is the target (`make` resolves to gmake here); GNU-only features are fine.

## Header

Right after the `# -*- makefile -*-` line, put this block, then give every environment variable the Makefile reads a `?=` default so `--warn-undefined-variables` stays quiet:

```makefile
SHELL:=bash
.SHELLFLAGS:=-eu -o pipefail -c
.DELETE_ON_ERROR:
.SUFFIXES:
MAKEFLAGS+=--no-builtin-rules --warn-undefined-variables
.DEFAULT_GOAL:=all
```

- `SHELL` and `.SHELLFLAGS`: recipes fail on the first error, unset shell variable, or failed pipeline stage
- `.DELETE_ON_ERROR`: a half-written target file is removed when its recipe fails (directories are not, so keep a `configure`-style target that wipes and redoes a build tree)
- `.SUFFIXES` and `--no-builtin-rules`: no implicit `.c`/`.o` rules, so a typo'd target cannot silently match one
- `.DEFAULT_GOAL`: the default target is explicit, not "whichever comes first"

## Targets

- The first target is `all`, declared phony, and usually empty so a bare `make` does nothing by accident
- Declare `.PHONY:` directly above each target it applies to, one target per declaration, never in a single list at the top
- Every target that does not produce a file of the same name is phony (`build`, `clean`, `lint`, `run`, ...)
- Real file and directory targets are not phony; use them so `make` can skip work that is up to date
- Recurse with `$(MAKE)`, never bare `make`, so flags and the jobserver propagate

## Variables

- `:=` for simple assignment; `?=` for values the caller may override from the command line or environment
- Branch on the host once at the top (`HOST_OS:=$(shell uname -s)`) rather than inside recipes
- Fail early for missing prerequisites with `$(error ...)` at parse time or in the target that needs them

## Recipes

- Indented with a tab, never spaces
- One command per line; use `&&` only when a later command must not run after a failure that make would otherwise not see
- Prefix with `@` only for echo-style lines; let real commands print so the log shows what ran

## Detection

The first line is always:

```makefile
# -*- makefile -*-
```

It marks the file as a Makefile for editors even when it is not named `Makefile`.

## Example

```makefile
# -*- makefile -*-
SHELL:=bash
.SHELLFLAGS:=-eu -o pipefail -c
.DELETE_ON_ERROR:
.SUFFIXES:
MAKEFLAGS+=--no-builtin-rules --warn-undefined-variables
.DEFAULT_GOAL:=all

BUILD_TYPE?=Release
BUILD_DIR:=cmake-bld

.PHONY: all
all:

$(BUILD_DIR):
	cmake -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) -S . -B $(BUILD_DIR)

.PHONY: configure
configure:
	rm -rf $(BUILD_DIR)
	$(MAKE) $(BUILD_DIR)

.PHONY: build
build: $(BUILD_DIR)
	cmake --build $(BUILD_DIR)

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
```
