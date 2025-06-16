## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## ----setup--------------------------------------------------------------------
# library(llmr)

## ----api-setup, eval=FALSE----------------------------------------------------
# set_api_key("your-anthropic-api-key-here")
# provider <- new_anthropic()

## ----basic-conditional--------------------------------------------------------
# # Define condition function
# classify_number <- function(x) {
#   if (x > 100) {
#     "large"
#   } else if (x > 10) {
#     "medium"
#   } else {
#     "small"
#   }
# }
# 
# # Define branch-specific processing
# process_large <- function(x) {
#   cat("Processing large number:", x, "\n")
#   x / 10  # Scale down large numbers
# }
# 
# process_medium <- function(x) {
#   cat("Processing medium number:", x, "\n")
#   x * 2   # Double medium numbers
# }
# 
# process_small <- function(x) {
#   cat("Processing small number:", x, "\n")
#   x + 100 # Boost small numbers
# }
# 
# # Create conditional workflow
# number_processor <- when(
#   classify_number,
#   large = step(process_large, name = "scale_down"),
#   medium = step(process_medium, name = "double"),
#   small = step(process_small, name = "boost")
# )
# 
# # View the workflow structure
# print(number_processor)
# 
# # Test with different values
# test_values <- c(5, 50, 500)
# for (val in test_values) {
#   cat("\n--- Processing:", val, "---\n")
#   result <- execute(number_processor, val)
#   cat("Result:", result, "\n")
# }

## ----preprocessing-conditional------------------------------------------------
# # Preprocessor function
# validate_and_prepare <- function(x) {
#   cat("Validating input:", x, "\n")
#   if (!is.numeric(x)) {
#     stop("Input must be numeric")
#   }
#   abs(x)  # Ensure positive values
# }
# 
# # Create workflow with preprocessing
# robust_processor <- step(validate_and_prepare, name = "validate") %->%
#                    when(
#                      classify_number,
#                      large = step(process_large, name = "scale_down"),
#                      medium = step(process_medium, name = "double"),
#                      small = step(process_small, name = "boost")
#                    )
# 
# print(robust_processor)
# 
# # Test with various inputs
# test_inputs <- c(-25, 15, 150)
# for (input in test_inputs) {
#   cat("\n--- Processing:", input, "---\n")
#   result <- execute(robust_processor, input)
#   cat("Final result:", result, "\n")
# }

## ----parallel-processing------------------------------------------------------
# # Define analysis functions
# sentiment_analysis <- function(text) {
#   cat("Analyzing sentiment...\n")
#   # Simulate sentiment analysis
#   sentiments <- c("positive", "negative", "neutral")
#   sample(sentiments, 1)
# }
# 
# word_count <- function(text) {
#   cat("Counting words...\n")
#   length(strsplit(text, "\\s+")[[1]])
# }
# 
# extract_keywords <- function(text) {
#   cat("Extracting keywords...\n")
#   words <- strsplit(tolower(text), "\\s+")[[1]]
#   # Return top 3 unique words
#   unique_words <- unique(words)
#   sample(unique_words, min(3, length(unique_words)))
# }
# 
# readability_score <- function(text) {
#   cat("Calculating readability...\n")
#   # Simple readability metric
#   words <- strsplit(text, "\\s+")[[1]]
#   avg_word_length <- mean(nchar(words))
#   round(avg_word_length, 2)
# }
# 
# # Function to combine parallel results
# combine_analysis <- function(results) {
#   cat("Combining analysis results...\n")
#   list(
#     sentiment = results$sentiment,
#     word_count = results$word_count,
#     keywords = results$keywords,
#     readability = results$readability,
#     summary = paste(
#       "Text analysis:", results$word_count, "words,",
#       results$sentiment, "sentiment,",
#       "readability score:", results$readability
#     )
#   )
# }
# 
# # Create parallel analysis workflow
# text_analyzer <- when(
#   function(text) c("sentiment", "word_count", "keywords", "readability"),
#   sentiment = step(sentiment_analysis, name = "sentiment"),
#   word_count = step(word_count, name = "count_words"),
#   keywords = step(extract_keywords, name = "extract_keys"),
#   readability = step(readability_score, name = "readability")
# ) %->%
# step(combine_analysis, name = "combine")
# 
# print(text_analyzer)
# 
# # Test parallel processing
# sample_text <- "The advanced workflow capabilities in llmr enable sophisticated data processing patterns."
# result <- execute(text_analyzer, sample_text)
# str(result)

