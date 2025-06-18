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
  cat("Nodes:", length(x$nodes), "| Edges:", length(x$edges), "\n\n")

  # Generate ASCII diagram
  diagram <- generate_workflow_diagram(x)
  cat(diagram)
  cat("\n")

  invisible(x)
}

# ASCII Diagram Generation ===================================================

generate_workflow_diagram <- function(workflow) {
  if (length(workflow$nodes) == 0) {
    return("(empty workflow)")
  }

  # Build execution order using topological sort
  execution_order <- topological_sort(workflow)

  if (length(execution_order) == 0) {
    return("(no executable path found)")
  }

  # Generate diagram lines
  lines <- character()

  for (i in seq_along(execution_order)) {
    node_id <- execution_order[i]
    node <- workflow$nodes[[node_id]]

    # Format node display
    node_display <- format_node_for_diagram(node, node_id)

    # Add node line
    if (i == 1) {
      lines <- c(lines, paste0("\u250c\u2500 ", node_display))
    } else {
      lines <- c(lines, "\u2502")
      lines <- c(lines, paste0("\u251c\u2500 ", node_display))
    }

    # Add branch information for condition nodes
    if (inherits(node, "workflow_condition_node")) {
      branch_lines <- format_branches_for_diagram(workflow, node_id)
      lines <- c(lines, branch_lines)
    }
  }

  # Close the diagram
  if (length(lines) > 0) {
    lines[length(lines)] <- gsub(
      "\u251c\u2500",
      "\u2514\u2500",
      lines[length(lines)]
    )
  }

  paste(lines, collapse = "\n")
}

format_node_for_diagram <- function(node, node_id) {
  if (inherits(node, "workflow_condition_node")) {
    branches <- paste(node$branch_names, collapse = ", ")
    paste0("\U0001f500 when(", branches, ")")
  } else if (inherits(node, "workflow_step")) {
    icon <- if (node$type == "agent") "\U0001f916" else "\u2699\ufe0f"
    paste0(icon, " ", node$name)
  } else {
    paste0("\u2753 ", node_id)
  }
}

format_branches_for_diagram <- function(workflow, condition_id) {
  # Find all edges from this condition
  condition_edges <- Filter(
    function(edge) {
      edge$from == condition_id && !is.null(edge$branch)
    },
    workflow$edges
  )

  if (length(condition_edges) == 0) {
    return(character())
  }

  branch_lines <- character()
  for (i in seq_along(condition_edges)) {
    edge <- condition_edges[[i]]
    target_node <- workflow$nodes[[edge$to]]
    target_display <- format_node_for_diagram(target_node, edge$to)

    if (i == length(condition_edges)) {
      branch_lines <- c(
        branch_lines,
        paste0("\u2502   \u2514\u2500 ", edge$branch, ": ", target_display)
      )
    } else {
      branch_lines <- c(
        branch_lines,
        paste0("\u2502   \u251c\u2500 ", edge$branch, ": ", target_display)
      )
    }
  }

  branch_lines
}

topological_sort <- function(workflow) {
  if (is.null(workflow$entry_point)) {
    return(character())
  }

  # Simple traversal from entry point (works for most workflow patterns)
  visited <- character()
  result <- character()

  traverse_node <- function(node_id) {
    if (node_id %in% visited) {
      return()
    }

    visited <<- c(visited, node_id)
    result <<- c(result, node_id)

    # Find outgoing edges (non-branch edges for regular flow)
    outgoing <- Filter(
      function(edge) {
        edge$from == node_id && is.null(edge$branch)
      },
      workflow$edges
    )

    for (edge in outgoing) {
      traverse_node(edge$to)
    }
  }

  traverse_node(workflow$entry_point)
  result
}

# Step System ================================================================

#' Create a workflow step
#'
#' Creates a step that can be used in workflows. Steps can wrap functions
#' or agents to provide processing capabilities.
#'
#' @param x An agent or function to use as a step
#' @param ... Additional arguments
#' @return A workflow step object
#' @export
step <- function(x, ...) {
  UseMethod("step")
}

#' @export
step.function <- function(x, name = NULL, ...) {
  structure(
    list(
      type = "function",
      handler = x,
      name = name %||% deparse(substitute(x))
    ),
    class = c("workflow_step", "function_step")
  )
}

