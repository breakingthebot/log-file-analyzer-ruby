# Tests metric aggregation for parsed log entries.
# Connects to: src/services/log_analyzer.rb, src/models/log_entry.rb.
# Created: 2026-06-29

require_relative "../test_helper"

module LogFileAnalyzer
  module Services
    class LogAnalyzerTest < Minitest::Test
      # Verifies request totals, error totals, and endpoint rankings.
      # @return [void]
      def test_summarize_builds_expected_metrics
        entries = [
          LogEntry.new(http_method: "GET", endpoint: "/", status_code: 200),
          LogEntry.new(http_method: "GET", endpoint: "/api/users", status_code: 200),
          LogEntry.new(http_method: "POST", endpoint: "/api/users", status_code: 500),
          LogEntry.new(http_method: "GET", endpoint: "/health", status_code: 404)
        ]

        summary = LogAnalyzer.new.summarize(entries)

        assert_equal 4, summary["total_requests"]
        assert_equal 2, summary["error_requests"]
        assert_equal 50.0, summary["error_rate"]
        assert_equal "/api/users", summary["top_endpoints"].first["endpoint"]
        assert_equal 2, summary["top_endpoints"].first["requests"]
      end
    end
  end
end
