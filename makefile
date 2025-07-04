default: check

document:
	R -s -e "devtools::document()"

check: document 
	R -s -e "devtools::check(document = FALSE, vignettes = FALSE)"

install:
	R -s -e "devtools::install()"

site: document
	R -s -e "pkgdown::build_site()"

article:
	R -s -e "pkgdown::build_article('$(a)')"
