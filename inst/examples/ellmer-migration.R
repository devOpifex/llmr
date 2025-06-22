# ellmer Migration Examples
# 
# This file demonstrates how to migrate from legacy llmr providers
# to the new ellmer-based providers.

library(llmr)

# =============================================================================
# Basic Provider Migration
# =============================================================================

# OLD WAY (deprecated)
if (FALSE) {
  old_provider <- new_anthropic() |>
    set_model("claude-3-sonnet-20240229") |>
    set_temperature(0.7)
  
  old_agent <- new_agent("assistant", old_provider)
}

# NEW WAY (recommended) - direct ellmer usage
new_agent <- new_agent("assistant", ellmer::chat_anthropic(
  model = "claude-3-sonnet-20240229",
  params = ellmer::params(temperature = 0.7)
))

# =============================================================================
# Tool Migration Examples
# =============================================================================

# Create a simple tool using mcpr (works with both provider types)
weather_tool <- mcpr::new_tool(
  name = "get_weather",
  description = "Get current weather for a location",
  input_schema = mcpr::schema(
    properties = mcpr::properties(
      location = mcpr::property_string(
        title = "Location",
        description = "City name or coordinates",
        required = TRUE
      ),
      units = mcpr::property_string(
        title = "Units",
        description = "Temperature units (celsius or fahrenheit)",
        required = FALSE
      )
    )
  ),
  handler = function(params) {
    location <- params$location
    units <- params$units %||% "celsius"
    
    # Simulate weather API call
    temp <- if (units == "celsius") "22°C" else "72°F"
    paste("Current weather in", location, "is sunny,", temp)
  }
)

# Add tool to agent (same interface for both provider types)
add_tool(new_agent, weather_tool)

# Create an ellmer-native tool (only works with ellmer providers)
calculator_tool <- ellmer::tool(
  function(expression) {
    result <- eval(parse(text = expression))
    paste("Result:", result)
  },
  "Perform mathematical calculations",
  expression = ellmer::type_string(
    "Mathematical expression to evaluate (e.g., '2 + 2', 'sqrt(16)')"
  )
)

add_tool(new_agent, calculator_tool)

# =============================================================================
# Usage Examples
# =============================================================================

# Basic conversation
request(new_agent, new_message("What's the weather like in Paris?"))
get_last_message(new_agent)

# Tool usage
request(new_agent, new_message("Calculate the square root of 144"))
get_last_message(new_agent)

# =============================================================================
# Advanced ellmer Features
# =============================================================================

# Access the underlying ellmer chat for advanced features
ellmer_chat <- new_provider$chat

# Streaming (ellmer only)
if (interactive()) {
  ellmer_chat$chat("Tell me a short story about a robot", echo = "output")
}

# Structured data extraction (ellmer only)
person_data <- ellmer_chat$chat_structured(
  "Extract information: Sarah Johnson, 28 years old, software engineer in Seattle",
  type = ellmer::type_object(
    name = ellmer::type_string("Full name"),
    age = ellmer::type_integer("Age in years"),
    profession = ellmer::type_string("Job title"),
    city = ellmer::type_string("City of residence")
  )
)

print(person_data)

# =============================================================================
# Multiple Provider Examples
# =============================================================================

# OpenAI with ellmer - direct usage
openai_agent <- new_agent("openai_assistant", ellmer::chat_openai(
  model = "gpt-4",
  params = ellmer::params(temperature = 0.5, max_tokens = 1000)
))
add_tool(openai_agent, weather_tool)

# Google Gemini (new provider available through ellmer)
if (Sys.getenv("GOOGLE_API_KEY") != "") {
  gemini_agent <- new_agent("gemini_assistant", ellmer::chat_google_gemini(model = "gemini-pro"))
  add_tool(gemini_agent, calculator_tool)
}

# =============================================================================
# MCP Integration (works with both provider types)
# =============================================================================

if (FALSE) {
  # Example MCP integration
  mcp_client <- mcpr::new_client(
    command = "Rscript",
    args = "path/to/mcp_server.R",
    name = "file_operations"
  )
  
  # Register MCP with agent
  register_mcp(new_agent, mcp_client)
  
  # Now the agent can use tools from the MCP server
  request(new_agent, new_message("List files in the current directory"))
}

# =============================================================================
# Configuration Compatibility
# =============================================================================

# Configure ellmer chat objects directly (recommended)
configured_agent <- new_agent("coder", ellmer::chat_anthropic(
  model = "claude-3-haiku-20240307",
  params = ellmer::params(
    temperature = 0.8,
    max_tokens = 2000
  ),
  system_prompt = "You are a helpful coding assistant."
))

# Test the configured agent
request(configured_agent, new_message("Write a simple Python function to calculate factorial"))
get_last_message(configured_agent)