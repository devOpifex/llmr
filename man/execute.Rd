% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/workflow.R
\name{execute}
\alias{execute}
\title{Execute a workflow}
\usage{
execute(workflow, input)
}
\arguments{
\item{workflow}{A workflow object}

\item{input}{Initial input data}
}
\value{
The result of workflow execution
}
\description{
Executes a workflow with the given input data, following the defined
execution flow including any conditional branching.
}
