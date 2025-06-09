#' Register a memory client provider
#'
#' @param provider An object of class `provider`.
#' @param mcp An object of class `client` from the {mcpr} package.
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

  provider$env$tools[[attr(mcp, "name")]] <- namespace(mcp, tools)

  invisible(provider)
}

namespace <- function(mcp, tools) {
  lapply(tools, function(tool) {
    tool$name <- sprintf("%s::%s", attr(mcp, "name"), tool$name)
    tool
  })
}
