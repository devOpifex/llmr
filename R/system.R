#' Set the system prompt for an LLM provider
#'
#' @param x An object
#' @param prompt Character string containing the system prompt
#' @param ... Additional arguments passed to methods
#'
#' @return The modified object
#' @export
#' @name set_system_prompt
set_system_prompt <- function(x, prompt, ...) UseMethod("set_system_prompt")

#' @method set_system_prompt provider_anthropic
#' @export
set_system_prompt.provider_anthropic <- function(x, prompt, ...) {
  stopifnot(is.character(prompt), length(prompt) == 1)

  attr(x, "system") <- prompt

  x
}

#' @method set_system_prompt provider_openai
#' @export
set_system_prompt.provider_openai <- function(x, prompt, ...) {
  stopifnot(is.character(prompt), length(prompt) == 1)

  x <- append_message(x, new_message(prompt, role = "system"))

  x
}

#' @method set_system_prompt agent
#' @export
set_system_prompt.agent <- function(x, prompt, ...) {
  set_system_prompt(x$provider, prompt)
}
