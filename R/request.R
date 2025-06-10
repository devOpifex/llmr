#' Make a request to an LLM provider
#'
#' @param provider An object of class `provider`.
#' @param message A message object.
#'
#' @return A response object
#' @export
#'
#' @name request
request <- function(provider, message) UseMethod("request")

#' @method request provider_anthropic
#' @export
request.provider_anthropic <- function(provider, message) {
  provider <- append_message(provider, message)

  body <- list(
    model = attr(provider, "model"),
    max_tokens = attr(provider, "max_tokens"),
    messages = provider$env$messages
  )

  # Add tools if available
  if (length(provider$env$tools)) {
    body$tools <- provider$env$tools
  }

  req <- httr2::request(provider$url) |>
    httr2::req_url_path(path = "v1/messages") |>
    httr2::req_headers(
      "content-type" = "application/json",
      "x-api-key" = attr(provider, "key"),
      "anthropic-version" = attr(provider, "version")
    ) |>
    httr2::req_body_json(body) |>
    httr2::req_method("POST")

  response <- req |>
    httr2::req_perform()

  if (httr2::resp_status(response) != 200) {
    stop(
      sprintf(
        "LLM provider returned an error: %s",
        httr2::resp_status_desc(response)
      )
    )
  }

  response <- httr2::resp_body_json(response)

  provider <- append_message(
    provider,
    new_message(response$content, role = "assistant")
  )

  # Handle the response (for tool_use etc.)
  handle_response(provider, response)
}

#' Handle response from an LLM provider
#'
#' @param provider An object of class `provider`.
#' @param response A response object from the LLM provider.
#' @param loop Whether to loop the request or not..
#'
#' @return A response object
#' @export
handle_response <- function(provider, response, loop = TRUE)
  UseMethod("handle_response")

#' @method handle_response provider_anthropic
#' @export
handle_response.provider_anthropic <- function(
  provider,
  response,
  loop = TRUE
) {
  if (length(response$stop_reason) && response$stop_reason == "tool_use") {
    tool_response <- handle_tool_use(provider, response)

    if (!length(tool_response)) return(response)

    if (!loop) {
      return(tool_response)
    }

    return(request(provider, new_message(tool_response, role = "user")))
  }

  response
}

#' Handle tool use in a response
#'
#' @param provider An object of class `provider`.
#' @param response A response object from the LLM provider.
#'
#' @return A formatted tool response
handle_tool_use <- function(provider, response) {
  results <- lapply(response$content, function(message) {
    if (!length(message$type)) return()

    if (message$type != "tool_use") return()

    tool_call <- message

    # Parse the tool name to check if it's namespaced
    tool_name <- tool_call$name
    parts <- strsplit(tool_name, "__")[[1]]

    if (length(parts) == 2) {
      # Namespaced tool
      mcp_name <- parts[1]
      actual_tool_name <- parts[2]

      # Find the appropriate MCP
      mcp <- find_mcp_by_name(provider, mcp_name)

      if (is.null(mcp)) {
        warning(sprintf("MCP '%s' not found", mcp_name))
        return(list(
          type = "tool_result",
          tool_use_id = tool_call$id,
          content = sprintf("Error: MCP '%s' not found", mcp_name)
        ))
      }

      params <- list(
        name = actual_tool_name,
        arguments = tool_call$input
      )

      # Call the tool
      tryCatch(
        {
          result <- mcpr::tools_call(
            mcp,
            params,
            tool_call$id
          )

          # Return the tool result
          list(
            type = "tool_result",
            tool_use_id = tool_call$id,
            content = result$content
          )
        },
        error = function(e) {
          list(
            type = "tool_result",
            tool_use_id = tool_call$id,
            content = sprintf("Error calling tool: %s", e$message)
          )
        }
      )
    } else {
      # Non-namespaced tool (not supported)
      list(
        type = "tool_result",
        tool_call_id = tool_call$id,
        content = "Error: Non-namespaced tools not supported"
      )
    }
  })

  Filter(Negate(is.null), results)
}

#' Find an MCP by name
#'
#' @param provider An object of class `provider`.
#' @param name The name of the MCP to find.
#'
#' @return An MCP object or NULL if not found
find_mcp_by_name <- function(provider, name) {
  for (mcp in provider$env$mcps) {
    if (attr(mcp, "name") == name) {
      return(mcp)
    }
  }
  NULL
}
