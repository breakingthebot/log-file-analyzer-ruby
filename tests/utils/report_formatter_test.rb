# Tests terminal and JSON report formatting.
# Connects to: src/utils/report_formatter.rb, src/services/log_analyzer.rb.
# Created: 2026-06-29

require_relative "../test_helper"
require "json"

module LogFileAnalyzer
  module Utils
    class ReportFormatterTest < Minitest::Test
      # Verifies text output includes the expected metric labels.
      # @return [void]
      def test_text_format_renders_summary_lines
        formatter = ReportFormatter.new(top_limit: 2)

        report = formatter.format(sample_summary, format: "text")

        assert_includes report, "Total requests: 3"
        assert_includes report, "Error rate: 33.33%"
        assert_includes report, "  - /api/users: 2 requests"
      end

      # Verifies JSON output honors the configured top endpoint limit.
      # @return [void]
      def test_json_format_limits_top_endpoints
        formatter = ReportFormatter.new(top_limit: 1)

        report = JSON.parse(formatter.format(sample_summary, format: "json"))

        assert_equal 1, report["top_endpoints"].length
        assert_equal "/api/users", report["top_endpoints"].first["endpoint"]
      end

      private

      # Supplies a stable summary fixture for formatter tests.
      # @return [Hash]
      def sample_summary
        {
          "total_requests" => 3,
          "error_requests" => 1,
          "error_rate" => 33.33,
          "top_endpoints" => [
            { "endpoint" => "/api/users", "requests" => 2 },
            { "endpoint" => "/health", "requests" => 1 }
          ]
        }
      end
    end
  end
end
