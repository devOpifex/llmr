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

# Create an agent with ellmer chat object directly (recommended)
agent <- new_agent("assistant", ellmer::chat_anthropic())

# Send request and get response
request(agent, new_message("Explain quantum computing in simple terms"))

# Print the last message
get_last_message(agent)
```

### Legacy Provider Support

The original provider API is still supported but deprecated:

```r
# Legacy API (deprecated)
provider <- new_anthropic()  # Will show deprecation warning
agent <- new_agent("assistant", provider)
```

## Creating a Simple Agent

Note that we leverage the tooling from the [mcpr](https://github.com/devOpifex/mcpr)
package to create the tools,
though you may also use the tools from [ellmer](https://github.com/tidyverse/ellmer).
This allows seamless integration with MCP (Model Context Protocol) servers.

```r
library(llmr)

# Create a simple agent with ellmer chat object
agent <- new_agent("calculator", ellmer::chat_anthropic())

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

## ellmer Providers (Recommended)

llmr now supports [ellmer](https://ellmer.tidyverse.org) as the underlying provider implementation, offering significant advantages:

- **15+ provider support** (Anthropic, OpenAI, Google Gemini, AWS Bedrock, Ollama, and more)
- **Advanced features**: streaming, async operations, structured data extraction
- **Better performance** and professional maintenance by the tidyverse team

```r
# Multiple providers available - use ellmer chat objects directly
anthropic_agent <- new_agent("claude", ellmer::chat_anthropic())
openai_agent <- new_agent("gpt", ellmer::chat_openai())
gemini_agent <- new_agent("gemini", ellmer::chat_google_gemini())

# Advanced ellmer features - access the underlying chat object
chat <- anthropic_agent$provider$chat

# Streaming responses
chat$chat("Tell me a story", echo = "output")

# Structured data extraction
data <- chat$chat_structured(
  "Extract: John Doe, age 30, lives in NYC",
  type = ellmer::type_object(
    name = ellmer::type_string("Person's name"),
    age = ellmer::type_integer("Person's age"),
    city = ellmer::type_string("City")
  )
)
```

## Configuration

Configuration methods work with both provider types:

```r
# Configure ellmer chat objects directly (recommended)
agent <- new_agent("assistant", ellmer::chat_anthropic(
  model = "claude-3-haiku-20240307",
  params = ellmer::params(
    temperature = 0.7,
    max_tokens = 1024
  ),
  system_prompt = "You are a helpful assistant that specializes in R programming."
))

# Legacy provider configuration still works (deprecated)
provider <- new_anthropic() |>
  set_model("claude-3-haiku-20240307") |>
  set_max_tokens(1024) |>
  set_temperature(0.7)
```
