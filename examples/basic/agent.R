devtools::load_all()

provider <- new_anthropic()

agent <- new_agent("A calculator", provider)

calculator <- mcpr::new_tool(
  name = "calculator",
  description = "Performs basic arithmetic operations",
  input_schema = mcpr::schema(
    properties = mcpr::properties(
      operation = mcpr::property_enum(
        "Operation",
        "Math operation to perform",
        values = c("add", "subtract", "multiply", "divide"),
        required = TRUE
      ),
      a = mcpr::property_number(
        "First number",
        "First operand",
        required = TRUE
      ),
      b = mcpr::property_number(
        "Second number",
        "Second operand",
        required = TRUE
      )
    )
  ),
  handler = function(params) {
    result <- switch(
      params$operation,
      "add" = params$a + params$b,
      "subtract" = params$a - params$b,
      "multiply" = params$a * params$b,
      "divide" = params$a / params$b
    )
    mcpr::response_text(result)
  }
)

agent <- add_tool(agent, calculator)

request(agent, new_message("What is 15 multiplied by 7?"))
get_last_message(agent)
