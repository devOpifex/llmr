devtools::load_all()

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

# Define preprocessing function that generates random values
generate_random_value <- function(x) {
  value <- runif(1, 0, 30)
  cat("Generated random value:", round(value, 2), "\n")
  value
}

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
branching_workflow <- step(generate_random_value) %->%
  when(
    check_value, # Use check_value as the condition function
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

generate_string <- function(x) {
  cat("Generating random string\n")
  paste(sample(letters, 10), collapse = "")
}

# Create parallel workflow
text_analysis_workflow <- step(generate_string) %->% # Pass through input
  when(
    function(text) c("sentiment", "word_count", "keywords"), # Execute all branches
    sentiment = step(sentiment_analysis),
    word_count = step(word_count),
    keywords = step(extract_keywords)
  ) %->%
  step(combine_analysis)

cat("Created text analysis workflow:\n")
print(text_analysis_workflow)

# Test parallel processing
sample_text <- "This is a wonderful example of text analysis using workflows in R"
cat("Analyzing text:", sample_text, "\n")
analysis_result <- execute(text_analysis_workflow, sample_text)
cat("Analysis complete:\n")
str(analysis_result)

# Example 4: Complex Multi-Stage Workflow ===================================
