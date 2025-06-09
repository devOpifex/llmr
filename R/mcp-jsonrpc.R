#' Write a JSON-RPC request to a mcp provider
#'
#' @param x A mcp provider
#' @param method The method to call
#' @param params The parameters to pass to the method
#' @param id The id of the request
#' @param timeout Timeout in milliseconds for reading the response
#'
#' @return The mcp provider
#' @export
#'
#' @examples
write <- function(x, method, params = NULL, id = generate_id(), timeout = 5000)
  UseMethod("write")

#' @method write mcp
#' @export
write.mcp <- function(
  x,
  method,
  params = NULL,
  id = generate_id(),
  timeout = 5000
) {
  # Check if process is alive before writing
  if (!x$is_alive()) {
    stop("MCP process is not alive")
  }

  # Create and write the request with proper newline
  r <- rpc_request(method, params, id)
  x$write_input(sprintf("%s\n", r))

  # Read the response with the specified timeout
  read(x, timeout)
}

#' Read a JSON-RPC response from a mcp provider
#'
#' @param x A mcp provider
#' @param timeout Timeout in milliseconds for reading the response
#'
#' @return The response
#' @export
read <- function(x, timeout = 60 * 1000) UseMethod("read")

#' @method read mcp
#' @export
read.mcp <- function(x, timeout = 60 * 1000) {
  # Check if process is alive before reading
  if (!x$is_alive()) {
    stop("MCP process is not alive")
  }

  # Use poll_io with timeout to wait for response
  poll_result <- x$poll_io(timeout)

  # Check if we have data to read
  if (poll_result["output"] == "ready") {
    # Read the output when it's ready
    return(x$read_output())
  } else if (poll_result["output"] == "timeout") {
    warning("Timeout waiting for MCP response")
    return(NULL)
  } else {
    # Process closed the connection or other issue
    warning("MCP connection closed or error")
    return(NULL)
  }
}

rpc_request <- function(method, params = NULL, id = generate_id()) {
  r <- list(
    jsonrpc = "2.0",
    method = method,
    params = params,
    id = id
  )

  r <- Filter(Negate(is.null), r)
  to_json(r) |>
    as.character()
}

to_json <- function(x) jsonlite::toJSON(x, auto_unbox = TRUE)

from_json <- function(x) jsonlite::fromJSON(x, simplifyVector = TRUE)
