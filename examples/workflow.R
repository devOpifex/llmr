devtools::load_all()

# Example 1: Basic Linear Workflow with Functions ===========================

cat("=== Example 1: Basic Linear Workflow ===\n")

# Define some simple processing functions
add_ten <- function(x) {
  cat("Adding 10 to", x, "\n")
  x + 10
}

multiply_by_two <- function(x) {
  cat("Multiplying", x, "by 2\n")
  x * 2
}

subtract_five <- function(x) {
  cat("Subtracting 5 from", x, "\n")
  x - 5
}

# Create workflow steps
step1 <- step(add_ten, name = "add_ten")
step2 <- step(multiply_by_two, name = "multiply_two")
step3 <- step(subtract_five, name = "subtract_five")

# Chain steps into a workflow
linear_workflow <- step1 %->% step2 %->% step3

cat("Created workflow:\n")
print(linear_workflow)

# Execute the workflow
input_value <- 5
cat("\nExecuting workflow with input:", input_value, "\n")
result <- execute(linear_workflow, input_value)
cat("Final result:", result, "\n")
cat("Expected: ((5 + 10) * 2) - 5 =", ((5 + 10) * 2) - 5, "\n\n")

# Example 2: Conditional Branching ==========================================

cat("=== Example 2: Conditional Branching ===\n")

# Define condition function
check_value <- function(x) {
  cat("Checking value:", x, "\n")
  if (x > 20) {
    "high"
  } else if (x > 10) {
    "medium"
  } else {
    "low"
  }
}

# Define branch-specific functions
process_high <- function(x) {
  cat("Processing high value:", x, "\n")
  x * 0.9 # Apply 10% discount
}

process_medium <- function(x) {
  cat("Processing medium value:", x, "\n")
  x * 0.95 # Apply 5% discount
}

process_low <- function(x) {
  cat("Processing low value:", x, "\n")
  x # No discount
}

format_result <- function(x) {
  cat("Formatting result:", x, "\n")
  paste("Final value:", round(x, 2))
}

# Create branching workflow
branching_workflow <- step(check_value) %->%
  when(
    function(result) result, # The condition function returns the branch name
    high = step(process_high),
    medium = step(process_medium),
    low = step(process_low)
  ) %->%
  step(format_result)

cat("Created branching workflow:\n")
print(branching_workflow)

# Test with different values
test_values <- c(5, 15, 25)
for (val in test_values) {
  cat("\n--- Testing with value:", val, "---\n")
  result <- execute(branching_workflow, val)
  cat("Result:", result, "\n")
}

# Example 3: Parallel Processing ============================================

cat("\n=== Example 3: Parallel Processing ===\n")

# Define analysis functions
sentiment_analysis <- function(text) {
  cat("Performing sentiment analysis on:", substr(text, 1, 30), "...\n")
  # Simulate sentiment analysis
  sentiments <- c("positive", "negative", "neutral")
  sample(sentiments, 1)
}

word_count <- function(text) {
  cat("Counting words in text\n")
  length(strsplit(text, "\\s+")[[1]])
}

extract_keywords <- function(text) {
  cat("Extracting keywords from text\n")
  words <- strsplit(tolower(text), "\\s+")[[1]]
  # Return most common words (simplified)
  unique_words <- unique(words)
  sample(unique_words, min(3, length(unique_words)))
}

# Function to combine results
combine_analysis <- function(results) {
  cat("Combining analysis results\n")
  list(
    sentiment = results$sentiment,
    word_count = results$word_count,
    keywords = results$keywords,
    summary = paste(
      "Text has",
      results$word_count,
      "words with",
      results$sentiment,
      "sentiment"
    )
  )
}

# Create parallel workflow
text_analysis_workflow <- step(identity) %->% # Pass through input
  when(
    function(text) c("sentiment", "word_count", "keywords"), # Execute all branches
    sentiment = step(sentiment_analysis),
    word_count = step(word_count),
    keywords = step(extract_keywords)
  ) %->%
  step(combine_analysis)

# Test parallel processing
sample_text <- "This is a wonderful example of text analysis using workflows in R"
cat("Analyzing text:", sample_text, "\n")
analysis_result <- execute(text_analysis_workflow, sample_text)
cat("Analysis complete:\n")
str(analysis_result)

