#' Set Retry Parameters for LLM Provider
#'
#' Configure retry behavior for API requests made by the provider.
#'
#' @param provider Provider object created with `new_provider()` or a specific provider constructor.
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
  provider,
  max_tries = 3
) {
  UseMethod("set_retry")
}

#' @method set_retry provider
#' @export
set_retry.provider <- function(
  provider,
  max_tries = 3
) {
  stopifnot(inherits(provider, "provider"))

  # Store retry parameters in the provider's environment
  provider$env$retry <- list(
    max_tries = max_tries
  )

  invisible(provider)
}
