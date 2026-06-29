# Shared test setup for the Ruby log file analyzer suite.
# Connects to: tests/services/*, tests/utils/*, src/main.rb.
# Created: 2026-06-29

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../src", __dir__))

require "main"
