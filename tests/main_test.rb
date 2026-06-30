# Tests CLI option precedence across defaults, config, and direct flags.
# Connects to: src/main.rb, src/utils/config_loader.rb.
# Created: 2026-06-29

require_relative "test_helper"

module LogFileAnalyzer
  class MainTest < Minitest::Test
    # Verifies explicit CLI flags override config values.
    # @return [void]
    def test_parse_options_prefers_cli_values_over_config
      options = Main.parse_options(
        [
          "--config", fixture_path("config/basic.yml"),
          "--format", "json",
          "--top", "3",
          "tests/fixtures/server.jsonl"
        ]
      )

      assert_equal "json", options[:format]
      assert_equal "json", options[:input_format]
      assert_equal 3, options[:top]
      assert_equal "minute", options[:time_bucket]
      assert_equal "method", options[:time_bucket_series]
      assert_equal "reports/basic-report.csv", options[:output_path]
      assert_equal ["tests/fixtures/server.jsonl"], options[:input_paths]
    end

    # Verifies threshold flags are parsed into the CLI options hash.
    # @return [void]
    def test_parse_options_accepts_threshold_flags
      options = Main.parse_options(
        [
          "--max-error-rate", "40.5",
          "--max-error-requests", "3",
          "--max-5xx-requests", "1",
          "tests/fixtures/server.log"
        ]
      )

      assert_equal 40.5, options[:max_error_rate]
      assert_equal 3, options[:max_error_requests]
      assert_equal 1, options[:max_5xx_requests]
    end

    # Verifies repeated comparison flags are collected as a second input set.
    # @return [void]
    def test_parse_options_collects_comparison_paths
      options = Main.parse_options(
        [
          "--compare-to", "tests/fixtures/batch/common-a.log",
          "--compare-to", "tests/fixtures/batch/common-b.log",
          "tests/fixtures/server.log"
        ]
      )

      assert_equal ["tests/fixtures/batch/common-a.log", "tests/fixtures/batch/common-b.log"], options[:compare_to_paths]
    end

    # Verifies config-provided input paths are used when no CLI paths are supplied.
    # @return [void]
    def test_parse_options_uses_config_input_paths_when_cli_paths_are_missing
      options = Main.parse_options(["--config", fixture_path("config/basic.yml")])

      assert_equal ["tests/fixtures/server.log"], options[:input_paths]
    end

    # Verifies invalid threshold flag values are rejected early.
    # @return [void]
    def test_parse_options_rejects_invalid_threshold_values
      error = assert_raises(OptionParser::ParseError) do
        Main.parse_options(["--max-error-rate", "120", "tests/fixtures/server.log"])
      end

      assert_equal "invalid argument: --max-error-rate Max error rate must be between 0 and 100.", error.message
    end

    private

    # Resolves a fixture path for the current test suite.
    # @param relative_path [String] fixture path suffix
    # @return [String]
    def fixture_path(relative_path)
      File.expand_path("fixtures/#{relative_path}", __dir__)
    end
  end
end
