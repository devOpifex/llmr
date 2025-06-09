# llmr

An R package for interacting with Large Language Models (LLMs).

## Installation

```r
pak::pak("devOpifex/llmr")
```

## Features

- Provider-based architecture supporting multiple LLM providers
- Default support for Anthropic Claude and OpenAI models
- Conversation management
- Simple, pipe-friendly interface
- Configurable API settings

## Quick Start with Anthropic

```r
library(llmr)

# Set your Anthropic API key
set_token("your-api-key") 
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
clear_messages()
```

## Configuration

```r
# Set a different model
set_model(provider, "claude-3-haiku-20240307")

# Set max tokens for response
set_max_tokens(provider, 1024)

# Set API version
set_version(provider, "2023-06-01")
```

## License

[Add license information]
