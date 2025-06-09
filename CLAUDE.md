# CLAUDE.md - Guidelines for llmr R Package

## Development Commands
* Build package: `R CMD build .`
* Check package: `R CMD check --as-cran llmr_*.tar.gz`
* Install package: `R CMD INSTALL .`
* Run tests: `Rscript -e 'devtools::test()'`
* Run single test: `Rscript -e 'devtools::test_file("tests/testthat/test-filename.R")'`
* Documentation: `Rscript -e 'devtools::document()'`
* Lint code: `Rscript -e 'lintr::lint_package()'`
* Style code: `Rscript -e 'styler::style_pkg()'`

## Code Style Guidelines
* Use roxygen2 for documentation (with markdown = TRUE)
* Function names: use snake_case for public functions, dot prefix for internal functions
* Constructor pattern: use `new_*` prefix for constructors
* Imports: Place at top of file, one per line, alphabetized
* Types: Use R's S3 class system with explicit structure() and class attributes
* Error handling: Use stopifnot() for assertions, provide informative error messages
* Format: 2-space indentation, 80-character line width
* Follow tidyverse style guide for other conventions
* Prioritze early returns over nesting, avoid `else`
* Use {httr2} for HTTP requests
