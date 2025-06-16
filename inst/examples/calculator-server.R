#!/usr/bin/env Rscript

# Example MCP Calculator Server
# This file demonstrates how to create a standalone MCP server
# that can be used with the llmr package.
#
# Usage:
# Rscript calculator-server.R

library(mcpr)

# Create the calculator tool (same as inline version)
calculator <- new_tool(
  name = "calculator",
  description = "Performs basic arithmetic operations",
  input_schema = schema(
    properties = properties(
      operation = property_enum(
        "Operation",
        "Math operation to perform",
        values = c("add", "subtract", "multiply", "divide"),
        required = TRUE
      ),
      a = property_number("First number", "First operand", required = TRUE),
      b = property_number("Second number", "Second operand", required = TRUE)
    )
  ),
  handler = function(params) {
    result <- switch(
      params$operation,
      "add" = params$a + params$b,
      "subtract" = params$a - params$b,
      "multiply" = params$a * params$b,
      "divide" = params$a / params$b
    )
    response_text(result)
  }
)

# Create an MCP server
mcp_server <- new_server(
  name = "Calculator Server",
  description = "A production-ready calculator service",
  version = "1.0.0"
)

# Add the calculator tool to the server
mcp_server <- add_capability(mcp_server, calculator)

# Start the server (listening on stdin/stdout)
serve_io(mcp_server)