# Implementation Plan for llmr Workflows

## Phase 1: Core Infrastructure

### 1.1 Basic Step System
**Files to create/modify:**
- `R/workflow.R` - Core workflow classes and constructors
- `R/step.R` - Step generic and methods

**Tasks:**
```r
# R/step.R
- Implement step() generic
- Implement step.function() method
- Implement step.agent() method
- Add step class validation

# R/workflow.R  
- Create workflow class structure
- Implement workflow constructor new_workflow()
- Add basic workflow validation
- Implement print.workflow() method
```

**Tests:**
- `tests/testthat/test-step.R` - Test step creation and validation
- `tests/testthat/test-workflow-basic.R` - Test workflow object creation

### 1.2 Custom Pipe Operator
**Files:**
- `R/workflow-operators.R` - Custom operators

**Tasks:**
```r
# R/workflow-operators.R
- Implement %->% operator
- Handle step %->% step (create new workflow)
- Handle workflow %->% step (add step to workflow)
- Add operator validation and error handling
```

**Tests:**
- `tests/testthat/test-operators.R` - Test pipe operator combinations

## Phase 2: Linear Workflows

### 2.1 Basic Workflow Building
**Files to modify:**
- `R/workflow.R`

**Tasks:**
```r
# R/workflow.R
- Implement add_step_to_workflow()
- Implement generate_step_id()
- Add DAG edge management
- Implement workflow$current_exits tracking
```

### 2.2 Workflow Execution
**Files:**
- `R/workflow-execution.R`

**Tasks:**
```r
# R/workflow-execution.R
- Implement execute.workflow() generic
- Implement execute.workflow_step() methods
- Add topological sort for execution order
- Implement data passing between steps
- Add execution error handling
```

**Tests:**
- `tests/testthat/test-workflow-linear.R` - Test linear workflow execution

## Phase 3: Branching System

### 3.1 When/Condition Nodes
**Files:**
- `R/workflow-branching.R`

**Tasks:**
```r
# R/workflow-branching.R
- Implement when() function
- Create workflow_condition_node class
- Implement add_branch_to_workflow()
- Add branch validation logic
```

### 3.2 Branch Execution
**Files to modify:**
- `R/workflow-execution.R`

**Tasks:**
```r
# R/workflow-execution.R
- Implement execute_condition_node()
- Add conditional edge following
- Implement parallel branch execution
- Add branch result merging
```

**Tests:**
- `tests/testthat/test-workflow-branching.R` - Test conditional branching
- `tests/testthat/test-workflow-parallel.R` - Test parallel execution

## Phase 4: Integration & Polish

### 4.1 NAMESPACE Updates
**Files to modify:**
- `NAMESPACE`

**Tasks:**
```r
# Add exports
export(step)
export(new_workflow)
export(execute)
export(when)
S3method(step, function)
S3method(step, agent)
S3method(execute, workflow)
S3method(print, workflow)
```

### 4.2 Documentation
**Files:**
- `man/step.Rd`
- `man/workflow.Rd`
- `man/when.Rd`
- `man/grapes-arrow-grapes.Rd` (for %->%)

**Tasks:**
- Add roxygen2 documentation for all functions
- Create workflow vignette
- Add examples to README

### 4.3 Advanced Features
**Files:**
- `R/workflow-utils.R`

**Tasks:**
```r
# R/workflow-utils.R
- Implement workflow visualization (optional)
- Add workflow validation functions
- Implement workflow composition utilities
- Add debugging/tracing capabilities
```

## Phase 5: Testing & Examples

### 5.1 Comprehensive Testing
**Files:**
- `tests/testthat/test-workflow-integration.R`
- `tests/testthat/test-workflow-errors.R`

**Tasks:**
- Integration tests with agents and functions
- Error handling and edge cases
- Performance testing with complex workflows
- Memory usage validation

### 5.2 Examples and Documentation
**Files:**
- `examples/workflow-examples.R`
- Update `README.md`

**Tasks:**
- Create realistic workflow examples
- Add workflow section to README
- Create workflow tutorial vignette

## Implementation Order

1. **Week 1**: Phase 1 (Core Infrastructure)
2. **Week 2**: Phase 2 (Linear Workflows) 
3. **Week 3**: Phase 3 (Branching System)
4. **Week 4**: Phase 4 (Integration & Polish)
5. **Week 5**: Phase 5 (Testing & Examples)

## Key Design Decisions to Validate

1. **DAG Structure**: Confirm the workflow object structure works for complex branching
2. **Memory Management**: Ensure large workflows don't cause memory issues
3. **Error Propagation**: Define how errors in branches affect overall execution
4. **Result Merging**: Decide how parallel branch results are combined
5. **Agent Integration**: Ensure seamless integration with existing agent system

