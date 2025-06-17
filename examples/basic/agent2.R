devtools::load_all()

provider <- new_anthropic()

agent <- new_agent("Weather forecaster and calculator", provider)

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


#request(agent, new_message("What's the weather like in New York?"))
request(agent, new_message("What's the weather like in New York?"))
get_last_message(agent)
