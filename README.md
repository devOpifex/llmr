# llmr

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

# Create a message
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
  name = "calculate",
  description = "Performs basic arithmetic calculations",
  parameters = list(
    expression = list(
      type = "string", 
      description = "The mathematical expression to evaluate"
    )
  ),
  handler = function(params) {
    result <- eval(parse(text = params$expression))
    return(as.character(result))
  }
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

```r
library(llmr)
library(mcpr)

# Set your API key
set_api_key("your_anthropic_api_key")

# Create a provider
provider <- new_anthropic()

# Create an MCP client that connects to an external calculator service
calculator_client <- mcpr::new_client(
  command = "Rscript",
  args = c("-e", "mcpr::serve()"),
  name = "calculator"
)

# Register the MCP with the provider
provider <- register_mcp(provider, calculator_client)

# Make a request using the external calculator
response <- request(
  provider,
  new_message("What is the square root of 144?")
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