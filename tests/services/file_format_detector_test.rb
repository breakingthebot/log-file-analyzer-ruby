# Tests file-level format detection for mixed batch parsing.
# Connects to: src/services/file_format_detector.rb, src/services/log_parser.rb.
# Created: 2026-06-29

require_relative "../test_helper"
require "stringio"

module LogFileAnalyzer
  module Services
    class FileFormatDetectorTest < Minitest::Test
      # Verifies the detector can infer common logs from content when extension is unknown.
      # @return [void]
      def test_detect_returns_common_for_common_log_content
        detector = FileFormatDetector.new(logger: logger)

        detected_format = detector.detect(fixture_path("batch/mixed/common-mixed.data"))

        assert_equal "common", detected_format
      end

      # Verifies the detector can infer JSON logs from content when extension is unknown.
      # @return [void]
      def test_detect_returns_json_for_json_log_content
        detector = FileFormatDetector.new(logger: logger)

        detected_format = detector.detect(fixture_path("batch/mixed/json-mixed.data"))

        assert_equal "json", detected_format
      end

      # Verifies the detector recognizes compressed common logs from extension.
      # @return [void]
      def test_detect_returns_common_for_gzip_log_extension
        detector = FileFormatDetector.new(logger: logger)

        detected_format = detector.detect(fixture_path("server.log.gz"))

        assert_equal "common", detected_format
      end

      # Verifies the detector recognizes compressed JSON logs from extension.
      # @return [void]
      def test_detect_returns_json_for_gzip_jsonl_extension
        detector = FileFormatDetector.new(logger: logger)

        detected_format = detector.detect(fixture_path("server.jsonl.gz"))

        assert_equal "json", detected_format
      end

      private

      # Builds a logger that keeps test output quiet.
      # @return [Logger]
      def logger
        @logger ||= Utils.build_logger(stream: StringIO.new)
      end

      # Resolves a fixture path for the current test suite.
      # @param relative_path [String] fixture path suffix
      # @return [String]
      def fixture_path(relative_path)
        File.expand_path("../fixtures/#{relative_path}", __dir__)
      end
    end
  end
end
