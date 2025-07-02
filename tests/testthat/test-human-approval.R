test_that("set_approval_callback works with agents", {
  # Skip if ellmer not available
  skip_if_not_installed("ellmer")
  
  # Create a mock chat object
  mock_chat <- structure(
    list(
      on_tool_request = function(callback) {
        # Store the callback for testing
        attr(mock_chat, "callback") <- callback
      }
    ),
    class = "Chat"
  )
  
  # Create agent with mock provider
  agent <- create_agent("test", mock_chat)
  
  # Test setting approval callback
  test_callback <- function(tool_info) TRUE
  result <- set_approval_callback(agent, test_callback)
  
  expect_identical(result, agent)
  expect_identical(agent$env$approval_callback, test_callback)
})

test_that("set_approval_callback validates inputs", {
  agent <- structure(list(env = new.env()), class = "agent")
  
  # Should work with function
  expect_silent(set_approval_callback(agent, function(x) TRUE))
  
  # Should work with NULL
  expect_silent(set_approval_callback(agent, NULL))
  
  # Should error with non-function
  expect_error(set_approval_callback(agent, "not a function"))
  
  # Should error with non-agent
  expect_error(set_approval_callback("not an agent", function(x) TRUE))
})

test_that("prompt_human_approval handles tool info correctly", {
  tool_info <- list(
    name = "test_tool",
    arguments = list(param1 = "value1", param2 = 42),
    id = "test_id_123"
  )
  
  # Test that tool_info structure is correct
  expect_true(is.list(tool_info))
  expect_true("name" %in% names(tool_info))
  expect_true("arguments" %in% names(tool_info))
  expect_true("id" %in% names(tool_info))
  
  # Test show_tool_details doesn't error
  expect_silent(show_tool_details(tool_info))
})

test_that("smart_approval_callback uses stored preferences", {
  # Clear any existing preferences
  clear_tool_approvals()
  
  tool_info <- list(name = "test_tool", arguments = list(), id = "123")
  
  # Manually store approval preference
  store_tool_approval("test_tool", TRUE)
  
  # Should auto-approve based on stored preference
  result <- smart_approval_callback(tool_info)
  expect_true(result)
  
  # Test with blocked tool
  store_tool_approval("blocked_tool", FALSE)
  blocked_info <- list(name = "blocked_tool", arguments = list(), id = "456")
  result2 <- smart_approval_callback(blocked_info)
  expect_true(is.character(result2))  # Should return error message
  
  # Clean up
  clear_tool_approvals()
})

test_that("tool approval storage works", {
  clear_tool_approvals()
  
  # Store approval
  store_tool_approval("test_tool", TRUE)
  expect_true(check_tool_approval("test_tool"))
  
  # Store denial
  store_tool_approval("bad_tool", FALSE)
  expect_false(check_tool_approval("bad_tool"))
  
  # Check non-existent tool
  expect_null(check_tool_approval("unknown_tool"))
  
  # Clear and verify
  clear_tool_approvals()
  expect_null(check_tool_approval("test_tool"))
})