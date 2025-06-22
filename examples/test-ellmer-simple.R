devtools::load_all()

# Test simple ellmer provider without MCP first
cat("Testing simple ellmer provider...\n")

# Create agent with ellmer chat object directly
agent <- new_agent("simple_test", ellmer::chat_anthropic())

# Add a simple tool directly using ellmer
simple_tool <- ellmer::tool(
  function(x, y) x + y,
  "Add two numbers",
  x = ellmer::type_number("First number"),
  y = ellmer::type_number("Second number")
)

# Register tool with ellmer chat directly
agent$provider$chat$register_tool(simple_tool)

# Test the tool
cat("Registered tools:\n")
print(names(agent$provider$chat$get_tools()))

# Make a request
cat("\nTesting tool call:\n")
request(agent, new_message("Add 5 and 3"))
cat("\nLast message:\n")
print(get_last_message(agent))

# Test weather tool using mcpr format
cat("\n\nTesting mcpr tool with ellmer...\n")
weather_tool <- mcpr::new_tool(
  name = "weather",
  description = "Get weather forecast",
  input_schema = mcpr::schema(
    properties = mcpr::properties(
      location = mcpr::property_string(
        title = "Location",
        description = "Location for weather",
        required = TRUE
      )
    )
  ),
  handler = function(params) {
    paste("Weather in", params$location, "is sunny")
  }
)

# Add using our integration
add_tool(agent, weather_tool)

cat("Tools after adding weather tool:\n")
print(names(agent$provider$chat$get_tools()))

# Test weather tool
request(agent, new_message("What's the weather in London?"))
cat("\nLast message after weather request:\n")
print(get_last_message(agent))