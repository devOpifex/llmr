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
  if (grepl(" ", name)) {
    stop("Provider name cannot contain spaces")
  }

  cls <- paste0("provider_", name)

  env <- new.env(parent = emptyenv())

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

#' @export
print.provider <- function(x, ...) {
  cat(sprintf("<%s> %s\n", x$name, x$url))
}

#' @rdname provider
#' @export
new_anthropic <- function(
  url = "https://api.anthropic.com",
  ...
) {
  .Deprecated(
    "ellmer::chat_anthropic", 
    package = "llmr",
    msg = paste(
      "new_anthropic() is deprecated and will be removed in a future version.",
      "Please use ellmer::chat_anthropic() directly instead for better performance and features.",
      "See the ellmer package documentation for migration guidance."
    )
  )
  
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
  .Deprecated(
    "ellmer::chat_openai", 
    package = "llmr",
    msg = paste(
      "new_openai() is deprecated and will be removed in a future version.",
      "Please use ellmer::chat_openai() directly instead for better performance and features.",
      "See the ellmer package documentation for migration guidance."
    )
  )
  
  new_provider("openai", url, ...) |>
    set_api_key(Sys.getenv("OPENAI_API_KEY")) |>
    set_model("gpt-4") |>
    set_max_tokens(1024)
}
