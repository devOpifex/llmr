devtools::load_all()

provider <- new_openai()

client <- mcpr::new_client_io(
  command = "Rscript",
  args = "/home/john/Opifex/Packages/llmr/examples/mcp/server.R",
  name = "calculator"
)

register_mcp(provider, client)

agent <- new_agent("Weather forecaster")

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

provider <- register_agent(provider, agent)

set_retry(provider, max_tries = 5)

request(provider, new_message("What's the weather like in New York?"))
