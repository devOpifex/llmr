#' Set the token for an LLM provider
#'
#' @param x A provider object
#' @param ... Additional arguments passed to methods
#' @param max Integer specifying the maximum number of tokens to generate
#'
#' @return The modified object
#' @export
set_max_tokens <- function(x, max, ...) UseMethod("set_max_tokens")

#' @method set_max_tokens provider
#' @export
set_max_tokens.provider <- function(x, max, ...) {
  stopifnot(!missing(max))
  stopifnot(is.numeric(max), length(max) == 1)

  attr(x, "max_tokens") <- max

  invisible(x)
}

#' @method set_max_tokens agent
#' @export
set_max_tokens.agent <- function(x, max, ...) {
  x$provider <- set_max_tokens(x$provider, max)
  invisible(x)
}