## Success Criteria

- [ ] Linear workflows execute correctly
- [ ] Conditional branching works with single and multiple conditions
- [ ] Parallel execution handles multiple branches
- [ ] Integration with existing agents and functions
- [ ] Comprehensive test coverage (>90%)
- [ ] Documentation and examples complete
- [ ] Performance acceptable for complex workflows

## Detailed Implementation Steps

### Phase 1 Implementation Details

#### Step 1.1: Basic Step System

**R/step.R**
```r
#' Create a workflow step
#' 
#' @param x An agent or function to use as a step
#' @param name Optional name for the step
#' @param ... Additional arguments
#' @export
step <- function(x, ...) {
  UseMethod("step")
}

#' @export
step.function <- function(fn, name = NULL, ...) {
  structure(
    list(
      type = "function",
      handler = fn,
      name = name %||% deparse(substitute(fn))
    ),
    class = c("workflow_step", "function_step")
  )
}

#' @export  
step.agent <- function(agent, name = NULL, ...) {
  structure(
    list(
      type = "agent", 
      handler = agent,
      name = name %||% "agent"
    ),
    class = c("workflow_step", "agent_step")
  )
}
```

**R/workflow.R**
```r
#' Create a new workflow
#' 
#' @param name Optional name for the workflow
#' @export
new_workflow <- function(name = NULL) {
  structure(
    list(
      name = name,
      nodes = list(),
      edges = list(),
      entry_point = NULL,
      current_exits = character(),
      .counter = 0L
    ),
    class = "workflow"
  )
}

#' @export
print.workflow <- function(x, ...) {
  cat("Workflow:", x$name %||% "<unnamed>", "\n")
  cat("Nodes:", length(x$nodes), "\n")
  cat("Edges:", length(x$edges), "\n")
  invisible(x)
}
```

#### Step 1.2: Custom Pipe Operator

**R/workflow-operators.R**
```r
#' Workflow pipe operator
#' 
#' @param lhs Left-hand side (step or workflow)
#' @param rhs Right-hand side (step, workflow, or when)
#' @export
`%->%` <- function(lhs, rhs) {
  if (inherits(lhs, "workflow_step") && inherits(rhs, "workflow_step")) {
    # step %->% step: create new workflow
    create_workflow_from_steps(lhs, rhs)
  } else if (inherits(lhs, "workflow") && inherits(rhs, "workflow_step")) {
    # workflow %->% step: add step to workflow
    add_step_to_workflow(lhs, rhs)
  } else if (inherits(lhs, "workflow") && inherits(rhs, "workflow_when")) {
    # workflow %->% when(): handle branching
    add_branch_to_workflow(lhs, rhs)
  } else {
    stop("Invalid workflow pipe operation")
  }
}
```

### Phase 2 Implementation Details

#### Step 2.1: Basic Workflow Building

**R/workflow.R** (additions)
```r
add_step_to_workflow <- function(workflow, step) {
  step_id <- generate_step_id(workflow, step)
  
  # Add node
  workflow$nodes[[step_id]] <- step
  
  # Connect to current exits
  for (exit_id in workflow$current_exits) {
    workflow$edges <- append(workflow$edges, 
      list(list(from = exit_id, to = step_id)))
  }
  
  # Update current exits
  workflow$current_exits <- step_id
  
  # Set entry point if first step
  if (is.null(workflow$entry_point)) {
    workflow$entry_point <- step_id
  }
  
  workflow
}

generate_step_id <- function(workflow, step) {
  workflow$.counter <- workflow$.counter + 1L
  paste0(step$name, "_", workflow$.counter)
}
```

#### Step 2.2: Workflow Execution

**R/workflow-execution.R**
```r
#' Execute a workflow
#' 
#' @param workflow A workflow object
#' @param input Initial input data
#' @export
execute <- function(workflow, input) {
  UseMethod("execute")
}

#' @export
execute.workflow <- function(workflow, input) {
  # Topological sort for execution order
  execution_order <- topological_sort(workflow)
  
  # Execute steps in order
  current_data <- input
  for (step_id in execution_order) {
    step <- workflow$nodes[[step_id]]
    current_data <- execute_step(step, current_data)
  }
  
  current_data
}

execute_step <- function(step, input) {
  UseMethod("execute_step")
}

execute_step.function_step <- function(step, input) {
  step$handler(input)
}

execute_step.agent_step <- function(step, input) {
  message <- new_message(input)
  response <- request(step$handler, message)
  response$content
}
```

This detailed implementation plan provides a clear roadmap for building the workflow feature incrementally while maintaining code quality and test coverage.