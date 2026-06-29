# Tests the packaged CLI version flag through the executable entry point.
# Connects to: exe/log-file-analyzer, src/config/version.rb.
# Created: 2026-06-29

require_relative "../test_helper"
require "open3"
require "rbconfig"

module LogFileAnalyzer
  class VersionCliTest < Minitest::Test
    # Verifies the executable prints the current application version.
    # @return [void]
    def test_executable_prints_current_version
      stdout, stderr, status = Open3.capture3(
        RbConfig.ruby,
        executable_path,
        "--version"
      )

      assert status.success?, "Expected success but got stderr: #{stderr}"
      assert_equal "#{LogFileAnalyzer::VERSION}\n", stdout
      assert_equal "", stderr
    end

    private

    # Resolves the CLI executable path under the repository root.
    # @return [String]
    def executable_path
      File.expand_path("../../exe/log-file-analyzer", __dir__)
    end
  end
end
