#' Set the model for an LLM provider
#'
#' @param x An object
#' @param name Character string specifying the model name
#' @param ... Additional arguments passed to methods
#'
#' @return The modified object
#' @export
#' @name set_model
set_model <- function(x, name, ...) UseMethod("set_model")

#' @method set_model provider
#' @export
set_model.provider <- function(x, name, ...) {
  stopifnot(is.character(name), length(name) == 1)
  attr(x, "model") <- name
  invisible(x)
}

#' @method set_model agent
#' @export
set_model.agent <- function(x, name, ...) {
  x$provider <- set_model(x$provider, name)
  invisible(x)
}
