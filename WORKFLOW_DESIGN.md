# Workflow Feature Design for llmr

## Overview

This document outlines the design for adding workflow functionality to the llmr package. Workflows support chaining, branching (with and without conditions), merging, and can contain both agents and functions as processing nodes.

## Core API Design

### Generic `step` Function

The `step` function is a generic with methods for both agents and functions:

```r
# Generic step function
step <- function(x, ...) UseMethod("step")

# Method for functions
step.function <- function(fn, name = NULL, ...) {
  structure(
    list(type = "function", handler = fn, name = name %||% deparse(substitute(fn))),
    class = c("workflow_step", "function_step")
  )
}

# Method for agents  
step.agent <- function(agent, name = NULL, ...) {
  structure(
    list(type = "agent", handler = agent, name = name %||% "agent"),
    class = c("workflow_step", "agent_step")
  )
}
```

### Custom Pipe Operator

The `%->%` operator creates workflow edges automatically:

```r
`%->%` <- function(lhs, rhs) {
  # Creates workflow edges automatically
  build_workflow_edge(lhs, rhs)
}
```

## Basic Usage

### Simple Linear Workflow

```r
# Mix agents and functions naturally
my_agent <- new_agent("processor")
validate_fn <- function(data) data[complete.cases(data), ]

workflow <- step(validate_fn) %->%           # function step
            step(my_agent) %->%              # agent step  
            step(function(x) x$summary) %->% # inline function step
            step(another_agent)              # another agent step

# Execute workflow
result <- execute(workflow, input = raw_data)
```

### Reusable Steps

```r
# Steps can be created and reused
data_validator <- step(validate_data_fn)
text_processor <- step(nlp_agent)
summarizer <- step(summary_agent)

# Compose workflows
workflow1 <- data_validator %->% text_processor %->% summarizer
workflow2 <- data_validator %->% step(different_agent) %->% summarizer
```

## Branching and Conditional Logic

### Conditional Branching with `when`

The `when` function takes a single function that returns branch name(s) to execute:

```r
# Simple binary branching
workflow <- step(validate_data) %->%
            when(
              function(result) if (result$valid) "proceed" else "fix",
              proceed = step(process_agent),
              fix = step(repair_agent) %->% step(process_agent)
            ) %->%
            step(output)

# Multiple condition branching
workflow <- step(load_data) %->%
            step(check_quality) %->%
            when(
              function(result) {
                if (result$quality > 0.8) "high_quality"
                else if (result$quality > 0.5) "medium_quality" 
                else "low_quality"
              },
              high_quality = step(advanced_agent) %->% step(detailed_report),
              medium_quality = step(standard_agent) %->% step(standard_report),
              low_quality = step(cleanup_agent) %->% step(basic_report)
            ) %->%
            step(final_output)
```

### Parallel Execution

Return multiple branch names for parallel execution:

```r
# Multiple parallel branches
workflow <- step(preprocess) %->%
            when(
              function(result) c("sentiment", "classify", "extract"), # return multiple
              sentiment = step(sentiment_agent),
              classify = step(classifier_agent),
              extract = step(extractor_agent)
            ) %->%
            step(combine_results) %->%
            step(summary)
```

### Dynamic Branching

```r
# Function can dynamically decide which branches to execute
workflow <- step(analyze_data) %->%
            when(
              function(result) {
                branches <- c()
                if (result$has_text) branches <- c(branches, "text_analysis")
                if (result$has_numbers) branches <- c(branches, "numeric_analysis") 
                if (result$has_images) branches <- c(branches, "image_analysis")
                branches
              },
              text_analysis = step(text_agent),
              numeric_analysis = step(stats_agent),
              image_analysis = step(vision_agent)
            ) %->%
            step(merge_results)
```

## Implementation Structure

### Core Classes

```r
# Workflow container
workflow <- structure(
  list(
    name = "workflow_name",
    steps = list(),
    edges = list(),
    env = new.env()
  ),
  class = "workflow"
)

# When node for conditional branching
when <- function(condition_fn, ...) {
  branches <- list(...)
  structure(
    list(
      type = "conditional",
      condition = condition_fn,
      branches = branches
    ),
    class = "workflow_when"
  )
}
```

### Execution Methods

```r
# Execute method for function steps
execute.function_step <- function(step_obj, input, ...) {
  step_obj$handler(input)
}

# Execute method for agent steps  
execute.agent_step <- function(step_obj, input, ...) {
  # Convert input to message and send to agent
  message <- new_message(input)
  response <- request(step_obj$handler, message)
  response$content
}

# Execute when nodes
execute_when <- function(when_node, input) {
  branch_names <- when_node$condition(input)
  
  # Execute selected branches
  results <- list()
  for (branch_name in branch_names) {
    if (branch_name %in% names(when_node$branches)) {
      results[[branch_name]] <- execute(when_node$branches[[branch_name]], input)
    }
  }
  
  results
}
```

## Design Principles

1. **Generic Dispatch**: `step()` works transparently with both agents and functions through S3 method dispatch
2. **Fluent Interface**: Custom `%->%` operator creates natural, readable workflow chains
3. **Flexible Branching**: Single condition function returns branch names for maximum flexibility
4. **Dynamic Execution**: Branches can be determined at runtime based on data
5. **Reusable Components**: Steps can be created once and reused across workflows
6. **Type Safety**: Method dispatch ensures proper handling of different step types
7. **Consistent with llmr**: Follows existing patterns in the package (S3 classes, pipe-friendly design)

## Advanced Examples

### Complex Multi-Stage Workflow

```r
# Data processing pipeline with multiple decision points
workflow <- step(load_raw_data) %->%
            step(data_validator) %->%
            when(
              function(result) if (result$needs_cleaning) "clean" else "process",
              clean = step(data_cleaner) %->% step(quality_checker),
              process = step(identity) # pass through
            ) %->%
            when(
              function(result) {
                types <- c()
                if (result$has_text) types <- c(types, "nlp")
                if (result$has_numbers) types <- c(types, "stats")
                if (result$has_images) types <- c(types, "vision")
                types
              },
              nlp = step(text_analysis_agent) %->% step(sentiment_extractor),
              stats = step(statistical_agent) %->% step(trend_analyzer),
              vision = step(image_analysis_agent) %->% step(object_detector)
            ) %->%
            step(result_merger) %->%
            step(report_generator) %->%
            step(output_formatter)

# Execute with error handling
result <- tryCatch(
  execute(workflow, input = my_data),
  error = function(e) {
    message("Workflow failed: ", e$message)
    NULL
  }
)
```

This design provides a powerful, flexible workflow system that integrates seamlessly with llmr's existing architecture while maintaining R's functional programming idioms.