#' Set the key for an LLM provider
#'
#' @param x A provider object
#' @param key Character string specifying the API key
#' @param ... Additional arguments passed to methods
#'
#' @return The modified object
#' @export
set_api_key <- function(x, key, ...) UseMethod("set_api_key")

#' @export
#' @method set_api_key provider
set_api_key.provider <- function(x, key, ...) {
  stopifnot(!missing(key))
  stopifnot(is.character(key), length(key) == 1)

  attr(x, "key") <- key

  invisible(x)
}

#' @export
#' @method set_api_key agent
set_api_key.agent <- function(x, key, ...) {
  x$provider <- set_api_key(x$provider, key)
  invisible(x)
}
