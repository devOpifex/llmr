devtools::load_all()

provider <- new_anthropic()

client <- mcpr::new_client(
  command = "Rscript",
  args = "/home/john/Opifex/Packages/llmr/examples/mcp/server.R",
  name = "calculator"
)

register_mcp(provider, client)

request(provider, new_message("Substract 3 from 45"))
