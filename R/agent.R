#' Create a new agent
#'
#' Creates a new agent with the specified name and provider.
#'
#' @param name Character string specifying the agent name.
#' @param provider An object of class `provider` or a function that returns a provider.
#' @param ... Additional arguments passed to methods.
#'
#' @details
#' The `provider` argument can be either a `provider` object or a function that returns a `provider` object.
#' If a function is provided, it will be called with no arguments and the result will be used as the provider.
#' This is recommended so agents are isolated from each other and do not share state as they would with
#' an instance of a `provider`.
#'
#' @return An object of class "agent"
#' @export
new_agent <- function(name, provider, ...) {
  UseMethod("new_agent", provider)
}

#' @method new_agent provider
#' @export
new_agent.provider <- function(name, provider, ...) {
  warning(
    "It is advised to pass the `provider` as a factory function, see details in ?new_agent."
  )
  create_agent(name, provider, ...)
}

#' @method new_agent function
#' @export
new_agent.function <- function(name, provider, ...) {
  instance <- tryCatch(provider(), error = function(e) e)

  if (inherits(instance, "error")) {
    stop(
      sprintf(
        "Error creating agent: %s",
        conditionMessage(instance)
      )
    )
  }

  if (!inherits(instance, "provider")) {
    stop("The provider function must return an object of class 'provider'")
  }

  create_agent(name, instance, ...)
}

#' @method new_agent Chat
#' @export
new_agent.Chat <- function(name, provider, ...) {
  # Handle ellmer Chat objects directly
  create_agent(name, provider, ...)
}

create_agent <- function(name, provider, ...) {
  env <- new.env(parent = emptyenv())
  env$tools <- list()
  env$messages <- list()
  env$mcps <- list()

  agent <- structure(
    list(
      env = env,
      provider = provider
    ),
    name = name,
    system = "",
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
add_tool <- function(x, tool, ...) UseMethod("add_tool", tool)

#' @method add_tool tool
#' @export
add_tool.tool <- function(x, tool, ...) {
  if (inherits(x$provider, "Chat")) {
    add_tool_ellmer(x, tool, ...)
  } else {
    x$env$tools <- c(x$env$tools, mcp_to_provider_tools(x$provider, list(tool)))
  }
  invisible(x)
}

#' @method add_tool ellmer::ToolDef
#' @export
`add_tool.ellmer::ToolDef` <- function(x, tool, ...) {
  if (inherits(x$provider, "Chat")) {
    add_tool_ellmer(x, tool, ...)
  } else {
    tool <- mcpr::ellmer_to_mcpr_tool(tool)
    x$env$tools <- c(x$env$tools, mcp_to_provider_tools(x$provider, list(tool)))
  }
  invisible(x)
}