# Example 4: Complex Multi-Stage Workflow ===================================

cat("\n=== Example 4: Complex Multi-Stage Workflow ===\n")

# Data validation function
validate_data <- function(data) {
  cat("Validating data...\n")
  if (is.numeric(data) && length(data) > 0) {
    list(data = data, valid = TRUE, needs_cleaning = any(is.na(data)))
  } else {
    list(data = data, valid = FALSE, needs_cleaning = TRUE)
  }
}

# Data cleaning function
clean_data <- function(result) {
  cat("Cleaning data...\n")
  if (result$valid) {
    cleaned_data <- result$data[!is.na(result$data)]
    list(data = cleaned_data, valid = TRUE, needs_cleaning = FALSE)
  } else {
    result
  }
}

# Statistical analysis functions
basic_stats <- function(result) {
  cat("Computing basic statistics...\n")
  if (result$valid && length(result$data) > 0) {
    list(
      mean = mean(result$data),
      median = median(result$data),
      sd = sd(result$data),
      min = min(result$data),
      max = max(result$data)
    )
  } else {
    list(error = "Invalid data for analysis")
  }
}

advanced_stats <- function(result) {
  cat("Computing advanced statistics...\n")
  if (result$valid && length(result$data) > 2) {
    list(
      mean = mean(result$data),
      median = median(result$data),
      sd = sd(result$data),
      skewness = sum((result$data - mean(result$data))^3) /
        (length(result$data) * sd(result$data)^3),
      kurtosis = sum((result$data - mean(result$data))^4) /
        (length(result$data) * sd(result$data)^4) -
        3
    )
  } else {
    basic_stats(result)
  }
}

# Report generation
generate_report <- function(stats) {
  cat("Generating report...\n")
  if ("error" %in% names(stats)) {
    paste("Analysis failed:", stats$error)
  } else {
    paste(
      "Statistical Report:",
      sprintf("Mean: %.2f", stats$mean),
      sprintf("Median: %.2f", stats$median),
      sprintf("SD: %.2f", stats$sd),
      sep = "\n"
    )
  }
}

# Create complex workflow with multiple decision points
data_analysis_workflow <- step(validate_data) %->%
  when(
    function(result) if (result$needs_cleaning) "clean" else "process",
    clean = step(clean_data),
    process = step(identity) # Pass through unchanged
  ) %->%
  when(
    function(result) {
      if (!result$valid) {
        return("error")
      }
      if (length(result$data) > 10) "advanced" else "basic"
    },
    error = step(function(x) list(error = "Cannot analyze invalid data")),
    basic = step(basic_stats),
    advanced = step(advanced_stats)
  ) %->%
  step(generate_report)

# Test with different datasets
cat("Testing complex workflow:\n")

# Test 1: Clean data, large dataset
test_data1 <- rnorm(20, mean = 50, sd = 10)
cat("\n--- Test 1: Clean large dataset ---\n")
result1 <- execute(data_analysis_workflow, test_data1)
cat(result1, "\n")

# Test 2: Data with missing values, small dataset
test_data2 <- c(1, 2, NA, 4, 5)
cat("\n--- Test 2: Small dataset with missing values ---\n")
result2 <- execute(data_analysis_workflow, test_data2)
cat(result2, "\n")

# Test 3: Invalid data
test_data3 <- "invalid data"
cat("\n--- Test 3: Invalid data ---\n")
result3 <- execute(data_analysis_workflow, test_data3)
cat(result3, "\n")

cat("\n=== Workflow Examples Complete ===\n")

# Example 5: Workflow with Agent Integration (commented out - requires API key)
#
# cat("\n=== Example 5: Agent Integration ===\n")
#
# # This example shows how to integrate agents into workflows
# # Uncomment and set API key to test
#
# # set_api_key("your-api-key-here")
# # text_agent <- new_agent("text_processor")
# #
# # # Create workflow mixing functions and agents
# # mixed_workflow <- step(function(x) paste("Process this text:", x)) %->%
# #   step(text_agent) %->%
# #   step(function(x) paste("Agent response:", x))
# #
# # result <- execute(mixed_workflow, "Hello world")
# # cat("Mixed workflow result:", result, "\n")

