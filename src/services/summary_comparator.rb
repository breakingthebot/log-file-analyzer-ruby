# Compares two analyzer summaries and calculates stable metric deltas.
# Connects to: src/main.rb, src/utils/report_formatter.rb, tests/services/summary_comparator_test.rb.
# Created: 2026-06-30

module LogFileAnalyzer
  module Services
    # Builds a comparison report from two completed analyzer summaries.
    class SummaryComparator
      SUMMARY_METRICS = {
        "total_requests" => "request volume",
        "error_requests" => "error volume",
        "error_rate" => "error rate"
      }.freeze

      # Builds a comparison payload from current and comparison summaries.
      # @param current_summary [Hash] summary for the primary input set
      # @param comparison_summary [Hash] summary for the comparison input set
      # @return [Hash]
      def compare(current_summary, comparison_summary)
        {
          "report_type" => "comparison",
          "current" => current_summary,
          "comparison" => comparison_summary,
          "delta" => {
            "summary" => build_summary_deltas(current_summary, comparison_summary),
            "methods" => build_breakdown_deltas(current_summary.fetch("methods"), comparison_summary.fetch("methods")),
            "status_families" => build_breakdown_deltas(current_summary.fetch("status_families"), comparison_summary.fetch("status_families")),
            "status_codes" => build_breakdown_deltas(current_summary.fetch("status_codes"), comparison_summary.fetch("status_codes")),
            "top_endpoints" => build_endpoint_deltas(current_summary.fetch("top_endpoints"), comparison_summary.fetch("top_endpoints"))
          }
        }
      end

      private

      # Builds deltas for the top-level summary metrics.
      # @param current_summary [Hash] summary for the primary input set
      # @param comparison_summary [Hash] summary for the comparison input set
      # @return [Array<Hash>]
      def build_summary_deltas(current_summary, comparison_summary)
        SUMMARY_METRICS.map do |metric_key, label|
          current_value = current_summary.fetch(metric_key)
          comparison_value = comparison_summary.fetch(metric_key)

          {
            "label" => label,
            "current" => current_value,
            "comparison" => comparison_value,
            "delta" => round_delta(current_value - comparison_value)
          }
        end
      end

      # Builds stable deltas for a generic breakdown section.
      # @param current_rows [Array<Hash>] current breakdown rows
      # @param comparison_rows [Array<Hash>] comparison breakdown rows
      # @return [Array<Hash>]
      def build_breakdown_deltas(current_rows, comparison_rows)
        current_counts = index_breakdown(current_rows)
        comparison_counts = index_breakdown(comparison_rows)

        (current_counts.keys | comparison_counts.keys)
          .sort
          .map do |label|
            current_value = current_counts.fetch(label, 0)
            comparison_value = comparison_counts.fetch(label, 0)

            {
              "label" => label,
              "current" => current_value,
              "comparison" => comparison_value,
              "delta" => current_value - comparison_value
            }
          end
      end

      # Builds stable deltas for endpoint rankings using request counts.
      # @param current_rows [Array<Hash>] current endpoint rows
      # @param comparison_rows [Array<Hash>] comparison endpoint rows
      # @return [Array<Hash>]
      def build_endpoint_deltas(current_rows, comparison_rows)
        current_counts = index_endpoints(current_rows)
        comparison_counts = index_endpoints(comparison_rows)

        (current_counts.keys | comparison_counts.keys)
          .sort_by { |endpoint| [-(current_counts.fetch(endpoint, 0) - comparison_counts.fetch(endpoint, 0)).abs, endpoint] }
          .map do |endpoint|
            current_value = current_counts.fetch(endpoint, 0)
            comparison_value = comparison_counts.fetch(endpoint, 0)

            {
              "endpoint" => endpoint,
              "current" => current_value,
              "comparison" => comparison_value,
              "delta" => current_value - comparison_value
            }
          end
      end

      # Indexes a generic summary breakdown by label.
      # @param rows [Array<Hash>] summary breakdown rows
      # @return [Hash]
      def index_breakdown(rows)
        rows.each_with_object({}) do |row, counts|
          counts[row.fetch("label")] = row.fetch("requests")
        end
      end

      # Indexes endpoint rows by endpoint path.
      # @param rows [Array<Hash>] endpoint rows
      # @return [Hash]
      def index_endpoints(rows)
        rows.each_with_object({}) do |row, counts|
          counts[row.fetch("endpoint")] = row.fetch("requests")
        end
      end

      # Rounds floating-point deltas while leaving integers stable.
      # @param value [Numeric] raw delta value
      # @return [Numeric]
      def round_delta(value)
        value.is_a?(Float) ? value.round(2) : value
      end
    end
  end
end
