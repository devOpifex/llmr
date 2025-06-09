#' Make a request to an LLM provider
#'
#' @param provider An object of class `provider`.
#' @param message A message object.
#'
#' @return A response object
#' @export
#'
#' @name request
request <- function(provider, message) UseMethod("request")

#' @method request provider_anthropic
#' @export
request.provider_anthropic <- function(provider, message) {
  provider <- append_message(provider, message)

  body <- list(
    model = attr(provider, "model"),
    max_tokens = attr(provider, "max_tokens"),
    messages = provider$env$messages
  )

  # Add tools if available
  if (length(provider$env$tools)) {
    body$tools <- provider$env$tools
  }

  req <- httr2::request(provider$url) |>
    httr2::req_url_path(path = "v1/messages") |>
    httr2::req_headers(
      "content-type" = "application/json",
      "x-api-key" = attr(provider, "key"),
      "anthropic-version" = attr(provider, "version")
    ) |>
    httr2::req_body_json(body) |>
    httr2::req_method("POST")

  response <- req |>
    httr2::req_perform()

  if (httr2::resp_status(response) != 200) {
    stop(
      sprintf(
        "LLM provider returned an error: %s",
        httr2::resp_status_desc(response)
      )
    )
  }

  response <- httr2::resp_body_json(response)

  provider <- append_message(
    provider,
    new_message(response$content, role = "assistant")
  )

  response
}
