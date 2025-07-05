#' Make a request to an LLM provider
#'
#' @param x An object of class `provider` or `agent`.
#' @param message A message object.
#' @param ... Additional arguments passed to methods.
#'
#' @details You can make a request with `message = NULL`
#' The agent will send the history of the conversation to the LLM provider.
#'
#' @return A response object
#' @export
#'
#' @name request
request <- function(x, message = NULL, ...) UseMethod("request")

#' @method request agent
#' @export
request.agent <- function(x, message = NULL, ...) {
  if (!is.null(message) && is.character(message)) {
    message <- new_message(message, role = "user")
  }

  if (!is.null(message)) {
    x <- append_message(x, message)
  }

  # Handle ellmer Chat objects differently
  if (inherits(x$provider, "Chat")) {
    # Ensure approval callback is set up if one exists
    if (!is.null(x$env$approval_callback)) {
      setup_approval_integration(x)
    }
    
    # For ellmer Chat objects, just send the message directly
    # ellmer handles tool calling internally
    if (!is.null(message)) {
      response <- x$provider$chat(message$content, echo = "none")
    }

    # Sync conversation history with ellmer
    sync_ellmer_history(x)
    return(invisible(x))
  }

  # Legacy provider handling
  response <- request(
    x$provider,
    x$env$messages,
    tools = x$env$tools
  )

  # Handle the response (for tool_use etc.)
  handle_response(x$provider, x, response)

  invisible(x)
}

#' Sync conversation history with ellmer Chat object
#'
#' @param x An agent with ellmer Chat provider
#' @keywords internal
sync_ellmer_history <- function(x) {
  if (!inherits(x$provider, "Chat")) {
    return(invisible(x))
  }

  # Get the latest turns from ellmer chat
  turns <- x$provider$get_turns()

  # Convert ellmer turns to llmr messages
  messages <- lapply(turns, function(turn) {
    new_message(turn@text, role = turn@role)
  })

  # Update agent's message history
  x$env$messages <- messages

  invisible(x)
}

#' @method request provider_anthropic
#' @export
request.provider_anthropic <- function(x, message, ..., tools = NULL) {
  stopifnot(!missing(message))

  if (is.character(message)) {
    message <- list(new_message(message, role = "user"))
  }

  body <- list(
    model = attr(x, "model"),
    max_tokens = attr(x, "max_tokens"),
    messages = message
  )

  # Add system prompt if available
  if (!is.null(attr(x, "system"))) {
    body$system <- attr(x, "system")
  }

  # Add temperature if available
  if (!is.null(attr(x, "temperature"))) {
    body$temperature <- attr(x$provider, "temperature")
  }

  # Add tools if available
  if (length(tools)) {
    body$tools <- tools
  }

  req <- httr2::request(x$url) |>
    httr2::req_url_path(path = "v1/messages") |>
    httr2::req_headers(
      "content-type" = "application/json",
      "x-api-key" = attr(x, "key"),
      "anthropic-version" = attr(x, "version")
    ) |>
    httr2::req_user_agent("llmr") |>
    httr2::req_body_json(body) |>
    httr2::req_method("POST")

  # Apply retry configuration if available
  if (length(x$env$retry)) {
    req <- do.call(httr2::req_retry, c(list(req), x$env$retry))
  }

  response <- tryCatch(
    httr2::req_perform(req),
    error = function(e) e
  )

  if (inherits(response, "error")) {
    stop(response$message)
  }

  if (httr2::resp_status(response) != 200) {
    stop(
      sprintf(
        "Anthropic returned an error: %s",
        httr2::resp_status_desc(response)
      )
    )
  }

  httr2::resp_body_json(response)
}

#' @method request provider_openai
#' @export
request.provider_openai <- function(x, message, ..., tools = NULL) {
  stopifnot(!missing(message))

  if (is.character(message)) {
    message <- list(new_message(message, role = "user"))
  }

  body <- list(
    model = attr(x, "model"),
    max_tokens = attr(x, "max_tokens"),
    messages = message
  )

  # Add temperature if available
  if (!is.null(attr(x, "temperature"))) {
    body$temperature <- attr(x, "temperature")
  }

  # Add tools if available
  if (length(tools)) {
    body$tools <- tools
  }

  req <- httr2::request(x$url) |>
    httr2::req_url_path(path = "v1/chat/completions") |>
    httr2::req_headers(
      "Content-Type" = "application/json",
      "Authorization" = sprintf("Bearer %s", attr(x, "key"))
    ) |>
    httr2::req_user_agent("llmr") |>
    httr2::req_body_json(body) |>
    httr2::req_method("POST")

  # Apply retry configuration if available
  if (length(x$env$retry)) {
    req <- do.call(httr2::req_retry, c(list(req), x$env$retry))
  }

  response <- tryCatch(
    httr2::req_perform(req),
    error = function(e) e
  )

  if (inherits(response, "error")) {
    stop(response$message, call. = FALSE)
  }

  if (httr2::resp_status(response) != 200) {
    stop(
      sprintf(
        "OpenAI returned an error: %s",
        httr2::resp_status_desc(response)
      )
    )
  }

  httr2::resp_body_json(response)
}

