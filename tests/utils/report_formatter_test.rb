# Tests terminal and JSON report formatting.
# Connects to: src/utils/report_formatter.rb, src/services/log_analyzer.rb.
# Created: 2026-06-29

require_relative "../test_helper"
require "csv"
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
        assert_includes report, "Methods:"
        assert_includes report, "  - GET: 2 requests"
        assert_includes report, "Status families:"
        assert_includes report, "  - 2xx: 2 requests"
        assert_includes report, "Time buckets:"
        assert_includes report, "  - 2026-06-29T10:00:00Z: 2 requests, 0 errors"
        assert_includes report, "    GET: 2 requests"
        assert_includes report, "  - /api/users: 2 requests"
      end

      # Verifies JSON output honors the configured top endpoint limit.
      # @return [void]
      def test_json_format_limits_top_endpoints
        formatter = ReportFormatter.new(top_limit: 1)

        report = JSON.parse(formatter.format(sample_summary, format: "json"))

        assert_equal 1, report["top_endpoints"].length
        assert_equal "/api/users", report["top_endpoints"].first["endpoint"]
        assert_equal "GET", report["methods"].first["label"]
        assert_equal "200", report["status_codes"].first["label"]
        assert_equal "2026-06-29T10:00:00Z", report["time_buckets"].first["label"]
        assert_equal "GET", report["time_buckets"].first["series"].first["label"]
      end

      # Verifies CSV output includes summary and breakdown rows.
      # @return [void]
      def test_csv_format_renders_sectioned_rows
        formatter = ReportFormatter.new(top_limit: 1)

        rows = CSV.parse(formatter.format(sample_summary, format: "csv"), headers: true)

        assert_equal ["section", "label", "requests", "value"], rows.headers
        assert_equal "summary", rows[0]["section"]
        assert_equal "total_requests", rows[0]["label"]
        assert_equal "3", rows[0]["value"]
        assert_equal "methods", rows[3]["section"]
        assert_equal "GET", rows[3]["label"]
        assert_equal "2", rows[3]["requests"]
        time_bucket_row = rows.find { |row| row["section"] == "time_buckets" }
        refute_nil time_bucket_row
        assert_equal "2026-06-29T10:00:00Z", time_bucket_row["label"]
        assert_equal "0", time_bucket_row["value"]
        time_bucket_series_row = rows.find { |row| row["section"] == "time_bucket_series" }
        refute_nil time_bucket_series_row
        assert_equal "2026-06-29T10:00:00Z", time_bucket_series_row["label"]
        assert_equal "GET", time_bucket_series_row["value"]
        assert_equal "top_endpoints", rows[-1]["section"]
        assert_equal "/api/users", rows[-1]["label"]
      end

      private

      # Supplies a stable summary fixture for formatter tests.
      # @return [Hash]
      def sample_summary
        {
          "total_requests" => 3,
          "error_requests" => 1,
          "error_rate" => 33.33,
          "methods" => [
            { "label" => "GET", "requests" => 2 },
            { "label" => "POST", "requests" => 1 }
          ],
          "status_families" => [
            { "label" => "2xx", "requests" => 2 },
            { "label" => "5xx", "requests" => 1 }
          ],
          "status_codes" => [
            { "label" => "200", "requests" => 2 },
            { "label" => "500", "requests" => 1 }
          ],
          "time_buckets" => [
            {
              "label" => "2026-06-29T10:00:00Z",
              "requests" => 2,
              "errors" => 0,
              "series" => [
                { "label" => "GET", "requests" => 2 }
              ]
            },
            {
              "label" => "2026-06-29T10:01:00Z",
              "requests" => 1,
              "errors" => 1,
              "series" => [
                { "label" => "POST", "requests" => 1 }
              ]
            }
          ],
          "top_endpoints" => [
            { "endpoint" => "/api/users", "requests" => 2 },
            { "endpoint" => "/health", "requests" => 1 }
          ]
        }
      end
    end
  end
end