#' @export
step.agent <- function(x, name = NULL, ...) {
  structure(
    list(
      type = "agent",
      handler = x,
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
#' steps to steps, steps to workflows, workflows to steps, or start workflows
#' with conditional branching.
#'
#' @param lhs Left-hand side (step, workflow, or when)
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
    # NEW: when() %->% step: create workflow starting with conditional
    create_workflow_from_when(lhs, rhs)
  } else if (inherits(lhs, "workflow_when") && inherits(rhs, "workflow")) {
    # NEW: when() %->% workflow: merge conditional with workflow
    create_workflow_from_when(lhs, rhs)
  } else {
    stop(
      "Invalid workflow pipe operation: cannot connect ",
      class(lhs)[1],
      " to ",
      class(rhs)[1]
    )
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
    workflow$edges <- append(
      workflow$edges,
      list(list(from = exit_id, to = step_id))
    )
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

# When-First Workflow Functions =============================================

create_workflow_from_when <- function(when_obj, next_element) {
  workflow <- new_workflow()

  # Add when() as the entry point
  workflow <- add_when_as_entry_point(workflow, when_obj)

  # Connect to next element
  if (inherits(next_element, "workflow_step")) {
    workflow <- add_step_to_workflow(workflow, next_element)
  } else if (inherits(next_element, "workflow")) {
    workflow <- merge_workflow_after_when(workflow, next_element)
  }

  workflow
}

add_when_as_entry_point <- function(workflow, when_obj) {
  # Create condition node as entry point
  condition_id <- generate_condition_id(workflow)
  condition_node <- structure(
    list(
      type = "condition",
      condition_fn = when_obj$condition,
      branch_names = names(when_obj$branches)
    ),
    class = "workflow_condition_node"
  )

  # Set as entry point and add branches
  workflow$nodes[[condition_id]] <- condition_node
  workflow$entry_point <- condition_id

  # Process branches (similar to existing add_branch_to_workflow logic)
  for (branch_name in names(when_obj$branches)) {
    branch_content <- when_obj$branches[[branch_name]]

    if (inherits(branch_content, "workflow_step")) {
      result <- add_step_to_empty_workflow(workflow, branch_content)
      workflow <- result$workflow
      step_id <- result$step_id
      workflow$edges <- append(
        workflow$edges,
        list(list(from = condition_id, to = step_id, branch = branch_name))
      )
    } else if (inherits(branch_content, "workflow")) {
      merge_result <- merge_branch_workflow(
        workflow,
        branch_content,
        condition_id,
        branch_name
      )
      workflow <- merge_result$workflow
    }
  }

  # CRITICAL: condition node itself becomes the exit point
  # This matches the existing add_branch_to_workflow behavior
  workflow$current_exits <- condition_id
  workflow
}

merge_workflow_after_when <- function(main_workflow, next_workflow) {
  # Connect all current exits (branch endpoints) to next workflow's entry
  if (!is.null(next_workflow$entry_point)) {
    # Add all nodes from next workflow with new IDs
    node_mapping <- list()
    for (node_id in names(next_workflow$nodes)) {
      new_id <- paste0("next_", node_id)
      main_workflow$nodes[[new_id]] <- next_workflow$nodes[[node_id]]
      node_mapping[[node_id]] <- new_id
    }

    # Add edges from next workflow
    for (edge in next_workflow$edges) {
      new_edge <- list(
        from = node_mapping[[edge$from]],
        to = node_mapping[[edge$to]]
      )
      if (!is.null(edge$branch)) {
        new_edge$branch <- edge$branch
      }
      main_workflow$edges <- append(main_workflow$edges, list(new_edge))
    }

    # Connect current exits to next workflow entry
    next_entry <- node_mapping[[next_workflow$entry_point]]
    for (exit_id in main_workflow$current_exits) {
      main_workflow$edges <- append(
        main_workflow$edges,
        list(list(from = exit_id, to = next_entry))
      )
    }

    # Update current exits
    main_workflow$current_exits <- sapply(
      next_workflow$current_exits,
      function(id) node_mapping[[id]]
    )
  }

  main_workflow
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
    workflow$edges <- append(
      workflow$edges,
      list(list(from = exit_id, to = condition_id))
    )
  }

  # Process each branch (add branch nodes and edges internally)
  for (branch_name in names(when_obj$branches)) {
    branch_content <- when_obj$branches[[branch_name]]

    if (inherits(branch_content, "workflow_step")) {
      # Single step branch - add the step node and connect to condition
      result <- add_step_to_empty_workflow(workflow, branch_content)
      workflow <- result$workflow
      step_id <- result$step_id
      workflow$edges <- append(
        workflow$edges,
        list(list(from = condition_id, to = step_id, branch = branch_name))
      )
    } else if (inherits(branch_content, "workflow")) {
      # Multi-step branch - merge the sub-workflow
      merge_result <- merge_branch_workflow(
        workflow,
        branch_content,
        condition_id,
        branch_name
      )
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

merge_branch_workflow <- function(
  main_workflow,
  branch_workflow,
  condition_id,
  branch_name
) {
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
    main_workflow$edges <- append(
      main_workflow$edges,
      list(list(from = condition_id, to = branch_entry, branch = branch_name))
    )
  }

  # Return updated workflow and branch exits
  branch_exits <- sapply(branch_workflow$current_exits, function(id) {
    node_mapping[[id]]
  })
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

#' @export
execute.workflow_when <- function(workflow, input) {
  # Execute the condition function to determine branches
  selected_branches <- workflow$condition(input)

  if (length(selected_branches) == 0) {
    return(list()) # No branches selected
  }

  # Execute all selected branches and collect results
  branch_results <- list()
  for (branch_name in selected_branches) {
    if (branch_name %in% names(workflow$branches)) {
      branch_content <- workflow$branches[[branch_name]]
      if (inherits(branch_content, "workflow_step")) {
        branch_results[[branch_name]] <- execute_step(branch_content, input)
      } else if (inherits(branch_content, "workflow")) {
        branch_results[[branch_name]] <- execute(branch_content, input)
      }
    }
  }

  branch_results
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

  # Log node execution start
  node_name <- if (!is.null(node$name)) node$name else node_id
  log("workflow", "Executing node: %s", node_name)

  if (inherits(node, "workflow_condition_node")) {
    # Handle condition node - execute branches and return named list
    selected_branches <- node$condition_fn(input)
    log(
      "workflow",
      "Condition node '%s' selected branches: %s",
      node_name,
      paste(selected_branches, collapse = ", ")
    )

    # Get edges for selected branches
    condition_edges <- get_conditional_edges(
      workflow$edges,
      node_id,
      selected_branches
    )

    if (length(condition_edges) == 0) {
      log("workflow", "No branches selected for condition node '%s'", node_name)
      branch_results <- list() # No branches selected, return empty named list
    } else {
      # Execute all selected branches and collect results in named list
      branch_results <- list()
      for (edge in condition_edges) {
        branch_name <- edge$branch
        next_node_id <- edge$to
        log(
          "workflow",
          "Executing branch '%s' -> node '%s'",
          branch_name,
          next_node_id
        )
        branch_results[[branch_name]] <- execute_node(
          workflow,
          next_node_id,
          input
        )
      }
    }

    # Check for non-branch outgoing edges (subsequent steps)
    next_edges <- get_outgoing_edges(workflow$edges, node_id)
    non_branch_edges <- Filter(function(edge) is.null(edge$branch), next_edges)

    if (length(non_branch_edges) == 0) {
      # No subsequent steps, return branch results
      branch_results
    } else if (length(non_branch_edges) == 1) {
      # Single subsequent step - pass branch results to it
      next_node_id <- non_branch_edges[[1]]$to
      execute_node(workflow, next_node_id, branch_results)
    } else {
      # Multiple subsequent steps (shouldn't happen)
      stop("Condition node has multiple non-branch outgoing edges: ", node_id)
    }
  } else {
    # Regular step execution
    result <- execute_step(node, input)

    # Find next nodes
    next_edges <- get_outgoing_edges(workflow$edges, node_id)

    if (length(next_edges) == 0) {
      # End of workflow
      result
    } else if (length(next_edges) == 1) {
      # Single next node
      next_node_id <- next_edges[[1]]$to
      execute_node(workflow, next_node_id, result)
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
  tryCatch(
    {
      step$handler(input)
    },
    error = function(e) {
      stop("Error in function step '", step$name, "': ", e$message)
    }
  )
}

#' @export
execute_step.agent_step <- function(step, input) {
  tryCatch(
    {
      # Convert input to message format if needed
      if (is.character(input) && length(input) == 1) {
        message <- new_message(input)
      } else {
        # For complex data, convert to string representation
        message <- new_message(paste(deparse(input), collapse = "\n"))
      }

      response <- request(step$handler, message)
      # Extract content from the last message in the agent's conversation
      messages <- response$env$messages
      if (length(messages) > 0) {
        last_message <- messages[[length(messages)]]
        last_message$content
      } else {
        NULL
      }
    },
    error = function(e) {
      stop("Error in agent step '", step$name, "': ", e$message)
    }
  )
}

# Utility Functions ==========================================================

get_outgoing_edges <- function(edges, node_id) {
  Filter(function(edge) edge$from == node_id, edges)
}

get_conditional_edges <- function(edges, condition_id, selected_branches) {
  condition_edges <- Filter(
    function(edge) {
      edge$from == condition_id && !is.null(edge$branch)
    },
    edges
  )

  Filter(function(edge) edge$branch %in% selected_branches, condition_edges)
}

# Null-coalescing operator
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