#' Handle response from an LLM provider
#'
#' @param x An object of class `provider`.
#' @param agent An object of class `agent`.
#' @param response A response object from the LLM provider.
#' @param loop Whether to loop the request or not..
#'
#' @return A response object
#' @keywords internal
handle_response <- function(x, agent, response, loop = TRUE) {
  UseMethod("handle_response")
}

#' @method handle_response provider_anthropic
#' @export
handle_response.provider_anthropic <- function(
  x,
  agent,
  response,
  loop = TRUE
) {
  agent <- append_message(
    agent,
    new_message(response$content, role = "assistant")
  )

  if (length(response$stop_reason) && response$stop_reason == "tool_use") {
    tool_response <- handle_tool_use(
      x,
      response,
      tools = agent$env$tools,
      mcps = agent$env$mcps
    )

    if (!length(tool_response)) {
      return(response)
    }

    if (!loop) {
      return(tool_response)
    }

    increment_tool_calls(agent)

    return(request(agent, new_message(tool_response, role = "user")))
  }

  agent
}

#' @method handle_response provider_openai
#' @export
handle_response.provider_openai <- function(
  x,
  agent,
  response,
  loop = TRUE
) {
  # Extract the message from the OpenAI response
  if (length(response$choices) > 0) {
    message_content <- response$choices[[1]]$message$content
    tool_calls <- response$choices[[1]]$message$tool_calls

    # For messages with tool calls
    if (!is.null(tool_calls) && length(tool_calls) > 0) {
      agent <- append_message(
        agent,
        list(
          content = message_content,
          role = "assistant",
          tool_calls = tool_calls
        ) |>
          as_message()
      )
    } else if (!is.null(message_content)) {
      agent <- append_message(
        agent,
        new_message(message_content, role = "assistant")
      )
    }
  }

  # Check if the response contains tool calls
  if (
    length(response$choices) > 0 &&
      response$choices[[1]]$finish_reason == "tool_calls"
  ) {
    # Process tool calls
    tool_responses <- handle_tool_use(
      x,
      response,
      tools = agent$env$tools,
      mcps = agent$env$mcps
    )

    if (length(tool_responses) == 0) {
      return(response)
    }

    # Add each tool response to the provider's messages
    for (tool_response in tool_responses) {
      agent <- append_message(
        agent,
        as_message(tool_response)
      )
    }

    if (!loop) {
      return(tool_responses)
    }

    increment_tool_calls(agent)

    return(request(agent))
  }

  agent
}

#' Handle tool use in a response
#'
#' @param provider An object of class `provider`.
#' @param response A response object from the LLM provider.
#' @param tools A list of available tools.
#' @param mcps A list of available memory context providers.
#'
#' @return A formatted tool response
#' @keywords internal
handle_tool_use <- function(provider, response, tools, mcps) {
  UseMethod("handle_tool_use")
}

