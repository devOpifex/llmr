<div align="center">
<img src="man/figures/logo.png" />
</div>

An R package for interacting with Large Language Models (LLMs) with support for tools and agents.

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

# Set your Anthropic API key
set_api_key("your-api-key") 
# Or use ANTHROPIC_API_KEY environment variable

# Create a provider
provider <- new_anthropic()

# defaults to user role
message <- new_message("Explain quantum computing in simple terms")

# Send request and get response
response <- request(provider, message)

# Print the response
cat(response$content)

# Continue the conversation
message <- new_message("Now give me a simple code example")
response <- request(provider, message)
cat(response$content)

# Clear conversation history
clear_messages(provider)
```

## Creating a Simple Agent

Note that we leverage the tooling from the [mcpr](https://github.com/devOpifex/mcpr)
package to create the tools.
This allows seamless integration with MCP (Model Context Protocol) servers.

```r
library(llmr)

# Set your API key
set_api_key("your_anthropic_api_key")

# Create a provider (default is Anthropic)
provider <- new_anthropic()

# Create a simple agent
agent <- new_agent("calculator")

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

# Register the agent with the provider
provider <- register_agent(provider, agent)

# Make a request to the LLM
response <- request(
  provider,
  new_message("What is 123 * 456? Please use the calculate tool.")
)

# Print the response
cat(response$content)
```

## Integrating with MCP (Model Context Protocol)

See [mcpr](https://github.com/devOpifex/mcpr) for how to create and use MCP
servers (and clients).

```r
library(llmr)
library(mcpr)

# Set your API key
set_api_key("your_anthropic_api_key")

# Create a provider
provider <- new_anthropic()

# Create an MCP client that connects to an external calculator service
client <- mcpr::new_client(
  command = "Rscript",
  args = "/path/to/server.R",
  name = "calculator"
)

# Register the MCP with the provider
register_mcp(provider, client)

# Make a request
response <- request(
  provider, 
  new_message("Subtract 5 from 10.")
)

# Print the response
cat(response$content)
```

## Configuration

```r
# Set a different model
set_model(provider, "claude-3-haiku-20240307")

# Set max tokens for response
set_max_tokens(provider, 1024)

# Set API version
set_version(provider, "2023-06-01")

# Set system prompt
set_system_prompt(provider, "You are a helpful assistant that specializes in R programming.")
```
