#' Create a new agent
#'
#' Creates a new agent with the specified name
#'
#' @param name Character string specifying the agent name
#' @param provider An object of class `provider`.
#'
#' @return An object of class "agent"
#' @export
new_agent <- function(name, provider) {
  stopifnot(is.character(name), length(name) == 1)
  stopifnot(!missing(provider), inherits(provider, "provider"))

  # Create a new environment for the agent
  env <- new.env(parent = emptyenv())
  env$tools <- list()
  env$messages <- list()
  env$mcps <- list()

  # Create the agent structure
  agent <- structure(
    list(
      env = env,
      provider = provider
    ),
    name = name,
    class = c("agent")
  )

  invisible(agent)
}

#' Add a tool to an agent
#'
#' @param x An object
#' @param tool A tool created with mcpr::new_tool
#' @param ... Additional arguments passed to methods
#'
#' @return The modified object
#' @export
#' @name add_tool
add_tool <- function(x, tool, ...) UseMethod("add_tool")

#' @method add_tool agent
#' @export
add_tool.agent <- function(x, tool, ...) {
  stopifnot(inherits(tool, c("capability", "tool")))

  # Add the tool to the agent's tool registry
  x$env$tools <- c(x$env$tools, mcp_to_provider_tools(x$provider, list(tool)))

  invisible(x)
}
