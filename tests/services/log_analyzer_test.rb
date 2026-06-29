# Tests metric aggregation for parsed log entries.
# Connects to: src/services/log_analyzer.rb, src/models/log_entry.rb.
# Created: 2026-06-29

require_relative "../test_helper"
require "time"

module LogFileAnalyzer
  module Services
    class LogAnalyzerTest < Minitest::Test
      # Verifies request totals, error totals, and endpoint rankings.
      # @return [void]
      def test_summarize_builds_expected_metrics
        entries = [
          LogEntry.new(http_method: "GET", endpoint: "/", status_code: 200, timestamp: Time.iso8601("2026-06-29T10:00:00Z")),
          LogEntry.new(http_method: "GET", endpoint: "/api/users", status_code: 200, timestamp: Time.iso8601("2026-06-29T10:00:10Z")),
          LogEntry.new(http_method: "POST", endpoint: "/api/users", status_code: 500, timestamp: Time.iso8601("2026-06-29T10:01:00Z")),
          LogEntry.new(http_method: "GET", endpoint: "/health", status_code: 404, timestamp: Time.iso8601("2026-06-29T10:01:20Z"))
        ]

        summary = LogAnalyzer.new.summarize(entries, time_bucket: "minute")

        assert_equal 4, summary["total_requests"]
        assert_equal 2, summary["error_requests"]
        assert_equal 50.0, summary["error_rate"]
        assert_equal "/api/users", summary["top_endpoints"].first["endpoint"]
        assert_equal 2, summary["top_endpoints"].first["requests"]
        assert_equal "GET", summary["methods"].first["label"]
        assert_equal 3, summary["methods"].first["requests"]
        assert_equal "2xx", summary["status_families"].first["label"]
        assert_equal 2, summary["status_families"].first["requests"]
        assert_equal "200", summary["status_codes"].first["label"]
        assert_equal 2, summary["status_codes"].first["requests"]
        assert_equal "2026-06-29T10:00:00Z", summary["time_buckets"].first["label"]
        assert_equal 2, summary["time_buckets"].first["requests"]
        assert_equal 0, summary["time_buckets"].first["errors"]
        assert_equal "2026-06-29T10:01:00Z", summary["time_buckets"][1]["label"]
        assert_equal 2, summary["time_buckets"][1]["requests"]
        assert_equal 2, summary["time_buckets"][1]["errors"]
      end
    end
  end
end
