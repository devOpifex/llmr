#' Register a memory client provider
#'
#' @param x An object of class `agent`.
#' @param mcp An object of class `client` from the "mcpr" package.
#'
#' @return A provider object
#' @export
register_mcp <- function(x, mcp) UseMethod("register_mcp")

#' @method register_mcp agent
#' @export
register_mcp.agent <- function(x, mcp) {
  if (inherits(x$provider, "provider_ellmer")) {
    register_mcp_ellmer(x, mcp)
  } else {
    x$env$mcps <- c(x$env$mcps, list(mcp))

    tools <- tryCatch(
      mcpr::tools_list(mcp),
      error = function(e) e
    )

    if (inherits(tools, "error")) {
      stop(
        sprintf(
          "Could not retrieve tools from MCP client provider: %s",
          tools$message
        )
      )
    }

    tools <- mcp_to_provider_tools(x$provider, tools$result$tools)
    tools <- namespace(mcp, tools)
    x$env$tools <- c(x$env$tools, tools)
  }

  invisible(x)
}

namespace <- function(mcp, tools) {
  lapply(tools, function(tool) {
    tool$name <- sprintf("%s__%s", mcpr::get_name(mcp), tool$name)
    tool
  })
}

mcp_to_provider_tools <- function(provider, tools) {
  UseMethod("mcp_to_provider_tools")
}

#' @method mcp_to_provider_tools provider_anthropic
#' @export
mcp_to_provider_tools.provider_anthropic <- function(provider, tools) {
  lapply(tools, function(tool) {
    tool$input_schema <- tool$inputSchema
    tool$input_schema$additionalProperties <- NULL
    tool$inputSchema <- NULL

    tool$input_schema$properties <- tool$input_schema$properties |>
      lapply(function(prop) {
        prop$title <- NULL
        prop
      })
    tool
  })
}

#' @method mcp_to_provider_tools provider_openai
#' @export
mcp_to_provider_tools.provider_openai <- function(provider, tools) {
  lapply(tools, function(tool) {
    tool$parameters <- tool$inputSchema
    tool$parameters$additionalProperties <- NULL
    tool$inputSchema <- NULL

    tool$type <- "function"

    tool$parameters$properties <- tool$parameters$properties |>
      lapply(function(prop) {
        prop$title <- NULL
        prop
      })

    list(
      type = "function",
      `function` = tool
    )
  })
}
