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

  # Add system prompt if available
  if (!is.null(attr(provider, "system"))) {
    body$system <- attr(provider, "system")
  }

  # Add temperature if available
  if (!is.null(attr(provider, "temperature"))) {
    body$temperature <- attr(provider, "temperature")
  }

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

  # Apply retry configuration if available
  if (length(provider$env$retry)) {
    req <- req |> httr2::req_retry(max_tries = provider$env$retry$max_tries)
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

  response <- httr2::resp_body_json(response)

  provider <- append_message(
    provider,
    new_message(response$content, role = "assistant")
  )

  # Handle the response (for tool_use etc.)
  handle_response(provider, response)
}

#' @method request provider_openai
#' @export
request.provider_openai <- function(provider, message) {
  provider <- append_message(provider, message)

  body <- list(
    model = attr(provider, "model"),
    max_tokens = attr(provider, "max_tokens"),
    messages = provider$env$messages
  )

  # Add temperature if available
  if (!is.null(attr(provider, "temperature"))) {
    body$temperature <- attr(provider, "temperature")
  }

  # Add tools if available
  if (length(provider$env$tools)) {
    body$tools <- provider$env$tools
  }

  req <- httr2::request(provider$url) |>
    httr2::req_url_path(path = "v1/chat/completions") |>
    httr2::req_headers(
      "Content-Type" = "application/json",
      "Authorization" = sprintf("Bearer %s", attr(provider, "key"))
    ) |>
    httr2::req_body_json(body) |>
    httr2::req_method("POST")

  # Apply retry configuration if available
  if (length(provider$env$retry)) {
    req <- req |> httr2::req_retry(max_tries = provider$env$retry$max_tries)
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

  response <- httr2::resp_body_json(response)
  
  # Extract the assistant's message from OpenAI response
  assistant_message <- response$choices[[1]]$message
  
  # Add the assistant message to the conversation history
  if (!is.null(assistant_message$tool_calls) && length(assistant_message$tool_calls) > 0) {
    # For messages with tool calls
    provider <- append_message(
      provider,
      new_message(
        content = assistant_message$content, 
        role = "assistant",
        tool_calls = assistant_message$tool_calls
      )
    )
  } else if (!is.null(assistant_message$content)) {
    # For regular text responses
    provider <- append_message(
      provider,
      new_message(assistant_message$content, role = "assistant")
    )
  }

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

#' @method handle_response provider_openai
#' @export
handle_response.provider_openai <- function(
  provider,
  response,
  loop = TRUE
) {
  # Check if the response contains tool calls
  if (length(response$choices) > 0 && 
      response$choices[[1]]$finish_reason == "tool_calls") {
    
    # Process tool calls
    tool_responses <- handle_tool_use(provider, response)
    
    if (length(tool_responses) == 0) return(response)
    
    # Add each tool response to the provider's messages
    for (tool_response in tool_responses) {
      provider <- append_message(
        provider,
        new_message(
          content = tool_response$content, 
          role = "tool",
          tool_call_id = tool_response$tool_call_id
        )
      )
    }
    
    if (!loop) {
      return(tool_responses)
    }
    
    # Continue the conversation with the LLM by sending an empty message
    # with all current messages (including tool responses)
    return(request(provider, new_message("", role = "user")))
  }
  
  response
}

#' Handle tool use in a response
#'
#' @param provider An object of class `provider`.
#' @param response A response object from the LLM provider.
#'
#' @return A formatted tool response
handle_tool_use <- function(provider, response) UseMethod("handle_tool_use")

#' @export
#' @method handle_tool_use provider_anthropic
handle_tool_use.provider_anthropic <- function(provider, response) {
  results <- lapply(response$content, function(message) {
    if (!length(message$type)) return()

    if (message$type != "tool_use") return()

    tool_call <- message
    tool_name <- tool_call$name

    if (!grepl("__", tool_name)) {
      tool <- Filter(function(tool) tool$name == tool_name, provider$env$tools)
      if (!length(tool)) {
        warning(sprintf("Tool '%s' not found", tool_name))
        return(list(
          type = "tool_result",
          tool_use_id = tool_call$id,
          content = sprintf("Error: Tool '%s' not found", tool_name)
        ))
      }

      tool <- tool[[1]]
      handler <- attr(tool, "handler")

      # Call the tool handler
      tryCatch(
        {
          result <- handler(tool_call$input)

          # Return the tool result
          list(
            type = "tool_result",
            tool_use_id = tool_call$id,
            content = result
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
handle_tool_use.provider_openai <- function(provider, response) {
  # Extract the tool calls from the OpenAI response
  tool_calls <- response$choices[[1]]$message$tool_calls
  
  # Process each tool call
  results <- lapply(tool_calls, function(tool_call) {
    tool_id <- tool_call$id
    function_info <- tool_call$`function`  # Use backticks for reserved R keyword
    tool_name <- function_info$name
    arguments <- function_info$arguments
    
    # Parse arguments (OpenAI returns them as JSON string)
    arguments <- tryCatch(
      yyjsonr::read_json_str(arguments),
      error = function(e) arguments
    )
    
    if (!grepl("__", tool_name)) {
      # Direct tool call
      tool <- Filter(function(t) {
        if (is.list(t) && "function" %in% names(t)) {
          return(t$`function`$name == tool_name)  # Use backticks for reserved R keyword
        }
        return(FALSE)
      }, provider$env$tools)
      
      if (!length(tool)) {
        warning(sprintf("Tool '%s' not found", tool_name))
        return(list(
          role = "tool",
          tool_call_id = tool_id,
          content = sprintf("Error: Tool '%s' not found", tool_name)
        ))
      }
      
      tool <- tool[[1]]$`function`  # Use backticks for reserved R keyword
      handler <- attr(tool, "handler")
      
      # Call the tool handler
      tryCatch({
          result <- handler(arguments)
          
          # Return the tool result
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
    } else {
      # Namespaced tool (MCP)
      parts <- strsplit(tool_name, "__")[[1]]
      
      if (length(parts) == 2) {
        mcp_name <- parts[1]
        actual_tool_name <- parts[2]
        
        # Find the appropriate MCP
        mcp <- find_mcp_by_name(provider, mcp_name)
        
        if (is.null(mcp)) {
          warning(sprintf("MCP '%s' not found", mcp_name))
          return(list(
            role = "tool",
            tool_call_id = tool_id,
            content = sprintf("Error: MCP '%s' not found", mcp_name)
          ))
        }
        
        params <- list(
          name = actual_tool_name,
          arguments = arguments
        )
        
        # Call the tool via MCP
        tryCatch({
            result <- mcpr::tools_call(
              mcp,
              params,
              tool_id
            )
            
            # Return the tool result
            list(
              role = "tool",
              tool_call_id = tool_id,
              content = result$content
            )
          },
          error = function(e) {
            list(
              role = "tool",
              tool_call_id = tool_id,
              content = sprintf("Error calling tool: %s", e$message)
            )
          }
        )
      } else {
        # Invalid tool name format
        list(
          role = "tool",
          tool_call_id = tool_id,
          content = sprintf("Error: Tool '%s' not found", tool_name)
        )
      }
    }
  })
  
  # Return list of tool results
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