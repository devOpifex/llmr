#' Set the version for an LLM provider
#'
#' @param x A provider object
#' @param version Character string specifying the API version
#' @param ... Additional arguments passed to methods
#'
#' @return The modified object
#' @export
set_version <- function(x, version, ...) UseMethod("set_version")

#' @export
set_version.provider_anthropic <- function(x, version, ...) {
  stopifnot(!missing(version))
  stopifnot(is.character(version), length(version) == 1)

  attr(x, "version") <- version

  invisible(x)
}