## ----dynamic-routing----------------------------------------------------------
# # Data type classifier
# classify_data_type <- function(data) {
#   if (is.character(data)) {
#     if (nchar(data) > 100) {
#       "long_text"
#     } else {
#       "short_text"
#     }
#   } else if (is.numeric(data)) {
#     if (length(data) > 1) {
#       "numeric_vector"
#     } else {
#       "single_number"
#     }
#   } else {
#     "other"
#   }
# }
# 
# # Specialized processors for different data types
# process_long_text <- function(text) {
#   cat("Processing long text (", nchar(text), "characters)\n")
#   # Summarize long text
#   words <- strsplit(text, "\\s+")[[1]]
#   paste("Summary:", length(words), "words starting with:",
#         paste(head(words, 3), collapse = " "))
# }
# 
# process_short_text <- function(text) {
#   cat("Processing short text:", text, "\n")
#   # Simple transformation for short text
#   toupper(text)
# }
# 
# process_numeric_vector <- function(vec) {
#   cat("Processing numeric vector of length", length(vec), "\n")
#   list(
#     mean = mean(vec),
#     sd = sd(vec),
#     range = range(vec)
#   )
# }
# 
# process_single_number <- function(num) {
#   cat("Processing single number:", num, "\n")
#   list(
#     value = num,
#     squared = num^2,
#     sqrt = sqrt(abs(num))
#   )
# }
# 
# process_other <- function(data) {
#   cat("Processing other data type:", class(data), "\n")
#   paste("Unsupported data type:", class(data)[1])
# }
# 
# # Create dynamic routing workflow
# data_router <- when(
#   classify_data_type,
#   long_text = step(process_long_text, name = "long_text_processor"),
#   short_text = step(process_short_text, name = "short_text_processor"),
#   numeric_vector = step(process_numeric_vector, name = "vector_processor"),
#   single_number = step(process_single_number, name = "number_processor"),
#   other = step(process_other, name = "fallback_processor")
# )
# 
# print(data_router)
# 
# # Test with different data types
# test_data <- list(
#   "Hello World",
#   "This is a much longer text that contains many words and should be classified as long text for processing purposes.",
#   42,
#   c(1, 2, 3, 4, 5),
#   factor(c("A", "B", "C"))
# )
# 
# for (i in seq_along(test_data)) {
#   cat("\n--- Test", i, "---\n")
#   result <- execute(data_router, test_data[[i]])
#   print(result)
# }

## ----agent-conditional--------------------------------------------------------
# # Create specialized agents
# technical_writer <- new_agent("technical_writer", provider)
# creative_writer <- new_agent("creative_writer", provider)
# data_analyst <- new_agent("data_analyst", provider)
# 
# # Configure agents
# set_system_prompt(
#   technical_writer$provider,
#   "You are a technical writer. Analyze text for technical accuracy and clarity. Provide structured feedback."
# )
# 
# set_system_prompt(
#   creative_writer$provider,
#   "You are a creative writing expert. Analyze text for creativity, style, and emotional impact."
# )
# 
# set_system_prompt(
#   data_analyst$provider,
#   "You are a data analyst. Extract quantitative insights and patterns from text."
# )
# 
# # Content classifier
# classify_content <- function(text) {
#   # Simple heuristic classification
#   technical_keywords <- c("algorithm", "function", "data", "analysis", "method", "system")
#   creative_keywords <- c("story", "character", "emotion", "beautiful", "imagine", "dream")
# 
#   text_lower <- tolower(text)
#   technical_score <- sum(sapply(technical_keywords, function(kw) grepl(kw, text_lower)))
#   creative_score <- sum(sapply(creative_keywords, function(kw) grepl(kw, text_lower)))
# 
#   if (technical_score > creative_score) {
#     "technical"
#   } else if (creative_score > technical_score) {
#     "creative"
#   } else {
#     "general"
#   }
# }
# 
# # Create intelligent content processor
# content_processor <- when(
#   classify_content,
#   technical = step(technical_writer, name = "technical_analysis"),
#   creative = step(creative_writer, name = "creative_analysis"),
#   general = step(data_analyst, name = "general_analysis")
# )
# 
# print(content_processor)
# 
# # Test with different content types
# technical_text <- "The algorithm processes data using advanced statistical methods to optimize system performance."
# creative_text <- "The beautiful story unfolds as the character embarks on an emotional journey through imagination."
# general_text <- "The quarterly report shows steady growth across all business segments."
# 
# test_texts <- list(
#   technical = technical_text,
#   creative = creative_text,
#   general = general_text
# )
# 
# for (type in names(test_texts)) {
#   cat("\n--- Analyzing", type, "content ---\n")
#   result <- execute(content_processor, test_texts[[type]])
#   cat("Analysis result:", substr(result, 1, 100), "...\n")
# }

