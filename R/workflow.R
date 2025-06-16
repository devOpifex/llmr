#' @importFrom utils deparse substitute
NULL

# Core Workflow Classes and Constructors ====================================

#' Create a new workflow
#' 
#' Creates a new workflow object that can contain steps and manage execution flow.
#' 
#' @param name Optional name for the workflow
#' @return A workflow object
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
  if (!is.null(x$entry_point)) {
    cat("Entry point:", x$entry_point, "\n")
  }
  if (length(x$current_exits) > 0) {
    cat("Current exits:", paste(x$current_exits, collapse = ", "), "\n")
  }
  invisible(x)
}

# Step System ================================================================

#' Create a workflow step
#' 
#' Creates a step that can be used in workflows. Steps can wrap functions
#' or agents to provide processing capabilities.
#' 
#' @param x An agent or function to use as a step
#' @param name Optional name for the step
#' @param ... Additional arguments
#' @return A workflow step object
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

#' @export
print.workflow_step <- function(x, ...) {
  cat("Workflow step (", x$type, "):", x$name, "\n")
  invisible(x)
}

# Workflow Pipe Operator ====================================================

#' Workflow pipe operator
#' 
#' Chains workflow steps together to create execution flows. Can connect
#' steps to steps, steps to workflows, or workflows to steps.
#' 
#' @param lhs Left-hand side (step or workflow)
#' @param rhs Right-hand side (step, workflow, or when)
#' @return A workflow object
#' @export
`%->%` <- function(lhs, rhs) {
  if (inherits(lhs, "workflow_step") && inherits(rhs, "workflow_step")) {
    # step %->% step: create new workflow
    create_workflow_from_steps(lhs, rhs)
  } else if (inherits(lhs, "workflow_step") && inherits(rhs, "workflow_when")) {
    # step %->% when(): create workflow with step, then add branch
    workflow <- create_workflow_from_step(lhs)
    add_branch_to_workflow(workflow, rhs)
  } else if (inherits(lhs, "workflow") && inherits(rhs, "workflow_step")) {
    # workflow %->% step: add step to workflow
    add_step_to_workflow(lhs, rhs)
  } else if (inherits(lhs, "workflow") && inherits(rhs, "workflow_when")) {
    # workflow %->% when(): handle branching
    add_branch_to_workflow(lhs, rhs)
  } else if (inherits(lhs, "workflow_when") && inherits(rhs, "workflow_step")) {
    # when() %->% step: this should not happen directly, but handle gracefully
    stop("Cannot directly connect when() to step. Use: step %->% when(...) %->% step")
  } else {
    stop("Invalid workflow pipe operation: cannot connect ", 
         class(lhs)[1], " to ", class(rhs)[1])
  }
}

# Workflow Building Functions ===============================================

create_workflow_from_steps <- function(step1, step2) {
  workflow <- new_workflow()
  workflow <- add_step_to_workflow(workflow, step1)
  workflow <- add_step_to_workflow(workflow, step2)
  workflow
}

create_workflow_from_step <- function(step) {
  workflow <- new_workflow()
  workflow <- add_step_to_workflow(workflow, step)
  workflow
}

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
  base_name <- gsub("[^a-zA-Z0-9_]", "_", step$name)
  paste0(base_name, "_", workflow$.counter)
}

# Branching System ===========================================================

#' Create conditional branching in workflows
#' 
#' Creates a conditional branch point in a workflow where execution can
#' follow different paths based on a condition function.
#' 
#' @param condition_fn A function that takes the current data and returns
#'   a character vector of branch names to execute
#' @param ... Named arguments where names are branch names and values are
#'   workflow steps or sub-workflows
#' @return A workflow branching object
#' @export
when <- function(condition_fn, ...) {
  branches <- list(...)
  
  if (length(branches) == 0) {
    stop("when() requires at least one branch")
  }
  
  if (is.null(names(branches)) || any(names(branches) == "")) {
    stop("All branches in when() must be named")
  }
  
  structure(
    list(
      type = "conditional",
      condition = condition_fn,
      branches = branches
    ),
    class = "workflow_when"
  )
}

#' @export
print.workflow_when <- function(x, ...) {
  cat("Workflow conditional branch with", length(x$branches), "branches:\n")
  cat("Branches:", paste(names(x$branches), collapse = ", "), "\n")
  invisible(x)
}

add_branch_to_workflow <- function(workflow, when_obj) {
  # Create condition node
  condition_id <- generate_condition_id(workflow)
  condition_node <- structure(
    list(
      type = "condition", 
      condition_fn = when_obj$condition,
      branch_names = names(when_obj$branches)
    ),
    class = "workflow_condition_node"
  )
  
  # Add condition node
  workflow$nodes[[condition_id]] <- condition_node
  
  # Connect condition to current exits
  for (exit_id in workflow$current_exits) {
    workflow$edges <- append(workflow$edges, 
      list(list(from = exit_id, to = condition_id)))
  }
  
  # Process each branch (add branch nodes and edges internally)
  for (branch_name in names(when_obj$branches)) {
    branch_content <- when_obj$branches[[branch_name]]
    
    if (inherits(branch_content, "workflow_step")) {
      # Single step branch - add the step node and connect to condition
      result <- add_step_to_empty_workflow(workflow, branch_content)
      workflow <- result$workflow
      step_id <- result$step_id
      workflow$edges <- append(workflow$edges, 
        list(list(from = condition_id, to = step_id, branch = branch_name)))
    } else if (inherits(branch_content, "workflow")) {
      # Multi-step branch - merge the sub-workflow
      merge_result <- merge_branch_workflow(workflow, branch_content, condition_id, branch_name)
      workflow <- merge_result$workflow
    } else {
      stop("Branch content must be a workflow step or workflow")
    }
  }
  
  # CRITICAL FIX: when() node itself becomes the single exit point
  # This ensures the next step connects to when() once, not to each branch
  workflow$current_exits <- condition_id
  workflow
}

