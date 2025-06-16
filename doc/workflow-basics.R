## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## ----setup--------------------------------------------------------------------
# library(llmr)

## ----api-setup, eval=FALSE----------------------------------------------------
# # Only needed for agent examples
# set_api_key("your-anthropic-api-key-here")

## ----function-workflow--------------------------------------------------------
# # Define simple processing functions
# add_ten <- function(x) {
#   cat("Adding 10 to", x, "\n")
#   x + 10
# }
# 
# multiply_by_two <- function(x) {
#   cat("Multiplying", x, "by 2\n")
#   x * 2
# }
# 
# subtract_five <- function(x) {
#   cat("Subtracting 5 from", x, "\n")
#   x - 5
# }
# 
# # Create workflow steps and chain them together inline
# math_workflow <- step(add_ten, name = "add_ten") %->%
#                  step(multiply_by_two, name = "multiply_two") %->%
#                  step(subtract_five, name = "subtract_five")
# 
# # View the workflow structure
# print(math_workflow)
# 
# # Execute the workflow
# input_value <- 5
# result <- execute(math_workflow, input_value)
# print(result)  # Should be 25: ((5 + 10) * 2) - 5 = 25

## ----agent-workflow-----------------------------------------------------------
# # Create provider and agents
# provider <- new_anthropic()
# 
# # Create specialized agents
# summarizer <- new_agent("summarizer", provider)
# analyzer <- new_agent("analyzer", provider)
# formatter <- new_agent("formatter", provider)
# 
# # Configure each agent with specific instructions
# set_system_prompt(
#   summarizer$provider,
#   "You are a text summarizer. Provide concise, one-sentence summaries."
# )
# set_system_prompt(
#   analyzer$provider,
#   "You are a sentiment analyzer. Analyze the emotional tone and return just the sentiment (positive/negative/neutral)."
# )
# set_system_prompt(
#   formatter$provider,
#   "You are a formatter. Take the previous analysis and format it as: 'Summary: [summary] | Sentiment: [sentiment]'"
# )
# 
# # Create workflow by chaining agent steps inline
# text_workflow <- step(summarizer, name = "summarize") %->%
#                  step(analyzer, name = "analyze_sentiment") %->%
#                  step(formatter, name = "format_output")
# 
# # View the workflow structure
# print(text_workflow)
# 
# # Execute the workflow
# input_text <- "The new product launch was incredibly successful, exceeding all our expectations. Customers are thrilled with the innovative features and the team is celebrating this major milestone."
# 
# result <- execute(text_workflow, input_text)
# print(result)

## ----mixed-workflow-----------------------------------------------------------
# # Function to preprocess text
# clean_text <- function(text) {
#   # Remove extra whitespace and convert to lowercase
#   cleaned <- trimws(tolower(text))
#   cat("Cleaned text:", substr(cleaned, 1, 50), "...\n")
#   cleaned
# }
# 
# # Function to add metadata
# add_metadata <- function(analysis) {
#   # Add timestamp and word count to the analysis
#   timestamp <- Sys.time()
#   word_count <- length(strsplit(analysis, "\\s+")[[1]])
# 
#   result <- paste0(
#     "Analysis: ", analysis, "\n",
#     "Generated: ", timestamp, "\n",
#     "Word count: ", word_count
#   )
# 
#   cat("Added metadata\n")
#   result
# }
# 
# # Create an agent for the core analysis
# analyzer <- new_agent("text_analyzer", provider)
# set_system_prompt(
#   analyzer$provider,
#   "Analyze the given text and provide insights about its main themes, tone, and key messages. Be concise but thorough."
# )
# 
# # Create mixed workflow: function -> agent -> function
# mixed_workflow <- step(clean_text, name = "preprocess") %->%
#                   step(analyzer, name = "analyze") %->%
#                   step(add_metadata, name = "finalize")
# 
# # View the workflow structure
# print(mixed_workflow)
# 
# # Execute the mixed workflow
# input_text <- "   THE QUARTERLY RESULTS show STRONG GROWTH across all sectors!   "
# result <- execute(mixed_workflow, input_text)
# print(result)

## ----data-flow-example, eval=FALSE--------------------------------------------
# # Input -> Step 1 -> Step 2 -> Step 3 -> Output
# #   5   ->   15   ->   30   ->   25   -> Final Result

## ----step-naming--------------------------------------------------------------
# # Steps can be named for clarity
# my_workflow <- step(my_function, name = "descriptive_name") %->%
#                step(another_function, name = "another_step")
# 
# # Names appear in workflow output and debugging
# print(my_workflow)  # Shows step names and visual diagram

## ----error-handling-----------------------------------------------------------
# # Function that might fail
# risky_function <- function(x) {
#   if (x < 0) stop("Cannot process negative numbers")
#   x * 2
# }
# 
# # Workflow will stop if risky_function fails
# risky_workflow <- step(risky_function, name = "risky_step")

## ----simple-steps-------------------------------------------------------------
# # Good: Single responsibility
# validate_input <- function(x) {
#   if (!is.numeric(x)) stop("Input must be numeric")
#   x
# }
# 
# # Good: Single transformation
# double_value <- function(x) x * 2
# 
# # Better than one complex function doing both

## ----descriptive-names--------------------------------------------------------
# # Good: Clear what each step does
# workflow <- step(validate_input, name = "validate") %->%
#            step(double_value, name = "double") %->%
#            step(format_output, name = "format")

## ----reusability--------------------------------------------------------------
# # Create reusable steps
# validation_step <- step(validate_input, name = "validate")
# doubling_step <- step(double_value, name = "double")
# 
# # Use in multiple workflows
# workflow_a <- validation_step %->% doubling_step
# workflow_b <- validation_step %->% other_step %->% doubling_step

## ----strategic-mixing---------------------------------------------------------
# # Use functions for:
# # - Data validation and cleaning
# # - Mathematical operations
# # - Formatting and output preparation
# 
# # Use agents for:
# # - Text analysis and interpretation
# # - Decision making
# # - Creative tasks
# # - Context-dependent processing

## ----preprocessing-pattern----------------------------------------------------
# preprocessing <- step(validate_data, name = "validate") %->%
#                 step(clean_data, name = "clean") %->%
#                 step(normalize_data, name = "normalize")

## ----analysis-pattern---------------------------------------------------------
# analysis <- step(analyzer_agent, name = "analyze") %->%
#            step(extract_insights, name = "extract") %->%
#            step(format_results, name = "format")

## ----full-pipeline------------------------------------------------------------
# complete_pipeline <- preprocessing %->% analysis

