# Tests parsing behavior for supported log file formats.
# Connects to: src/services/log_parser.rb, tests/fixtures/server.log, tests/fixtures/server.jsonl.
# Created: 2026-06-29

require_relative "../test_helper"
require "stringio"

module LogFileAnalyzer
  module Services
    class LogParserTest < Minitest::Test
      # Verifies the parser converts common log lines and skips malformed ones.
      # @return [void]
      def test_parse_file_returns_structured_entries_for_common_logs
        logger = Utils.build_logger(stream: StringIO.new)
        parser = LogParser.new(logger: logger, input_format: "common")

        entries = parser.parse_file(fixture_path("server.log"))

        assert_equal 5, entries.length
        assert_equal "/api/users", entries[1].endpoint
        assert_equal "/api/users", entries[3].endpoint
        assert_equal 500, entries[2].status_code
      end

      # Verifies the parser converts newline-delimited JSON logs and skips invalid lines.
      # @return [void]
      def test_parse_file_returns_structured_entries_for_json_logs
        logger = Utils.build_logger(stream: StringIO.new)
        parser = LogParser.new(logger: logger, input_format: "json")

        entries = parser.parse_file(fixture_path("server.jsonl"))

        assert_equal 4, entries.length
        assert_equal "/", entries[0].endpoint
        assert_equal "/api/users", entries[2].endpoint
        assert_equal 503, entries[2].status_code
      end

      # Verifies auto mode can parse files without an explicit format flag.
      # @return [void]
      def test_parse_file_auto_detects_json_lines
        logger = Utils.build_logger(stream: StringIO.new)
        parser = LogParser.new(logger: logger)

        entries = parser.parse_file(fixture_path("server.jsonl"))

        assert_equal 4, entries.length
        assert_equal "/health", entries.last.endpoint
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
end
