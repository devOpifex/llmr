devtools::load_all()

# Test with ellmer provider - direct usage
client <- mcpr::new_client_io(
  command = "Rscript",
  args = "/home/john/Opifex/Packages/llmr/examples/mcp/server.R",
  name = "calculator"
)

# Create agent with ellmer chat object directly
agent <- new_agent("Weather forecaster and calculator", ellmer::chat_anthropic())
set_retry(agent, max_tries = 5)

# Register MCP with ellmer provider
register_mcp(agent, client)

# Add a regular tool
add_tool(
  agent,
  mcpr::new_tool(
    name = "weather",
    description = "Get the weather forecast for a given location",
    input_schema = mcpr::schema(
      properties = mcpr::properties(
        location = mcpr::property_string(
          title = "Location",
          description = "The location for which you want the weather forecast",
          required = TRUE
        )
      )
    ),
    handler = function(params) {
      sprintf("The weather forecast for %s is dark and rainy", params$location)
    }
  )
)

# Test calculation
cat("Testing calculation with ellmer provider:\n")
request(agent, new_message("Subtract 5 from 10"))
cat("\nMessages:\n")
print(get_messages(agent))

# Test weather tool
cat("\n\nTesting weather tool:\n")
request(agent, new_message("What's the weather like in Paris?"))
cat("\nLast message:\n")
print(get_last_message(agent))