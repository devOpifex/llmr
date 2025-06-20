<div align="center">
<img src="man/figures/logo.png" />
</div>

An R package for interacting with Large Language Models (LLMs) with support for agents, workflows, and MCPs:
[Get Started](https://llmr.opifex.org/articles/get-started)

## Overview

llmr provides a streamlined interface to LLM providers like Anthropic's Claude and OpenAI. The package allows you to:

- Create and manage conversation history with LLMs
- Define agents with custom tools that LLMs can use
- Handle structured responses and tool calls
- Integrate with external tools via the mcpr package

## Installation

```r
pak::pak("devOpifex/llmr")
```

## Basic Usage

```r
library(llmr)

# Create a provider
provider <- new_anthropic()

# defaults to user role
message <- new_message("Explain quantum computing in simple terms")

# Send request and get response
request(provider, message)

# Print the last message
get_last_message(provider)
```

## Creating a Simple Agent

Note that we leverage the tooling from the [mcpr](https://github.com/devOpifex/mcpr)
package to create the tools,
though you may also use the tools from [ellmer](https://github.com/tidyverse/ellmer).
This allows seamless integration with MCP (Model Context Protocol) servers.

```r
library(llmr)

# Create a simple agent
agent <- new_agent("calculator", new_anthropic)

# Add a calculator tool to the agent
add_tool(
  agent,
  mcpr::new_tool(
    name = "weather",
    description = "Get the weather forecast for a given location",
    input_schema = mcpr::schema(
      properties = mcpr::properties(
        location = mcpr::property_string(
          title = "Location",
          description = "The location for which you want the weather forecast",
          required = TRUE
        )
      )
    ),
    handler = function(params) {
      sprintf("The weather forecast for %s is dark and rainy", params$location)
    }
  )
)

# Make a request to the LLM
request(
  agent,
  new_message("What is the weather in Switzerland?")
)

# Print the response
get_last_message(agent)
```

## Integrating with MCP (Model Context Protocol)

See [mcpr](https://github.com/devOpifex/mcpr) for how to create and use MCP
servers (and clients).

```r
library(llmr)
library(mcpr)

# Create a provider
agent <- new_agent("mcp", new_anthropic)

# Create an MCP client that connects to an external calculator service
client <- mcpr::new_client(
  command = "Rscript",
  args = "/path/to/server.R",
  name = "calculator"
)

# Register the MCP with the provider
register_mcp(agent, client)

# Make a request
request(
  agent, 
  new_message("Subtract 5 from 10.")
)

# Print the response
get_last_message(agent)
```

## Workflows

Chain together processing steps and agents into workflows:

```r
library(llmr)

# Define processing functions
add_ten <- function(x) x + 10
multiply_two <- function(x) x * 2

# Create workflow steps
step1 <- step(add_ten)
step2 <- step(multiply_two)

# Chain steps together
workflow <- step1 %->% step2

# Execute workflow
result <- execute(workflow, 5)  # Returns 30: (5 + 10) * 2
```

## Configuration

Methods for `agent` exists too.

```r
# Set a different model
set_model(provider, "claude-3-haiku-20240307")

# Set max tokens for response
set_max_tokens(provider, 1024)

# Set API version
set_version(provider, "2023-06-01")

# Set temperature for response randomness (0.0 to 1.0)
set_temperature(provider, 0.7)

# Set system prompt
set_system_prompt(provider, "You are a helpful assistant that specializes in R programming.")
```