generate_condition_id <- function(workflow) {
  workflow$.counter <- workflow$.counter + 1L
  paste0("condition_", workflow$.counter)
}

add_step_to_empty_workflow <- function(workflow, step) {
  step_id <- generate_step_id(workflow, step)
  workflow$nodes[[step_id]] <- step
  list(workflow = workflow, step_id = step_id)
}

merge_branch_workflow <- function(main_workflow, branch_workflow, condition_id, branch_name) {
  # Add all nodes from branch workflow
  node_mapping <- list()
  for (node_id in names(branch_workflow$nodes)) {
    new_id <- paste0(branch_name, "_", node_id)
    main_workflow$nodes[[new_id]] <- branch_workflow$nodes[[node_id]]
    node_mapping[[node_id]] <- new_id
  }
  
  # Add edges from branch workflow with updated IDs
  for (edge in branch_workflow$edges) {
    new_edge <- list(
      from = node_mapping[[edge$from]],
      to = node_mapping[[edge$to]]
    )
    main_workflow$edges <- append(main_workflow$edges, list(new_edge))
  }
  
  # Connect condition to branch entry point
  if (!is.null(branch_workflow$entry_point)) {
    branch_entry <- node_mapping[[branch_workflow$entry_point]]
    main_workflow$edges <- append(main_workflow$edges,
      list(list(from = condition_id, to = branch_entry, branch = branch_name)))
  }
  
  # Return updated workflow and branch exits
  branch_exits <- sapply(branch_workflow$current_exits, function(id) node_mapping[[id]])
  list(workflow = main_workflow, exits = branch_exits)
}

# Workflow Execution ========================================================

#' Execute a workflow
#' 
#' Executes a workflow with the given input data, following the defined
#' execution flow including any conditional branching.
#' 
#' @param workflow A workflow object
#' @param input Initial input data
#' @return The result of workflow execution
#' @export
execute <- function(workflow, input) {
  UseMethod("execute")
}

#' @export
execute.workflow <- function(workflow, input) {
  if (is.null(workflow$entry_point)) {
    stop("Workflow has no entry point")
  }
  
  # Execute workflow using graph traversal
  execute_workflow_graph(workflow, input)
}

execute_workflow_graph <- function(workflow, input) {
  # Use recursive execution starting from entry point
  execute_node(workflow, workflow$entry_point, input)
}

execute_node <- function(workflow, node_id, input) {
  if (is.null(node_id) || length(node_id) == 0) {
    return(input)
  }
  
  node <- workflow$nodes[[node_id]]
  
  if (inherits(node, "workflow_condition_node")) {
    # Handle condition node - execute branches and return named list
    selected_branches <- node$condition_fn(input)
    
    # Get edges for selected branches
    condition_edges <- get_conditional_edges(workflow$edges, node_id, selected_branches)
    
    if (length(condition_edges) == 0) {
      return(list())  # No branches selected, return empty named list
    }
    
    # Execute all selected branches and collect results in named list
    branch_results <- list()
    for (edge in condition_edges) {
      branch_name <- edge$branch
      next_node_id <- edge$to
      branch_results[[branch_name]] <- execute_node(workflow, next_node_id, input)
    }
    
    # Always return named list (consistent behavior)
    return(branch_results)
  } else {
    # Regular step execution
    result <- execute_step(node, input)
    
    # Find next nodes
    next_edges <- get_outgoing_edges(workflow$edges, node_id)
    
    if (length(next_edges) == 0) {
      # End of workflow
      return(result)
    } else if (length(next_edges) == 1) {
      # Single next node
      next_node_id <- next_edges[[1]]$to
      return(execute_node(workflow, next_node_id, result))
    } else {
      # Multiple outgoing edges (shouldn't happen for regular steps)
      stop("Regular step has multiple outgoing edges: ", node_id)
    }
  }
}



execute_step <- function(step, input) {
  UseMethod("execute_step")
}

#' @export
execute_step.function_step <- function(step, input) {
  tryCatch({
    step$handler(input)
  }, error = function(e) {
    stop("Error in function step '", step$name, "': ", e$message)
  })
}

#' @export
execute_step.agent_step <- function(step, input) {
  tryCatch({
    # Convert input to message format if needed
    if (is.character(input) && length(input) == 1) {
      message <- new_message(input)
    } else {
      # For complex data, convert to string representation
      message <- new_message(paste(deparse(input), collapse = "\n"))
    }
    
    response <- request(step$handler, message)
    response$content
  }, error = function(e) {
    stop("Error in agent step '", step$name, "': ", e$message)
  })
}

# Utility Functions ==========================================================

get_outgoing_edges <- function(edges, node_id) {
  Filter(function(edge) edge$from == node_id, edges)
}

get_conditional_edges <- function(edges, condition_id, selected_branches) {
  condition_edges <- Filter(function(edge) {
    edge$from == condition_id && !is.null(edge$branch)
  }, edges)
  
  Filter(function(edge) edge$branch %in% selected_branches, condition_edges)
}

# Null-coalescing operator
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}