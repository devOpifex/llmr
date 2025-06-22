#' Request method for ellmer providers
#'
#' @param x An ellmer provider object
#' @param message A message or list of messages
#' @param ... Additional arguments
#' @param tools Optional list of tools
#'
#' @return Response from ellmer
#' @method request provider_ellmer
#' @export
request.provider_ellmer <- function(x, message = NULL, ..., tools = NULL) {
  # Handle message input
  if (is.character(message)) {
    # Single string message
    response <- x$chat$chat(message, echo = "none")
  } else if (is.list(message)) {
    # List of messages - convert to ellmer format
    for (msg in message) {
      if (inherits(msg, "message")) {
        if (msg$role == "user") {
          x$chat$chat(msg$content, echo = "none")
        }
        # Assistant messages are already in chat history
      }
    }
    response <- x$chat$last_turn()@text
  } else if (is.null(message)) {
    # No new message, just get last response
    response <- x$chat$last_turn()@text
  } else {
    stop("message must be a character string, list of messages, or NULL")
  }
  
  # Return in format expected by llmr
  list(
    content = response,
    role = "assistant"
  )
}

#' Handle response for ellmer providers
#'
#' @param x An ellmer provider object
#' @param agent An agent object
#' @param response Response from ellmer
#' @param loop Whether to continue tool loops
#'
#' @return Updated agent
#' @method handle_response provider_ellmer
#' @export
handle_response.provider_ellmer <- function(x, agent, response, loop = TRUE) {
  # ellmer handles tool calling internally, so we just need to
  # sync the conversation history with the agent
  
  # Get the latest turns from ellmer chat
  turns <- x$chat$get_turns()
  
  # Convert ellmer turns to llmr messages
  messages <- lapply(turns, function(turn) {
    new_message(turn@text, role = turn@role)
  })
  
  # Update agent's message history
  agent$env$messages <- messages
  
  agent
}

#' Handle tool use for ellmer providers
#'
#' @param provider An ellmer provider object
#' @param response Response containing tool calls
#' @param tools Available tools
#' @param mcps Available MCPs
#'
#' @return Tool results
#' @method handle_tool_use provider_ellmer
#' @export
handle_tool_use.provider_ellmer <- function(provider, response, tools = NULL, mcps = NULL) {
  # ellmer handles tool execution internally
  # This method is mainly for compatibility
  list()
}