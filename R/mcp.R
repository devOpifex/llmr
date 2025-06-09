#' Register a memory client provider
#'
#' @param provider An object of class `provider`.
#' @param mcp An object of class `client` from the "mcpr" package.
#'
#' @return A provider object
#' @export
register_mcp <- function(provider, mcp) UseMethod("register_mcp", mcp)

#' @method register_mcp client
#' @export
register_mcp.client <- function(provider, mcp) {
  provider$env$mcps <- c(provider$env$mcps, list(mcp))

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

  tools <- mcp_to_provider_tools(tools$result$tools)
  tools <- namespace(mcp, tools)
  provider$env$tools <- c(provider$env$tools, tools)

  invisible(provider)
}

namespace <- function(mcp, tools) {
  lapply(tools, function(tool) {
    tool$name <- sprintf("%s__%s", attr(mcp, "name"), tool$name)
    tool
  })
}

mcp_to_provider_tools <- function(tools) {
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
