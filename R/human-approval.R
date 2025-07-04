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
  log_info("Agent wants to use tool: %s", tool_info$name)
  log_plain("[ARGS] Arguments:")

  # Pretty print arguments
  if (length(tool_info$arguments) == 0) {
    log_plain("  (no arguments)")
  } else {
    for (arg_name in names(tool_info$arguments)) {
      arg_value <- tool_info$arguments[[arg_name]]
      if (is.character(arg_value) && length(arg_value) == 1) {
        log_plain("  ", arg_name, ":", arg_value)
      } else {
        log_plain(
          "  ",
          arg_name,
          ":",
          utils::capture.output(utils::str(arg_value, max.level = 1))
        )
      }
    }
  }

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
      log_warn("Please respond with y/n/details")
      prompt_human_approval(tool_info)
    }
  )
}

#' Show detailed information about a tool call
#'
#' @param tool_info A list containing tool information
#' @keywords internal
show_tool_details <- function(tool_info) {
  log_plain("=== Tool Call Details ===")
  log_plain("Tool Name:", tool_info$name)
  log_plain("Call ID:", tool_info$id)
  log_plain("Arguments (detailed):")

  if (length(tool_info$arguments) == 0) {
    log_plain("  (no arguments)")
  } else {
    utils::str(tool_info$arguments)
  }
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
  log_info("Tool Call Request")
  log_plain("Tool:", tool_info$name)

  # Show a summary of arguments
  if (length(tool_info$arguments) > 0) {
    arg_summary <- paste(names(tool_info$arguments), collapse = ", ")
    log_plain("Args:", arg_summary)
  }

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
      log_warn("Please respond with y/n/d/a/b")
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
    log_status("Tool %s will be auto-approved in future", tool_name)
  } else {
    log_status("Tool %s will be auto-blocked in future", tool_name)
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
      log_status("Auto-approving tool: %s", tool_info$name)
      return(TRUE)
    } else {
      log_status("Auto-blocking tool: %s", tool_info$name)
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
  log_system("Cleared all tool approval preferences")
}

#' List current tool approval preferences
#'
#' @export
list_tool_approvals <- function() {
  if (length(ls(.tool_approvals)) == 0) {
    log_system("No tool approval preferences stored")
    return(invisible(NULL))
  }

  log_system("Current tool approval preferences:")
  for (tool_name in ls(.tool_approvals)) {
    status <- if (.tool_approvals[[tool_name]]) {
      "[+] APPROVED"
    } else {
      "[-] BLOCKED"
    }
    log_plain("  ", tool_name, ":", status)
  }
}
