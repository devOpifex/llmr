## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## ----setup--------------------------------------------------------------------
# library(llmr)
# library(mcpr)

## ----provider-setup-----------------------------------------------------------
# # Create a provider instance
# provider <- new_anthropic()

## ----create-agent-------------------------------------------------------------
# # Create an agent with a descriptive name
# agent <- new_agent("calculator", provider)

## ----create-calculator--------------------------------------------------------
# # Create a calculator tool
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

## ----add-tool-----------------------------------------------------------------
# # Add the calculator tool to the agent
# agent <- add_tool(agent, calculator)

## ----conversation-------------------------------------------------------------
# # Ask the agent to perform a calculation
# response <- request(agent, "What is 15 multiplied by 7?")
# print(response)
# 
# # Ask for a more complex calculation
# response <- request(agent, "I have 100 dollars and spend 23.50 on groceries and 15.75 on gas. How much do I have left?")
# print(response)

