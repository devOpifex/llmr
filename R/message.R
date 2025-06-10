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
new_message <- function(content, role = "user") {
  structure(
    list(
      role = role,
      content = content
    ),
    class = c("message", "list")
  )
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
append_message <- function(provider, message) {
  if (!inherits(message, "message")) {
    stop("message must be an object of class 'message'")
  }
  provider$env$messages <- c(provider$env$messages, list(message))
  invisible(provider)
}
