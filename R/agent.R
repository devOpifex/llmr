#' Create a new agent
#'
#' Creates a new agent with the specified name and provider.
#'
#' @param name Character string specifying the agent name.
#' @param provider An object of class `provider` or a function that returns a provider.
#' @param approval_callback Optional function for human approval of tool calls.
#'   Should accept a tool_info parameter and return TRUE/FALSE or a character string.
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
new_agent <- function(name, provider, approval_callback = NULL, ...) {
  UseMethod("new_agent", provider)
}

#' @method new_agent provider
#' @export
new_agent.provider <- function(name, provider, approval_callback = NULL, ...) {
  warning(
    "It is advised to pass the `provider` as a factory function, see details in ?new_agent."
  )
  create_agent(name, provider, approval_callback = approval_callback, ...)
}

#' @method new_agent function
#' @export
new_agent.function <- function(name, provider, approval_callback = NULL, ...) {
  instance <- tryCatch(provider(), error = function(e) e)

  if (inherits(instance, "error")) {
    stop(
      sprintf(
        "Error creating agent: %s",
        conditionMessage(instance)
      )
    )
  }

  if (!inherits(instance, "provider") && !inherits(instance, "Chat")) {
    stop(
      "The provider function must return an object of class 'provider' or 'Chat'."
    )
  }

  create_agent(name, instance, approval_callback = approval_callback, ...)
}

#' @method new_agent Chat
#' @export
new_agent.Chat <- function(name, provider, approval_callback = NULL, ...) {
  # Handle ellmer Chat objects directly
  create_agent(name, provider, approval_callback = approval_callback, ...)
}

create_agent <- function(name, provider, approval_callback = NULL, ...) {
  # Validate approval_callback if provided
  if (!is.null(approval_callback) && !is.function(approval_callback)) {
    stop("approval_callback must be a function or NULL")
  }

  env <- new.env(parent = emptyenv())
  env$tools <- list()
  env$messages <- list()
  env$mcps <- list()
  env$approval_callback <- approval_callback

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

#' Set approval callback for human-in-the-loop tool execution
#'
#' @param agent An agent object
#' @param callback_fn A function that takes tool information and returns TRUE/FALSE for approval
#'
#' @details
#' The callback function receives a list with the following elements:
#' - `name`: The name of the tool being called
#' - `arguments`: A list of arguments passed to the tool
#' - `id`: The unique identifier for this tool call
#'
#' The callback should return:
#' - `TRUE` to approve the tool execution
#' - `FALSE` to deny the tool execution
#' - A character string to deny with a custom error message
#'
#' @return The modified agent (invisibly)
#' @export
set_approval_callback <- function(agent, callback_fn) {
  if (!inherits(agent, "agent")) {
    stop("agent must be an agent object")
  }

  if (!is.function(callback_fn) && !is.null(callback_fn)) {
    stop("callback_fn must be a function or NULL")
  }

  agent$env$approval_callback <- callback_fn

  if (inherits(agent$provider, "Chat")) {
    setup_approval_integration(agent)
  }

  invisible(agent)
}

#' Setup approval integration with ellmer Chat objects
#'
#' @param agent An agent with ellmer Chat provider
#' @keywords internal
setup_approval_integration <- function(agent) {
  if (is.null(agent$env$approval_callback)) {
    return(invisible(agent))
  }

  agent$provider$on_tool_request(function(request) {
    tool_info <- list(
      name = request@name,
      arguments = request@arguments,
      id = request@id
    )

    approved <- agent$env$approval_callback(tool_info)

    if (!isTRUE(approved)) {
      reason <- if (is.character(approved)) {
        approved
      } else {
        "Human denied tool execution"
      }
      # Create error condition with ellmer_tool_reject class
      err <- structure(
        list(message = reason, call = NULL),
        class = c("ellmer_tool_reject", "error", "condition")
      )
      stop(err)
    }
  })

  invisible(agent)
}
