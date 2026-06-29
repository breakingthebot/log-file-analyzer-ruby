# Tests YAML-backed config loading for CLI defaults.
# Connects to: src/utils/config_loader.rb, src/main.rb.
# Created: 2026-06-29

require_relative "../test_helper"

module LogFileAnalyzer
  module Utils
    class ConfigLoaderTest < Minitest::Test
      # Verifies config values are loaded and normalized from YAML.
      # @return [void]
      def test_load_returns_normalized_config_values
        config = ConfigLoader.new.load(fixture_path("config/basic.yml"))

        assert_equal "csv", config[:format]
        assert_equal "json", config[:input_format]
        assert_equal 2, config[:top]
        assert_equal "minute", config[:time_bucket]
        assert_equal "reports/basic-report.csv", config[:output_path]
        assert_equal ["tests/fixtures/server.log"], config[:input_paths]
      end

      # Verifies invalid top values fail fast with a clear message.
      # @return [void]
      def test_load_rejects_invalid_top_value
        error = assert_raises(ArgumentError) do
          ConfigLoader.new.load(fixture_path("config/invalid-top.yml"))
        end

        assert_equal "Config value for top must be a positive integer.", error.message
      end

      private

      # Resolves a fixture path for the current test suite.
      # @param relative_path [String] fixture path suffix
      # @return [String]
      def fixture_path(relative_path)
        File.expand_path("../fixtures/#{relative_path}", __dir__)
      end
    end
  end
end
