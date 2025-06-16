## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## ----inline-tool, eval=FALSE--------------------------------------------------
# # Development approach - tool embedded in agent
# calculator <- new_tool(
#   name = "calculator",
#   description = "Performs basic arithmetic operations",
#   # ... tool definition
# )
# agent <- add_tool(agent, calculator)

## ----mcp-approach, eval=FALSE-------------------------------------------------
# # Production approach - tool as external MCP server
# client <- new_client_io(command = "Rscript", args = "calculator-server.R")
# agent <- register_mcp(agent, client)

## ----server-code, eval=FALSE--------------------------------------------------
# library(mcpr)
# 
# # Create the same calculator tool from the Get Started guide
# calculator <- new_tool(
#   name = "calculator",
#   description = "Performs basic arithmetic operations",
#   input_schema = schema(
#     properties = properties(
#       operation = property_enum(
#         "Operation",
#         "Math operation to perform",
#         values = c("add", "subtract", "multiply", "divide"),
#         required = TRUE
#       ),
#       a = property_number("First number", "First operand", required = TRUE),
#       b = property_number("Second number", "Second operand", required = TRUE)
#     )
#   ),
#   handler = function(params) {
#     result <- switch(
#       params$operation,
#       "add" = params$a + params$b,
#       "subtract" = params$a - params$b,
#       "multiply" = params$a * params$b,
#       "divide" = params$a / params$b
#     )
#     response_text(result)
#   }
# )
# 
# # Create an MCP server and add the calculator tool
# mcp_server <- new_server(
#   name = "Calculator Server",
#   description = "A production-ready calculator service",
#   version = "1.0.0"
# )
# 
# # Add the tool to the server
# mcp_server <- add_capability(mcp_server, calculator)
# 
# # Start the server (listening on stdin/stdout)
# serve_io(mcp_server)

## ----client-setup-------------------------------------------------------------
# library(llmr)
# library(mcpr)
# 
# # Set up your provider (same as before)
# provider <- new_anthropic()
# 
# # Create an agent
# agent <- new_agent("calculator", provider)

## ----mcp-connection-----------------------------------------------------------
# # Get the path to the example calculator server included with llmr
# server_path <- system.file("examples", "calculator-server.R", package = "llmr")
# 
# # Create an MCP client that connects to our calculator server
# calculator_client <- new_client_io(
#   command = "Rscript",
#   args = server_path,
#   name = "calculator"
# )
# 
# # Register the MCP client with our agent
# agent <- register_mcp(agent, calculator_client)

## ----usage-examples-----------------------------------------------------------
# # Same usage as the inline tool version
# response <- request(agent, "What is 25 multiplied by 4?")
# print(response)
# 
# # Complex calculations work the same way
# response <- request(agent, "I have 150 dollars, spend 47.50 on dinner and 23.75 on a book. How much is left?")
# print(response)

## ----scalability-example, eval=FALSE------------------------------------------
# # Multiple agents can share the same calculator service
# agent1 <- new_agent("financial_advisor", provider)
# agent2 <- new_agent("math_tutor", provider)
# agent3 <- new_agent("data_analyst", provider)
# 
# # All connect to the same MCP server
# register_mcp(agent1, calculator_client)
# register_mcp(agent2, calculator_client)
# register_mcp(agent3, calculator_client)

## ----multiple-services, eval=FALSE--------------------------------------------
# # Connect to different specialized services
# calculator_client <- new_client_io(command = "Rscript", args = "calculator-server.R")
# weather_client <- new_client_io(command = "Rscript", args = "weather-server.R")
# database_client <- new_client_io(command = "Rscript", args = "database-server.R")
# 
# # Register all services with the agent
# agent <- register_mcp(agent, calculator_client)
# agent <- register_mcp(agent, weather_client)
# agent <- register_mcp(agent, database_client)

## ----hybrid-approach, eval=FALSE----------------------------------------------
# # Quick inline tool for simple tasks
# simple_tool <- new_tool(name = "timestamp", ...)
# agent <- add_tool(agent, simple_tool)
# 
# # External MCP service for complex operations
# complex_client <- new_client_io(...)
# agent <- register_mcp(agent, complex_client)

## ----phase1, eval=FALSE-------------------------------------------------------
# # Start with inline tools
# agent <- add_tool(agent, my_tool)

## ----phase2, eval=FALSE-------------------------------------------------------
# # Test MCP version alongside inline version
# agent <- add_tool(agent, my_tool)  # Keep original
# agent <- register_mcp(agent, mcp_client)  # Add MCP version

## ----phase3, eval=FALSE-------------------------------------------------------
# # Remove inline tool, use only MCP
# agent <- register_mcp(agent, mcp_client)

