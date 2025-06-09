# CONTEXT.md - llmr R Package Development Guide

## Build/Test/Lint Commands
* Build/check/install: `make` (or `make install`, `make check`, `make document`)
* Test all: `Rscript -e 'devtools::test()'`
* Test single: `Rscript -e 'devtools::test_file("tests/testthat/test-filename.R")'`
* Lint: `Rscript -e 'lintr::lint_package()'`
* Style: `Rscript -e 'styler::style_pkg()'`
* Site: `make site`

## Code Style
* Functions: snake_case for public, .dot_prefix for internal, new_* for constructors
* Documentation: roxygen2 with markdown = TRUE
* Imports: Top of file, one per line, alphabetized
* Types: S3 classes with explicit structure() and class attributes
* Error handling: stopifnot() for assertions, informative error messages
* Format: 2-space indent, 80-char width, early returns over nesting, avoid `else`
* HTTP: Use {httr2} for requests
* Follow tidyverse style guide