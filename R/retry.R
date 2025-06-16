#' Set Retry Parameters for LLM Provider
#'
#' Configure retry behavior for API requests made by the provider.
#'
#' @param x An object of class `provider` or `agent`.
#' @param max_tries Maximum number of retry attempts (default: 3).
#'
#' @return The provider object with updated retry settings.
#'
#' @examples
#' \dontrun{
#' provider <- new_anthropic() |>
#'   set_retry(max_tries = 5)
#' }
set_retry <- function(
  x,
  max_tries = 3
) {
  UseMethod("set_retry")
}

#' @method set_retry provider
#' @export
set_retry.provider <- function(
  x,
  max_tries = 3
) {
  stopifnot(inherits(provider, "provider"))

  x$env$retry <- list(
    max_tries = max_tries
  )

  invisible(provider)
}

#' @method set_retry agent
#' @export
set_retry.agent <- function(
  x,
  max_tries = 3
) {
  set_retry(x$provider, max_tries)
  invisible(x)
}
