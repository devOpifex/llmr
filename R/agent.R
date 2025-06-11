#' Create a new agent
#'
#' Creates a new agent with the specified name
#'
#' @param name Character string specifying the agent name
#'
#' @return An object of class "agent"
#' @export
new_agent <- function(name) {
  stopifnot(is.character(name), length(name) == 1)

  # Create a new environment for the agent
  env <- new.env(parent = emptyenv())
  env$tools <- list()

  # Create the agent structure
  agent <- structure(
    list(
      env = env
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
  x$env$tools <- c(x$env$tools, list(tool))

  invisible(x)
}

#' Register an agent with a provider
#'
#' @param provider An object of class `provider`
#' @param agent An object of class `agent`
#' @param ... Additional arguments passed to methods
#'
#' @return The modified provider object (invisibly)
#' @export
#' @name register_agent
register_agent <- function(provider, agent, ...) UseMethod("register_agent")

#' @method register_agent provider
#' @export
register_agent.provider <- function(provider, agent, ...) {
  stopifnot(inherits(agent, "agent"))

  # Get tools from the agent
  tools <- agent$env$tools

  # Add all tools to the provider
  if (length(tools) > 0) {
    provider$env$tools <- c(
      provider$env$tools,
      mcp_to_provider_tools(provider, tools)
    )
  }

  invisible(provider)
}
