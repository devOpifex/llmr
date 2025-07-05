devtools::load_all()

# Example 1: Basic Interactive Approval
# =====================================

# Create an agent with ellmer provider
agent <- new_agent("assistant", ellmer::chat_anthropic)

# Add a simple tool
add_tool(
  agent,
  mcpr::new_tool(
    name = "get_weather",
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
      sprintf("The weather in %s is sunny and 72F", params$location)
    }
  )
)

# Set up interactive human approval
agent <- set_approval_callback(agent, prompt_human_approval)

request(agent, new_message("What's the weather in Paris?"))

# Now when you make a request that triggers tool use, you'll be prompted:
# request(agent, new_message("What's the weather in Paris?"))

# Example 2: Custom Approval Logic
# =================================

# Create a custom approval function
custom_approval <- function(tool_info) {
  # Auto-approve safe tools
  safe_tools <- c("get_weather", "search_docs", "calculate")

  if (tool_info$name %in% safe_tools) {
    cat("[+] Auto-approving safe tool:", tool_info$name, "\n")
    return(TRUE)
  }

  # Require approval for potentially dangerous tools
  dangerous_tools <- c("delete_file", "send_email", "make_payment")

  if (tool_info$name %in% dangerous_tools) {
    cat("[!] DANGEROUS TOOL:", tool_info$name, "\n")
    cat("This tool can make irreversible changes!\n")
    response <- readline("Are you SURE you want to proceed? (yes/no): ")
    return(tolower(trimws(response)) == "yes")
  }

  # For unknown tools, use the default prompt
  prompt_human_approval(tool_info)
}

# Apply custom approval logic
agent2 <- new_agent("careful_assistant", ellmer::chat_anthropic) |>
  set_approval_callback(custom_approval)


# Example 3: Smart Approval with Memory
# ======================================

# Use the smart approval callback that remembers preferences
agent3 <- new_agent("smart_assistant", ellmer::chat_anthropic) |>
  set_approval_callback(smart_approval_callback)

# The smart callback will:
# 1. Remember your approval/denial decisions
# 2. Auto-approve/block tools based on past decisions
# 3. Only prompt for new tools

# You can manage the stored preferences:
# list_tool_approvals()    # See current preferences
# clear_tool_approvals()   # Clear all preferences

# Example 4: Batch Approval Interface
# ====================================

# Use the batch approval interface for more options
agent4 <- new_agent("batch_assistant", ellmer::chat_anthropic) |>
  set_approval_callback(batch_approval_interface)

# The batch interface provides options to:
# - Approve/deny individual calls
# - Always approve a specific tool type
# - Block a specific tool type
# - View detailed information

# Example 5: Workflow Integration
# ================================

# Human approval also works with workflows
approval_step <- function(data) {
  cat("Workflow step received data:", data, "\n")
  data * 2
}

# Create a workflow with an agent that requires approval
workflow <- step(function(x) x + 10) %->%
  step(agent) %->%
  step(approval_step)

# When executed, the agent step will prompt for tool approval if needed
# result <- execute(workflow, 5)

# Example 6: Disabling Approval
# ==============================

# To remove approval callback (allow all tools):
agent_no_approval <- set_approval_callback(agent, NULL)

# Or create an agent without approval from the start:
agent_auto_approve <- new_agent("auto_agent", ellmer::chat_anthropic)
# (no set_approval_callback call means no approval required)

# Tips for Using Human-in-the-Loop
# =================================

# 1. Start with prompt_human_approval() for simple cases
# 2. Use smart_approval_callback() to reduce repetitive prompts
# 3. Create custom approval functions for specific security requirements
# 4. Use batch_approval_interface() for power users who want more control
# 5. Remember that approval only works with ellmer Chat providers
# 6. Tool approval happens before tool execution, so you can prevent unwanted actions
