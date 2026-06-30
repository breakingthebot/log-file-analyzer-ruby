# Tests CLI threshold behavior for automation-oriented failure exit codes.
# Connects to: src/main.rb, src/services/threshold_evaluator.rb.
# Created: 2026-06-30

require_relative "../test_helper"

module LogFileAnalyzer
  class ThresholdCliTest < Minitest::Test
    # Verifies the CLI returns the threshold failure code when a limit is exceeded.
    # @return [void]
    def test_run_returns_threshold_failure_exit_code
      exit_code = Main.run(
        [
          "--max-error-rate", "30",
          fixture_path("server.log")
        ]
      )

      assert_equal Main::THRESHOLD_FAILURE_EXIT_CODE, exit_code
    end

    # Verifies the CLI still succeeds when thresholds are not exceeded.
    # @return [void]
    def test_run_returns_success_when_thresholds_pass
      exit_code = Main.run(
        [
          "--max-error-rate", "50",
          "--max-error-requests", "2",
          "--max-5xx-requests", "1",
          fixture_path("server.log")
        ]
      )

      assert_equal 0, exit_code
    end

    private

    # Resolves a fixture path for the current test suite.
    # @param file_name [String] fixture file name
    # @return [String]
    def fixture_path(file_name)
      File.expand_path("../fixtures/#{file_name}", __dir__)
    end
  end
end
