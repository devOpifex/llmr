#' Set the maximum number of tool calls for an LLM provider
#'
#' @param x An object
#' @param max Character string containing the system max
#' @param ... Additional arguments passed to methods
#'
#' @return The modified object
#' @export
#' @name set_max_tool_calls
set_max_tool_calls <- function(x, max, ...) UseMethod("set_max_tool_calls")

#' @method set_max_tool_calls provider
#' @export
set_max_tool_calls.provider <- function(x, max, ...) {
  stopifnot(is.character(max), length(max) == 1)
  attr(x, "max_tool_calls") <- max
  invisible(x)
}

#' @method set_max_tool_calls agent
#' @export
set_max_tool_calls.agent <- function(x, max, ...) {
  attr(x, "max_tool_calls") <- max
  set_max_tool_calls(x$provider, max)
  invisible(x)
}

get_max_tool_calls <- function(x, ...) {
  v <- attr(x, "max_tool_calls")

  if (!length(v)) {
    return(25)
  }

  v
}

#' Increment the number of tool calls for an LLM provider
#'
#' @param x An object
#' @param ... Additional arguments passed to methods
#'
#' @return The modified object
#' @export
#' @keywords internal
increment_tool_calls <- function(x, ...) UseMethod("increment_tool_calls")

#' @method increment_tool_calls agent
#' @export
increment_tool_calls.agent <- function(x, ...) {
  v <- attr(x, "tool_calls")
  if (!length(v)) {
    v <- 0
  }
  attr(x, "tool_calls") <- v + 1
  invisible(x)
}

#' @method increment_tool_calls provider
#' @export
increment_tool_calls.provider <- function(x, ...) {
  v <- attr(x, "tool_calls")
  if (!length(v)) {
    v <- 0
  }
  attr(x, "tool_calls") <- v + 1
  invisible(x)
}