#' @export
#' @method handle_tool_use provider_anthropic
handle_tool_use.provider_anthropic <- function(
  provider,
  response,
  tools = NULL,
  mcps = NULL
) {
  results <- lapply(response$content, function(message) {
    if (!length(message$type)) {
      return()
    }

    if (message$type != "tool_use") {
      return()
    }

    tool_call <- message
    tool_name <- tool_call$name

    if (!grepl("__", tool_name)) {
      tool <- Filter(function(tool) tool$name == tool_name, tools)
      if (!length(tool)) {
        warning(sprintf("Tool '%s' not found", tool_name))
        return(
          list(
            type = "tool_result",
            tool_use_id = tool_call$id,
            content = sprintf("Error: Tool '%s' not found", tool_name)
          )
        )
      }

      tool <- tool[[1]]
      handler <- attr(tool, "handler")

      # Call the tool handler
      tryCatch(
        {
          log("TOOL", "Calling tool: %s", tool_name)
          result <- handler(tool_call$input)

          # Return the tool result
          list(
            type = "tool_result",
            tool_use_id = tool_call$id,
            content = yyjsonr::write_json_str(
              result,
              list(auto_unbox = TRUE)
            )
          )
        },
        error = function(e) {
          warning(sprintf("Error calling tool: %s", e$message))
          list(
            type = "tool_result",
            tool_use_id = tool_call$id,
            content = sprintf("Error calling tool: %s", e$message)
          )
        }
      )
    } else {
      # Check if it's a namespaced tool (for backward compatibility)
      parts <- strsplit(tool_name, "__")[[1]]

      if (length(parts) == 2) {
        # Namespaced tool
        mcp_name <- parts[1]
        actual_tool_name <- parts[2]

        # Find the appropriate MCP
        mcp <- find_mcp_by_name(mcps, mcp_name)

        if (is.null(mcp)) {
          warning(sprintf("MCP '%s' not found", mcp_name))
          return(
            list(
              type = "tool_result",
              tool_use_id = tool_call$id,
              content = sprintf("Error: MCP '%s' not found", mcp_name)
            )
          )
        }

        params <- list(
          name = actual_tool_name,
          arguments = tool_call$input
        )

        # Call the tool
        tryCatch(
          {
            log("TOOL", "Calling MCP (%s) tool: %s", mcp_name, actual_tool_name)
            result <- mcpr::tools_call(
              mcp,
              params,
              id = tool_call$id
            )

            # Return the tool result
            list(
              type = "tool_result",
              tool_use_id = tool_call$id,
              content = yyjsonr::write_json_str(
                result$result$content,
                list(auto_unbox = TRUE)
              )
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
        # Tool not found
        list(
          type = "tool_result",
          tool_use_id = tool_call$id,
          content = sprintf("Error: Tool '%s' not found", tool_name)
        )
      }
    }
  })

  Filter(Negate(is.null), results)
}

#' @export
#' @method handle_tool_use provider_openai
handle_tool_use.provider_openai <- function(
  provider,
  response,
  tools = NULL,
  mcps = NULL
) {
  # Extract the tool calls from the OpenAI response
  if (
    length(response$choices) == 0 ||
      is.null(response$choices[[1]]$message$tool_calls)
  ) {
    return(list())
  }

  tool_calls <- response$choices[[1]]$message$tool_calls

  # Process each tool call
  results <- lapply(tool_calls, function(tool_call) {
    tool_id <- tool_call$id
    function_info <- tool_call$`function` # Use backticks for reserved R keyword
    tool_name <- function_info$name
    arguments <- function_info$arguments

    # Parse arguments (OpenAI returns them as JSON string)
    arguments <- tryCatch(
      yyjsonr::read_json_str(arguments),
      error = function(e) arguments
    )

    # Handle namespaced tools (MCP)
    if (grepl("__", tool_name)) {
      parts <- strsplit(tool_name, "__")[[1]]

      # If not a properly formatted namespaced tool, return error
      if (length(parts) != 2) {
        return(list(
          role = "tool",
          tool_call_id = tool_id,
          content = sprintf("Error: Tool '%s' not found", tool_name)
        ))
      }

      # Extract namespace parts
      mcp_name <- parts[1]
      actual_tool_name <- parts[2]

      # Find the appropriate MCP
      mcp <- find_mcp_by_name(mcps, mcp_name)

      # If MCP not found, return error
      if (is.null(mcp)) {
        warning(sprintf("MCP '%s' not found", mcp_name))
        return(
          list(
            role = "tool",
            tool_call_id = tool_id,
            content = sprintf("Error: MCP '%s' not found", mcp_name)
          )
        )
      }

      # Set up parameters for MCP tool call
      params <- list(
        name = actual_tool_name,
        arguments = arguments
      )

      # Call the tool via MCP and return result
      return(tryCatch(
        {
          log("TOOL", "Calling MCP (%s) tool: %s", mcp_name, actual_tool_name)
          result <- mcpr::tools_call(
            mcp,
            params,
            tool_id
          )

          list(
            role = "tool",
            tool_call_id = tool_id,
            content = yyjsonr::write_json_str(
              result$result$content,
              list(auto_unbox = TRUE)
            )
          )
        },
        error = function(e) {
          list(
            role = "tool",
            tool_call_id = tool_id,
            content = sprintf("Error calling tool: %s", e$message)
          )
        }
      ))
    }

    # Direct tool call (not namespaced)
    tool <- Filter(
      function(t) {
        if (is.list(t) && "function" %in% names(t)) {
          return(t$`function`$name == tool_name) # Use backticks for reserved R keyword
        }
        return(FALSE)
      },
      tools
    )

    # If tool not found, return error
    if (!length(tool)) {
      warning(sprintf("Tool '%s' not found", tool_name))
      return(
        list(
          role = "tool",
          tool_call_id = tool_id,
          content = sprintf("Error: Tool '%s' not found", tool_name)
        )
      )
    }

    # Extract tool and handler
    tool <- tool[[1]]$`function` # Use backticks for reserved R keyword
    handler <- attr(tool, "handler")

    # Call the tool handler and return result
    tryCatch(
      {
        log("TOOL", "Calling tool: %s", tool_name)
        result <- handler(arguments)

        list(
          role = "tool",
          tool_call_id = tool_id,
          content = result
        )
      },
      error = function(e) {
        warning(sprintf("Error calling tool: %s", e$message))
        list(
          role = "tool",
          tool_call_id = tool_id,
          content = sprintf("Error calling tool: %s", e$message)
        )
      }
    )
  })

  # Return list of tool results
  Filter(Negate(is.null), results)
}

#' Find an MCP by name
#'
#' @param mcps An environment containing MCPs
#' @param name The name of the MCP to find.
#'
#' @keywords internal
#' @return An MCP object or NULL if not found
find_mcp_by_name <- function(mcps, name) {
  if (!length(mcps)) {
    return(NULL)
  }

  for (mcp in mcps) {
    if (mcpr::get_name(mcp) == name) {
      return(mcp)
    }
  }
  NULL
}
