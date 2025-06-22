devtools::load_all()

# Test direct ellmer usage
cat("Testing direct ellmer integration...\n")

# Test 1: Basic agent creation with ellmer chat object
cat("\n1. Testing basic agent creation:\n")
agent <- new_agent("test", ellmer::chat_anthropic())
cat("✓ Agent created successfully with ellmer chat object\n")
cat("Provider class:", class(agent$provider), "\n")

# Test 2: Tool addition
cat("\n2. Testing tool addition:\n")
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

add_tool(agent, weather_tool)
cat("✓ Tool added successfully\n")
cat("Registered tools:", names(agent$provider$chat$get_tools()), "\n")

# Test 3: Request handling
cat("\n3. Testing request handling:\n")
request(agent, new_message("What's the weather in Tokyo?"))
last_msg <- get_last_message(agent)
cat("✓ Request processed successfully\n")
cat("Response:", last_msg$content, "\n")

# Test 4: Multiple providers
cat("\n4. Testing multiple ellmer providers:\n")

# OpenAI
if (Sys.getenv("OPENAI_API_KEY") != "") {
  openai_agent <- new_agent("openai", ellmer::chat_openai(model = "gpt-3.5-turbo"))
  cat("✓ OpenAI agent created\n")
} else {
  cat("⚠ OpenAI API key not set, skipping OpenAI test\n")
}

# Gemini
if (Sys.getenv("GOOGLE_API_KEY") != "") {
  gemini_agent <- new_agent("gemini", ellmer::chat_google_gemini())
  cat("✓ Gemini agent created\n")
} else {
  cat("⚠ Google API key not set, skipping Gemini test\n")
}

# Test 5: Configuration during creation
cat("\n5. Testing configuration during creation:\n")
configured_agent <- new_agent("configured", ellmer::chat_anthropic(
  model = "claude-3-haiku-20240307",
  params = ellmer::params(
    temperature = 0.5,
    max_tokens = 500
  ),
  system_prompt = "You are a helpful assistant."
))
cat("✓ Configured agent created successfully\n")

# Test 6: Access to ellmer features
cat("\n6. Testing access to ellmer features:\n")
ellmer_chat <- configured_agent$provider$chat
cat("✓ Can access underlying ellmer chat object\n")
cat("Model:", ellmer_chat$get_model(), "\n")
cat("System prompt:", ellmer_chat$get_system_prompt(), "\n")

cat("\n✅ All tests passed! Direct ellmer integration working correctly.\n")