## ----complex-workflow---------------------------------------------------------
# # Multi-stage document processor
# document_preprocessor <- function(doc) {
#   cat("Preprocessing document...\n")
#   # Clean and prepare document
#   cleaned <- trimws(doc)
#   list(
#     content = cleaned,
#     length = nchar(cleaned),
#     word_count = length(strsplit(cleaned, "\\s+")[[1]])
#   )
# }
# 
# # Document classifier based on length and content
# classify_document <- function(doc_info) {
#   if (doc_info$word_count > 100) {
#     "long_document"
#   } else if (doc_info$word_count > 20) {
#     "medium_document"
#   } else {
#     "short_document"
#   }
# }
# 
# # Specialized processors for different document lengths
# process_long_document <- function(doc_info) {
#   cat("Processing long document...\n")
#   # For long documents, do parallel analysis
#   execute(
#     when(
#       function(x) c("summary", "keywords", "sentiment"),
#       summary = step(function(x) paste("Summary of", x$word_count, "words"), name = "summarize"),
#       keywords = step(function(x) c("key1", "key2", "key3"), name = "extract_keywords"),
#       sentiment = step(function(x) "neutral", name = "analyze_sentiment")
#     ),
#     doc_info
#   )
# }
# 
# process_medium_document <- function(doc_info) {
#   cat("Processing medium document...\n")
#   list(
#     type = "medium",
#     analysis = paste("Medium document with", doc_info$word_count, "words"),
#     recommendation = "Consider expanding or condensing"
#   )
# }
# 
# process_short_document <- function(doc_info) {
#   cat("Processing short document...\n")
#   list(
#     type = "short",
#     analysis = paste("Short document with", doc_info$word_count, "words"),
#     recommendation = "Consider expanding content"
#   )
# }
# 
# # Final formatter
# format_results <- function(analysis) {
#   cat("Formatting final results...\n")
#   list(
#     timestamp = Sys.time(),
#     analysis = analysis,
#     status = "complete"
#   )
# }
# 
# # Create complex multi-stage workflow
# document_pipeline <- step(document_preprocessor, name = "preprocess") %->%
#                     when(
#                       classify_document,
#                       long_document = step(process_long_document, name = "process_long"),
#                       medium_document = step(process_medium_document, name = "process_medium"),
#                       short_document = step(process_short_document, name = "process_short")
#                     ) %->%
#                     step(format_results, name = "format")
# 
# print(document_pipeline)
# 
# # Test with documents of different lengths
# test_documents <- list(
#   short = "Brief note.",
#   medium = "This is a medium-length document that contains several sentences and provides a reasonable amount of content for analysis purposes.",
#   long = paste(rep("This is a very long document with many repeated sentences to simulate a lengthy piece of content.", 10), collapse = " ")
# )
# 
# for (doc_type in names(test_documents)) {
#   cat("\n--- Processing", doc_type, "document ---\n")
#   result <- execute(document_pipeline, test_documents[[doc_type]])
#   cat("Processing complete. Result type:", class(result), "\n")
# }

## ----error-handling-----------------------------------------------------------
# # Safe processor with error handling
# safe_processor <- function(data) {
#   tryCatch({
#     if (is.character(data) && nchar(data) == 0) {
#       stop("Empty string not allowed")
#     }
#     if (is.numeric(data) && data < 0) {
#       stop("Negative numbers not supported")
#     }
#     # Normal processing
#     paste("Processed:", data)
#   }, error = function(e) {
#     cat("Error occurred:", e$message, "\n")
#     paste("Error:", e$message)
#   })
# }
# 
# # Fallback processor
# fallback_processor <- function(data) {
#   cat("Using fallback processing...\n")
#   paste("Fallback result for:", as.character(data))
# }
# 
# # Workflow with error handling
# robust_workflow <- step(safe_processor, name = "safe_process") %->%
#                   when(
#                     function(result) {
#                       if (grepl("^Error:", result)) {
#                         "error"
#                       } else {
#                         "success"
#                       }
#                     },
#                     error = step(fallback_processor, name = "fallback"),
#                     success = step(function(x) paste("Success:", x), name = "finalize")
#                   )
# 
# print(robust_workflow)
# 
# # Test error handling
# test_inputs <- list("valid input", "", -5, 42)
# for (input in test_inputs) {
#   cat("\n--- Testing input:", as.character(input), "---\n")
#   result <- execute(robust_workflow, input)
#   cat("Result:", result, "\n")
# }

## ----condition-best-practices-------------------------------------------------
# # Good: Clear, single-purpose condition
# classify_by_size <- function(data) {
#   if (length(data) > 1000) "large"
#   else if (length(data) > 100) "medium"
#   else "small"
# }
# 
# # Good: Descriptive branch names
# size_router <- when(
#   classify_by_size,
#   large = step(batch_processor, name = "batch_process"),
#   medium = step(standard_processor, name = "standard_process"),
#   small = step(quick_processor, name = "quick_process")
# )

## ----edge-cases---------------------------------------------------------------
# # Always include fallback branches
# robust_classifier <- function(data) {
#   if (is.null(data)) return("null")
#   if (length(data) == 0) return("empty")
#   if (is.character(data)) return("text")
#   if (is.numeric(data)) return("number")
#   "unknown"  # Fallback for unexpected types
# }

## ----meaningful-names---------------------------------------------------------
# # Good: Descriptive workflow and step names
# data_pipeline <- step(validate_input, name = "validate") %->%
#                 when(
#                   classify_data_complexity,
#                   simple = step(fast_processor, name = "fast_track"),
#                   complex = step(thorough_processor, name = "deep_analysis")
#                 ) %->%
#                 step(format_output, name = "finalize")

