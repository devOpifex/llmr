#' Set the temperature for an LLM provider
#'
#' @param x A provider object
#' @param temperature Numeric value specifying the temperature (typically between 0 and 1)
#' @param ... Additional arguments passed to methods
#'
#' @return The modified object
#' @export
set_temperature <- function(x, temperature, ...) UseMethod("set_temperature")

#' @export
set_temperature.provider_anthropic <- function(x, temperature, ...) {
  stopifnot(!missing(temperature))
  stopifnot(is.numeric(temperature), length(temperature) == 1)
  stopifnot(temperature >= 0, temperature <= 1)

  attr(x, "temperature") <- temperature

  invisible(x)
}