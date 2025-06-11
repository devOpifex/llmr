#' Create a provider
#'
#' @param name Name of the provider
#' @param url URL of the provider
#' @param ... Additional options
#'
#' @return A provider object
#' @export
#'
#' @examples
#' provider <- new_anthropic()
#' @name provider
new_provider <- function(name, url, ...) {
  cls <- paste0("provider_", name)

  env <- new.env()
  env$messages <- list()
  env$mcps <- list()
  env$tools <- list()

  p <- structure(
    list(
      url = gsub("/$", "", url),
      options = list(...),
      env = env
    ),
    name = name,
    key = "",
    version = "",
    class = c(cls, "provider")
  )

  invisible(p)
}

#' @rdname provider
#' @export
new_anthropic <- function(
  url = "https://api.anthropic.com/v1",
  ...
) {
  new_provider("anthropic", url, ...) |>
    set_api_key(Sys.getenv("ANTHROPIC_API_KEY")) |>
    set_model("claude-opus-4-20250514") |>
    set_version("2023-06-01") |>
    set_max_tokens(1024)
}

#' @rdname provider
#' @export
new_openai <- function(
  url = "https://api.openai.com",
  ...
) {
  new_provider("openai", url, ...) |>
    set_api_key(Sys.getenv("OPENAI_API_KEY")) |>
    set_model("gpt-4")
}
