#' Create a new agent
#'
#' Create a new agent object that can be used to invoke tools and process responses.
#'
#' @param name Character string for the agent name
#' @param description Character string describing the agent's purpose
#' @param tools List of tool objects the agent can use
#' @param ... Additional parameters passed to the agent
#'
#' @return An object of class 'agent'
#' @export
#'
#' @examples
#' \dontrun{
#' agent <- new_agent(
#'   name = "research_assistant",
#'   description = "Helps with research tasks",
#'   tools = list()
#' )
#' }
new_agent <- function(name, description, tools = list(), ...) {
  stopifnot(
    is.character(name),
    is.character(description),
    is.list(tools)
  )

  agent <- structure(
    list(
      name = name,
      description = description,
      tools = tools,
      ...
    ),
    class = c("agent", "list")
  )

  return(agent)
}
