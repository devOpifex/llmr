devtools::load_all()

# Debug tool conversion
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
    cat("Handler called with params:", str(params), "\n")
    paste("Weather in", params$location, "is sunny")
  }
)

cat("Original mcpr tool structure:\n")
str(weather_tool)

cat("\nHandler attribute:\n")
str(attr(weather_tool, "handler"))

# Test the handler directly
cat("\nTesting handler directly:\n")
handler <- attr(weather_tool, "handler")
result <- handler(list(location = "Paris"))
cat("Direct handler result:", result, "\n")

# Convert to ellmer tool
cat("\nConverting to ellmer tool...\n")
ellmer_tool <- mcpr_to_ellmer_tool(weather_tool)

cat("\nEllmer tool structure:\n")
str(ellmer_tool)

# Test ellmer tool directly
cat("\nTesting ellmer tool function directly:\n")
tryCatch({
  result <- ellmer_tool@fun(location = "Paris")
  cat("Ellmer tool result:", result, "\n")
}, error = function(e) {
  cat("Error calling ellmer tool:", e$message, "\n")
})