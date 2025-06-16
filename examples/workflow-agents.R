devtools::load_all()

cat("=== Workflow with Agents Example ===\n")

# Set API key (you'll need to set this)
# set_api_key("your-anthropic-api-key")

# Create provider
provider <- new_anthropic()

# Create agents with different specializations
summarizer <- new_agent("summarizer", provider)
analyzer <- new_agent("analyzer", provider)
formatter <- new_agent("formatter", provider)

# Set system prompts for each agent
set_system_prompt(
  summarizer$provider,
  "You are a text summarizer. Provide concise summaries."
)
set_system_prompt(
  analyzer$provider,
  "You are a sentiment analyzer. Analyze the emotional tone."
)
set_system_prompt(
  formatter$provider,
  "You are a formatter. Format text into structured output."
)

# Create workflow steps from agents
summary_step <- step(summarizer, name = "summarize")
analysis_step <- step(analyzer, name = "analyze_sentiment")
format_step <- step(formatter, name = "format_output")

# Create a linear workflow: summarize -> analyze -> format
agent_workflow <- summary_step %->% analysis_step %->% format_step

cat("Created agent workflow:\n")
print(agent_workflow)

# Example with conditional branching based on text length
text_router <- function(text) {
  word_count <- length(strsplit(text, "\\s+")[[1]])
  if (word_count > 100) {
    "long"
  } else {
    "short"
  }
}

# Create different processing paths
short_processor <- new_agent("short_processor", provider)
long_processor <- new_agent("long_processor", provider)

set_system_prompt(
  short_processor,
  "Process short text quickly with very brief analysis."
)
set_system_prompt(
  long_processor,
  "Process long text thoroughly with detailed analysis."
)

# Create a preprocessing step
preprocessor <- function(text) {
  cat("Preprocessing text:", substr(text, 1, 50), "...\n")
  text
}

# Create branching workflow - must start with a step
branching_workflow <- step(preprocessor, name = "preprocess") %->%
  when(
    text_router,
    short = step(short_processor, name = "quick_process"),
    long = step(long_processor, name = "detailed_process")
  ) %->%
  step(formatter, name = "final_format")

cat("\nCreated branching agent workflow:\n")
print(branching_workflow)

# Example execution (commented out since it requires API key)
# sample_text <- "This is a sample text for processing through our agent workflow."
# cat("\nExecuting workflow with sample text...\n")
# result <- execute(agent_workflow, sample_text)
# cat("Result:", result, "\n")

cat("\nTo run this example:\n")
cat("1. Set your API key: set_api_key('your-key')\n")
cat("2. Execute: result <- execute(agent_workflow, 'your text here')\n")

result <- execute(agent_workflow, "This is some text")

print(result)
