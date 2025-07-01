#' Tool integration for ellmer providers
#'
#' These functions handle tool registration and management for ellmer-based providers.

#' Add tool to ellmer provider
#'
#' @param x An agent with ellmer provider
#' @param tool A tool object (mcpr tool or ellmer ToolDef)
#' @param ... Additional arguments
#'
#' @return The modified agent
#' @keywords internal
add_tool_ellmer <- function(x, tool, ...) {
  if (!inherits(x$provider, "Chat")) {
    stop("This method is only for ellmer Chat objects")
  }
  
  # Register tool directly with ellmer chat
  if (inherits(tool, "ToolDef")) {
    # Already an ellmer ToolDef
    x$provider$register_tool(tool)
  } else if (inherits(tool, "tool")) {
    # Convert mcpr tool to ellmer ToolDef
    ellmer_tool <- mcpr_to_ellmer_tool(tool)
    x$provider$register_tool(ellmer_tool)
  } else {
    stop("tool must be an ellmer ToolDef or mcpr tool object")
  }
  
  invisible(x)
}

#' Convert mcpr tool to ellmer ToolDef
#'
#' @param mcpr_tool A tool object from mcpr package
#'
#' @return An ellmer ToolDef object
#' @keywords internal
mcpr_to_ellmer_tool <- function(mcpr_tool) {
  # Extract tool metadata
  name <- mcpr_tool$name
  description <- mcpr_tool$description
  handler <- attr(mcpr_tool, "handler")
  
  # Convert input schema to ellmer types
  schema <- mcpr_tool$inputSchema
  
  # Build ellmer type specification from JSON schema
  ellmer_args <- convert_schema_to_ellmer_types(schema)
  
  # Create a wrapper function that converts ellmer's calling convention
  # to mcpr's expected format (single params list)
  ellmer_wrapper <- function(...) {
    params <- list(...)
    handler(params)
  }
  
  # Create ellmer tool
  do.call(ellmer::tool, c(
    list(
      .fun = ellmer_wrapper,
      .name = name,
      .description = description
    ),
    ellmer_args
  ))
}

#' Convert JSON schema to ellmer type specifications
#'
#' @param schema JSON schema object
#'
#' @return List of ellmer type specifications
#' @keywords internal
convert_schema_to_ellmer_types <- function(schema) {
  if (is.null(schema$properties)) {
    return(list())
  }
  
  args <- list()
  
  for (prop_name in names(schema$properties)) {
    prop <- schema$properties[[prop_name]]
    
    # Convert based on type
    ellmer_type <- switch(prop$type,
      "string" = ellmer::type_string(prop$description),
      "integer" = ellmer::type_integer(prop$description),
      "number" = ellmer::type_number(prop$description),
      "boolean" = ellmer::type_boolean(prop$description),
      "array" = convert_array_type(prop),
      "object" = convert_object_type(prop),
      ellmer::type_string(prop$description) # fallback
    )
    
    # Handle required fields
    if (!is.null(schema$required) && prop_name %in% schema$required) {
      # ellmer types are required by default
    }
    
    args[[prop_name]] <- ellmer_type
  }
  
  args
}

#' Convert array type to ellmer specification
#'
#' @param prop Property definition
#'
#' @return ellmer type specification
#' @keywords internal
convert_array_type <- function(prop) {
  if (is.null(prop$items)) {
    return(ellmer::type_array(ellmer::type_string()))
  }
  
  item_type <- switch(prop$items$type,
    "string" = ellmer::type_string(),
    "integer" = ellmer::type_integer(),
    "number" = ellmer::type_number(),
    "boolean" = ellmer::type_boolean(),
    ellmer::type_string() # fallback
  )
  
  ellmer::type_array(item_type, description = prop$description)
}

#' Convert object type to ellmer specification
#'
#' @param prop Property definition
#'
#' @return ellmer type specification
#' @keywords internal
convert_object_type <- function(prop) {
  if (is.null(prop$properties)) {
    return(ellmer::type_object())
  }
  
  # Recursively convert nested properties
  nested_args <- convert_schema_to_ellmer_types(prop)
  
  do.call(ellmer::type_object, nested_args)
}

#' Register MCP with ellmer provider
#'
#' @param x An agent with ellmer provider
#' @param mcp An MCP client object
#'
#' @return The modified agent
#' @keywords internal
register_mcp_ellmer <- function(x, mcp) {
  if (!inherits(x$provider, "Chat")) {
    stop("This method is only for ellmer Chat objects")
  }
  
  # Get tools from MCP
  tools <- tryCatch(
    mcpr::tools_list(mcp),
    error = function(e) {
      stop(sprintf("Could not retrieve tools from MCP: %s", e$message))
    }
  )
  
  # Convert each MCP tool to ellmer ToolDef and register
  for (tool in tools$result$tools) {
    # Create a closure that captures the tool name correctly
    tool_handler <- local({
      tool_name <- tool$name
      function(params) {
        result <- mcpr::tools_call(mcp, list(
          name = tool_name,
          arguments = params
        ))
        result$result$content
      }
    })
    
    # Create ellmer tool with MCP handler
    ellmer_tool <- mcpr_to_ellmer_tool(structure(
      tool,
      handler = tool_handler,
      class = "tool"
    ))
    
    x$provider$register_tool(ellmer_tool)
  }
  
  # Store MCP reference
  x$env$mcps <- c(x$env$mcps, list(mcp))
  
  invisible(x)
}