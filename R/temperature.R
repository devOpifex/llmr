#' Set the temperature for an LLM provider
#'
#' @param x An object of class `provider` or `agent`
#' @param temperature Numeric value specifying the temperature (typically between 0 and 1)
#' @param ... Additional arguments passed to methods
#'
#' @return The modified object
#' @export
set_temperature <- function(x, temperature, ...) UseMethod("set_temperature")

#' @method set_temperature provider_anthropic
#' @export
set_temperature.provider_anthropic <- function(x, temperature, ...) {
  stopifnot(!missing(temperature))
  stopifnot(is.numeric(temperature), length(temperature) == 1)
  stopifnot(temperature >= 0, temperature <= 1)

  attr(x, "temperature") <- temperature

  invisible(x)
}


#' @method set_temperature agent
#' @export
set_temperature.agent <- function(x, temperature, ...) {
  x$provider <- set_temperature(x$provider, temperature)
  invisible(x)
}
