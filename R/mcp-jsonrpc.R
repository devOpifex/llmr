#' Write a JSON-RPC request to a mcp provider
#'
#' @param x A mcp provider
#' @param method The method to call
#' @param params The parameters to pass to the method
#' @param id The id of the request
#'
#' @return The mcp provider
#' @export
#'
#' @examples
write <- function(x, method, params = NULL, id = generate_id())
  UseMethod("write")

#' @method write mcp
#' @export
write.mcp <- function(x, method, params = NULL, id = generate_id()) {
  r <- rpc_request(method, params, id)
  print(x$is_alive())
  x$write_input(as.character(r))
  read(x)
}

#' Read a JSON-RPC response from a mcp provider
#'
#' @param x A mcp provider
#'
#' @return The response
#' @export
read <- function(x) UseMethod("read")

#' @method read mcp
#' @export
read.mcp <- function(x) {
  x$read_output()
}

rpc_request <- function(method, params = NULL, id = generate_id()) {
  r <- list(
    jsonrpc = "2.0",
    method = method,
    params = params,
    id = id
  )

  r <- Filter(Negate(is.null), r)
  to_json(r)
}

to_json <- function(x) jsonlite::toJSON(x, auto_unbox = TRUE)

from_json <- function(x) jsonlite::fromJSON(x, simplifyVector = TRUE)
