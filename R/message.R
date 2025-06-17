#' Create a message
#'
#' @param content Content of the message
#' @param role Role of the message
#'
#' @return A message object
#' @export
#'
#' @examples
#' message <- new_message("Hello, world!")
#' @name message
new_message <- function(
  content,
  role = "user"
) {
  message <- list(
    role = role,
    content = content
  )

  structure(
    message,
    class = c("message", "list")
  )
}

as_message <- function(x) {
  class(x) <- c("message", "list")
  x
}

#' @export
print.message <- function(x, ...) {
  cat(sprintf("%s: %s\n", x$role, x$content))
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
#' @param x An object of class `agent`.
#' @param message A message object.
#' @export
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
#' @export
get_messages <- function(x) UseMethod("get_messages")

#' @method get_messages agent
#' @export
get_messages.agent <- function(x) {
  x$env$messages |> lapply(unclass)
}

#' Get last message
#'
#' @param x An object of class `agent`.
#'
#' @return A list of messages
#' @export
get_last_message <- function(x) UseMethod("get_last_message")

#' @method get_last_message agent
#' @export
get_last_message.agent <- function(x) {
  x$env$messages[[length(x$env$messages)]] |> unclass()
}
