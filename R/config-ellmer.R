#' Configuration methods for ellmer providers
#'
#' These methods provide compatibility with llmr's configuration API
#' while delegating to ellmer's underlying provider configuration.

#' Set API key for ellmer provider
#'
#' @param x An ellmer provider object
#' @param key API key string
#' @param ... Additional arguments
#'
#' @return The modified provider
#' @method set_api_key provider_ellmer
#' @export
set_api_key.provider_ellmer <- function(x, key, ...) {
  warning("API key configuration not supported for ellmer providers. Please configure when creating the ellmer chat object.")
  invisible(x)
}

#' Set model for ellmer provider
#'
#' @param x An ellmer provider object
#' @param name Model name
#' @param ... Additional arguments
#'
#' @return The modified provider
#' @method set_model provider_ellmer
#' @export
set_model.provider_ellmer <- function(x, name, ...) {
  warning("Model configuration not supported for ellmer providers. Please configure when creating the ellmer chat object.")
  invisible(x)
}

#' Set temperature for ellmer provider
#'
#' @param x An ellmer provider object
#' @param temperature Temperature value
#' @param ... Additional arguments
#'
#' @return The modified provider
#' @method set_temperature provider_ellmer
#' @export
set_temperature.provider_ellmer <- function(x, temperature, ...) {
  warning("Temperature configuration not supported for ellmer providers. Please configure when creating the ellmer chat object.")
  invisible(x)
}

#' Set max tokens for ellmer provider
#'
#' @param x An ellmer provider object
#' @param max Maximum tokens
#' @param ... Additional arguments
#'
#' @return The modified provider
#' @method set_max_tokens provider_ellmer
#' @export
set_max_tokens.provider_ellmer <- function(x, max, ...) {
  warning("Max tokens configuration not supported for ellmer providers. Please configure when creating the ellmer chat object.")
  invisible(x)
}

#' Set system prompt for ellmer provider
#'
#' @param x An ellmer provider object
#' @param prompt System prompt string
#' @param ... Additional arguments
#'
#' @return The modified provider
#' @method set_system_prompt provider_ellmer
#' @export
set_system_prompt.provider_ellmer <- function(x, prompt, ...) {
  # ellmer handles system prompts directly
  x$chat$set_system_prompt(prompt)
  
  invisible(x)
}

#' Set retry configuration for ellmer provider
#'
#' @param x An ellmer provider object
#' @param max_tries Maximum retry attempts
#' @param ... Additional arguments
#'
#' @return The modified provider
#' @method set_retry provider_ellmer
#' @export
set_retry.provider_ellmer <- function(x, max_tries = 3, ...) {
  # ellmer doesn't expose retry configuration directly
  # This is a no-op for compatibility
  warning("Retry configuration not supported for ellmer providers")
  invisible(x)
}

#' Set version for ellmer provider
#'
#' @param x An ellmer provider object
#' @param version API version
#' @param ... Additional arguments
#'
#' @return The modified provider
#' @method set_version provider_ellmer
#' @export
set_version.provider_ellmer <- function(x, version, ...) {
  # ellmer handles API versions internally
  # This is a no-op for compatibility
  warning("Version configuration not supported for ellmer providers")
  invisible(x)
}