# Tests parsing behavior for access log files.
# Connects to: src/services/log_parser.rb, tests/fixtures/server.log.
# Created: 2026-06-29

require_relative "../test_helper"
require "stringio"

module LogFileAnalyzer
  module Services
    class LogParserTest < Minitest::Test
      # Verifies the parser converts valid lines and skips malformed ones.
      # @return [void]
      def test_parse_file_returns_structured_entries
        logger = Utils.build_logger(stream: StringIO.new)
        parser = LogParser.new(logger: logger)

        entries = parser.parse_file(fixture_path("server.log"))

        assert_equal 5, entries.length
        assert_equal "/api/users", entries[1].endpoint
        assert_equal "/api/users", entries[3].endpoint
        assert_equal 500, entries[2].status_code
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
