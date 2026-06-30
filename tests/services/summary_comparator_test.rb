# Tests summary-to-summary comparison output for delta reporting.
# Connects to: src/services/summary_comparator.rb, src/services/log_analyzer.rb.
# Created: 2026-06-30

require_relative "../test_helper"

module LogFileAnalyzer
  module Services
    class SummaryComparatorTest < Minitest::Test
      # Verifies the comparator builds stable summary and breakdown deltas.
      # @return [void]
      def test_compare_builds_metric_and_endpoint_deltas
        comparison = SummaryComparator.new.compare(current_summary, comparison_summary)

        assert_equal "comparison", comparison["report_type"]
        assert_equal 5, comparison["current"]["total_requests"]
        assert_equal 3, comparison["comparison"]["total_requests"]
        total_delta = comparison["delta"]["summary"].find { |entry| entry["label"] == "request volume" }
        assert_equal 2, total_delta["delta"]
        method_delta = comparison["delta"]["methods"].find { |entry| entry["label"] == "POST" }
        assert_equal 1, method_delta["delta"]
        endpoint_delta = comparison["delta"]["top_endpoints"].find { |entry| entry["endpoint"] == "/api/users" }
        assert_equal 2, endpoint_delta["current"]
        assert_equal 1, endpoint_delta["comparison"]
        assert_equal 1, endpoint_delta["delta"]
      end

      private

      # Supplies a stable current summary fixture for comparison tests.
      # @return [Hash]
      def current_summary
        {
          "total_requests" => 5,
          "error_requests" => 2,
          "error_rate" => 40.0,
          "methods" => [
            { "label" => "GET", "requests" => 4 },
            { "label" => "POST", "requests" => 1 }
          ],
          "status_families" => [
            { "label" => "2xx", "requests" => 3 },
            { "label" => "4xx", "requests" => 1 },
            { "label" => "5xx", "requests" => 1 }
          ],
          "status_codes" => [
            { "label" => "200", "requests" => 3 },
            { "label" => "404", "requests" => 1 },
            { "label" => "500", "requests" => 1 }
          ],
          "time_buckets" => [],
          "top_endpoints" => [
            { "endpoint" => "/api/users", "requests" => 2 },
            { "endpoint" => "/", "requests" => 1 }
          ]
        }
      end

      # Supplies a stable comparison summary fixture for comparison tests.
      # @return [Hash]
      def comparison_summary
        {
          "total_requests" => 3,
          "error_requests" => 1,
          "error_rate" => 33.33,
          "methods" => [
            { "label" => "GET", "requests" => 2 },
            { "label" => "POST", "requests" => 0 }
          ],
          "status_families" => [
            { "label" => "2xx", "requests" => 2 },
            { "label" => "5xx", "requests" => 1 }
          ],
          "status_codes" => [
            { "label" => "200", "requests" => 2 },
            { "label" => "500", "requests" => 1 }
          ],
          "time_buckets" => [],
          "top_endpoints" => [
            { "endpoint" => "/api/users", "requests" => 1 },
            { "endpoint" => "/health", "requests" => 1 }
          ]
        }
      end
    end
  end
end
