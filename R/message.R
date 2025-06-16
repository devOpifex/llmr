#' Create a message
#'
#' @param content Content of the message
#' @param role Role of the message
#' @param tool_calls Optional tool calls for OpenAI
#' @param tool_call_id Optional tool call ID for OpenAI tool responses
#'
#' @return A message object
#' @export
#'
#' @examples
#' message <- new_message("Hello, world!")
#' @name message
new_message <- function(
  content,
  role = "user",
  tool_calls = NULL,
  tool_call_id = NULL,
  tool_use_id = NULL,
  type = NULL
) {
  message <- list(
    role = role,
    content = content
  )

  # Add tool_calls if provided (for OpenAI)
  if (!is.null(tool_calls)) {
    message$tool_calls <- tool_calls
  }

  # Add tool_call_id if provided (for OpenAI tool responses)
  if (!is.null(tool_call_id)) {
    message$tool_call_id <- tool_call_id
  }

  if (!is.null(tool_use_id)) {
    message$tool_use_id <- tool_use_id
  }

  if (!is.null(type)) {
    message$type <- type
  }

  structure(
    message,
    class = c("message", "list")
  )
}

as_message <- function(x) {
  class(x) <- c("message", "list")
  x
}

#' Clear messages
#'
#' @param provider An object of class `provider`.
#'
#' @return A response object
#' @export
#'
#' @name clear_messages
clear_messages <- function(provider) {
  provider$env$messages <- list()
  invisible(provider)
}

#' Add a message to the list
#'
#' @param provider An object of class `provider`.
#' @param message A message object.
append_message <- function(x, message) UseMethod("append_message")

#' @method append_message agent
#' @export
append_message.agent <- function(x, message) {
  if (!inherits(message, "message")) {
    stop("message must be an object of class 'message'")
  }
  x$env$messages <- c(x$env$messages, list(message))
  invisible(x)
}

#' Get messages
#'
#' @param x An object of class `agent`.
#'
#' @return A list of messages
get_messages <- function(x) UseMethod("get_messages")

#' @method get_messages agent
#' @export
get_messages.agent <- function(x) {
  x$env$messages |> lapply(unclass)
}
