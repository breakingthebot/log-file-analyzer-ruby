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
        assert_equal Time.iso8601("2026-06-29T10:00:00Z"), entries[0].timestamp.utc
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
        assert_equal Time.iso8601("2026-06-29T10:00:03Z"), entries[3].timestamp.utc
      end

      # Verifies the parser can read gzip-compressed common logs.
      # @return [void]
      def test_parse_file_returns_structured_entries_for_gzip_common_logs
        logger = Utils.build_logger(stream: StringIO.new)
        parser = LogParser.new(logger: logger, input_format: "common")

        entries = parser.parse_file(fixture_path("server.log.gz"))

        assert_equal 5, entries.length
        assert_equal "/api/users", entries[1].endpoint
        assert_equal 500, entries[2].status_code
      end

      # Verifies the parser can read gzip-compressed JSON logs.
      # @return [void]
      def test_parse_file_returns_structured_entries_for_gzip_json_logs
        logger = Utils.build_logger(stream: StringIO.new)
        parser = LogParser.new(logger: logger, input_format: "json")

        entries = parser.parse_file(fixture_path("server.jsonl.gz"))

        assert_equal 4, entries.length
        assert_equal "/", entries[0].endpoint
        assert_equal "/health", entries.last.endpoint
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

      # Verifies multiple files can be parsed into one combined entry list.
      # @return [void]
      def test_parse_files_combines_entries_from_multiple_files
        logger = Utils.build_logger(stream: StringIO.new)
        parser = LogParser.new(logger: logger, input_format: "auto")

        entries = parser.parse_files(
          [
            fixture_path("batch/common-a.log"),
            fixture_path("batch/common-b.log"),
            fixture_path("batch/structured.jsonl")
          ]
        )

        assert_equal 5, entries.length
        assert_equal ["/", "/api/users", "/api/users", "/health", "/api/admin"], entries.map(&:endpoint)
      end

      # Verifies auto mode can choose different parser modes for different files in one batch.
      # @return [void]
      def test_parse_files_auto_detects_mixed_batch_per_file
        logger = Utils.build_logger(stream: StringIO.new)
        parser = LogParser.new(logger: logger, input_format: "auto")

        entries = parser.parse_files(
          [
            fixture_path("batch/mixed/common-mixed.data"),
            fixture_path("batch/mixed/json-mixed.data")
          ]
        )

        assert_equal 4, entries.length
        assert_equal ["/reports", "/reports", "/events", "/events"], entries.map(&:endpoint)
      end

      # Verifies streamed parsing yields entries across multiple files.
      # @return [void]
      def test_each_entry_streams_entries_across_multiple_files
        logger = Utils.build_logger(stream: StringIO.new)
        parser = LogParser.new(logger: logger, input_format: "auto")

        entries = parser.each_entry(
          [
            fixture_path("batch/common-a.log"),
            fixture_path("batch/structured.jsonl")
          ]
        ).to_a

        assert_equal 3, entries.length
        assert_equal ["/", "/api/users", "/api/admin"], entries.map(&:endpoint)
      end

      # Verifies batch parsing can combine compressed and uncompressed files.
      # @return [void]
      def test_parse_files_combines_compressed_and_uncompressed_inputs
        logger = Utils.build_logger(stream: StringIO.new)
        parser = LogParser.new(logger: logger, input_format: "auto")

        entries = parser.parse_files(
          [
            fixture_path("batch/common-a.log"),
            fixture_path("batch/structured.jsonl.gz")
          ]
        )

        assert_equal 3, entries.length
        assert_equal ["/", "/api/users", "/api/admin"], entries.map(&:endpoint)
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
