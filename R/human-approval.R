#' Interactive human approval prompt for tool execution
#'
#' A default implementation of a human approval callback that prompts the user
#' interactively to approve or deny tool execution.
#'
#' @param tool_info A list containing tool information with elements:
#'   - `name`: The name of the tool being called
#'   - `arguments`: A list of arguments passed to the tool
#'   - `id`: The unique identifier for this tool call
#'
#' @return `TRUE` if approved, `FALSE` if denied
#' @export
#'
#' @examples
#' \dontrun{
#' # Set up an agent with interactive approval
#' agent <- new_agent("assistant", ellmer::chat_anthropic) |>
#'   set_approval_callback(prompt_human_approval)
#' }
prompt_human_approval <- function(tool_info) {
  cat("\n")
  cat("[AGENT] Agent wants to use tool:", tool_info$name, "\n")
  cat("[ARGS] Arguments:\n")

  # Pretty print arguments
  if (length(tool_info$arguments) == 0) {
    cat("  (no arguments)\n")
  } else {
    for (arg_name in names(tool_info$arguments)) {
      arg_value <- tool_info$arguments[[arg_name]]
      if (is.character(arg_value) && length(arg_value) == 1) {
        cat("  ", arg_name, ":", arg_value, "\n")
      } else {
        cat(
          "  ",
          arg_name,
          ":",
          utils::capture.output(utils::str(arg_value, max.level = 1)),
          "\n"
        )
      }
    }
  }

  cat("\n")
  response <- readline("[?] Approve this tool call? (y/n/details): ")

  switch(
    tolower(trimws(response)),
    "y" = TRUE,
    "yes" = TRUE,
    "n" = FALSE,
    "no" = FALSE,
    "details" = {
      show_tool_details(tool_info)
      prompt_human_approval(tool_info)
    },
    {
      cat("Please respond with y/n/details\n")
      prompt_human_approval(tool_info)
    }
  )
}

#' Show detailed information about a tool call
#'
#' @param tool_info A list containing tool information
#' @keywords internal
show_tool_details <- function(tool_info) {
  cat("\n=== Tool Call Details ===\n")
  cat("Tool Name:", tool_info$name, "\n")
  cat("Call ID:", tool_info$id, "\n")
  cat("\nArguments (detailed):\n")

  if (length(tool_info$arguments) == 0) {
    cat("  (no arguments)\n")
  } else {
    utils::str(tool_info$arguments)
  }

  cat("\n")
}

#' Batch approval interface for multiple tool calls
#'
#' A more advanced approval callback that can handle multiple tool calls
#' and provides batch approval options.
#'
#' @param tool_info A list containing tool information
#'
#' @return `TRUE` if approved, `FALSE` if denied, or a character string with denial reason
#' @export
batch_approval_interface <- function(tool_info) {
  cat("\n")
  cat("[TOOL] Tool Call Request\n")
  cat("Tool:", tool_info$name, "\n")

  # Show a summary of arguments
  if (length(tool_info$arguments) > 0) {
    arg_summary <- paste(names(tool_info$arguments), collapse = ", ")
    cat("Args:", arg_summary, "\n")
  }

  cat("\n")
  response <- readline(
    "Action? (y)es/(n)o/(d)etails/(a)lways approve this tool/(b)lock this tool: "
  )

  switch(
    tolower(trimws(response)),
    "y" = TRUE,
    "yes" = TRUE,
    "n" = FALSE,
    "no" = FALSE,
    "d" = {
      show_tool_details(tool_info)
      batch_approval_interface(tool_info)
    },
    "details" = {
      show_tool_details(tool_info)
      batch_approval_interface(tool_info)
    },
    "a" = {
      # Store approval for this tool type
      store_tool_approval(tool_info$name, approved = TRUE)
      TRUE
    },
    "always" = {
      store_tool_approval(tool_info$name, approved = TRUE)
      TRUE
    },
    "b" = {
      # Store denial for this tool type
      store_tool_approval(tool_info$name, approved = FALSE)
      paste("Tool", tool_info$name, "is blocked by user preference")
    },
    "block" = {
      store_tool_approval(tool_info$name, approved = FALSE)
      paste("Tool", tool_info$name, "is blocked by user preference")
    },
    {
      cat("Please respond with y/n/d/a/b\n")
      batch_approval_interface(tool_info)
    }
  )
}

# Simple in-memory storage for tool approvals (could be enhanced to persist)
.tool_approvals <- new.env(parent = emptyenv())

#' Store tool approval preference
#'
#' @param tool_name Name of the tool
#' @param approved Whether the tool is approved
#' @keywords internal
store_tool_approval <- function(tool_name, approved) {
  .tool_approvals[[tool_name]] <- approved
  if (approved) {
    cat("[+] Tool", tool_name, "will be auto-approved in future\n")
  } else {
    cat("[-] Tool", tool_name, "will be auto-blocked in future\n")
  }
}

#' Check if tool has stored approval preference
#'
#' @param tool_name Name of the tool
#' @return `TRUE`, `FALSE`, or `NULL` if no preference stored
#' @keywords internal
check_tool_approval <- function(tool_name) {
  if (exists(tool_name, envir = .tool_approvals)) {
    .tool_approvals[[tool_name]]
  } else {
    NULL
  }
}

#' Smart approval callback that uses stored preferences
#'
#' An intelligent approval callback that remembers user preferences for
#' specific tools and only prompts for new or unrecognized tools.
#'
#' @param tool_info A list containing tool information
#'
#' @return `TRUE` if approved, `FALSE` if denied, or a character string with denial reason
#' @export
smart_approval_callback <- function(tool_info) {
  # Check if we have a stored preference for this tool
  stored_approval <- check_tool_approval(tool_info$name)

  if (!is.null(stored_approval)) {
    if (stored_approval) {
      cat("[+] Auto-approving tool:", tool_info$name, "\n")
      return(TRUE)
    } else {
      cat("[-] Auto-blocking tool:", tool_info$name, "\n")
      return(paste("Tool", tool_info$name, "is blocked by user preference"))
    }
  }

  # No stored preference, prompt user
  batch_approval_interface(tool_info)
}

#' Clear all stored tool approval preferences
#'
#' @export
clear_tool_approvals <- function() {
  rm(list = ls(.tool_approvals), envir = .tool_approvals)
  cat("[CLEAR] Cleared all tool approval preferences\n")
}

#' List current tool approval preferences
#'
#' @export
list_tool_approvals <- function() {
  if (length(ls(.tool_approvals)) == 0) {
    cat("No tool approval preferences stored\n")
    return(invisible(NULL))
  }

  cat("Current tool approval preferences:\n")
  for (tool_name in ls(.tool_approvals)) {
    status <- if (.tool_approvals[[tool_name]]) "[+] APPROVED" else "[-] BLOCKED"
    cat("  ", tool_name, ":", status, "\n")
  }
}

