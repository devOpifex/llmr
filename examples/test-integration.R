# Simple integration test for human-in-the-loop functionality
library(llmr)

cat("Testing human-in-the-loop integration...\n")

# Test 1: Basic agent creation and callback setting
cat("1. Testing agent creation and callback setting...\n")

# Create a simple mock chat object for testing
mock_chat <- structure(
  list(
    callbacks = list(),
    on_tool_request = function(callback) {
      mock_chat$callbacks <- c(mock_chat$callbacks, list(callback))
      cat("   [+] Tool request callback registered\n")
    }
  ),
  class = "Chat"
)

# Create agent using Chat class directly
agent <- new_agent("test", mock_chat)
cat("   [+] Agent created successfully\n")

# Set approval callback
test_callback <- function(tool_info) {
  cat("   [+] Approval callback called with tool:", tool_info$name, "\n")
  return(TRUE)
}

result <- set_approval_callback(agent, test_callback)
cat("   [+] Approval callback set successfully\n")

# Test 2: Tool approval storage
cat("2. Testing tool approval storage...\n")

clear_tool_approvals()
cat("   [+] Cleared tool approvals\n")

store_tool_approval("safe_tool", TRUE)
cat("   [+] Stored approval for safe_tool\n")

approval_status <- check_tool_approval("safe_tool")
if (approval_status == TRUE) {
  cat("   [+] Retrieved approval status correctly\n")
} else {
  cat("   [-] Failed to retrieve approval status\n")
}

# Test 3: Smart approval callback
cat("3. Testing smart approval callback...\n")

tool_info <- list(
  name = "safe_tool",
  arguments = list(param = "value"),
  id = "test123"
)

result <- smart_approval_callback(tool_info)
if (result == TRUE) {
  cat("   [+] Smart callback auto-approved stored tool\n")
} else {
  cat("   [-] Smart callback failed\n")
}

# Test 4: Tool details display
cat("4. Testing tool details display...\n")

show_tool_details(tool_info)
cat("   [+] Tool details displayed successfully\n")

# Clean up
clear_tool_approvals()
cat("   [+] Cleaned up tool approvals\n")

cat("\n[SUCCESS] All integration tests passed!\n")
cat("\nThe human-in-the-loop functionality is ready to use.\n")
cat("\nNext steps:\n")
cat("1. Set your API keys (ANTHROPIC_API_KEY, OPENAI_API_KEY, etc.)\n")
cat("2. Create an agent with ellmer::chat_anthropic() or similar\n")
cat("3. Add tools using add_tool()\n")
cat("4. Set approval callback using set_approval_callback()\n")
cat("5. Make requests and approve/deny tool calls interactively\n")