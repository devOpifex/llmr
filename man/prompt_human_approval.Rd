% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/human-approval.R
\name{prompt_human_approval}
\alias{prompt_human_approval}
\title{Interactive human approval prompt for tool execution}
\usage{
prompt_human_approval(tool_info)
}
\arguments{
\item{tool_info}{A list containing tool information with elements:
\itemize{
\item \code{name}: The name of the tool being called
\item \code{arguments}: A list of arguments passed to the tool
\item \code{id}: The unique identifier for this tool call
}}
}
\value{
\code{TRUE} if approved, \code{FALSE} if denied
}
\description{
A default implementation of a human approval callback that prompts the user
interactively to approve or deny tool execution.
}
\examples{
\dontrun{
# Set up an agent with interactive approval
agent <- new_agent("assistant", ellmer::chat_anthropic) |>
  set_approval_callback(prompt_human_approval)
}
}
