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
      content = as.character(content)
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
#' @examples
#' response <- clear_messages(provider)
#' @name clear_messages
clear_messages <- function(provider) {
  provider$messages <- list()
  invisible(provider)
}
