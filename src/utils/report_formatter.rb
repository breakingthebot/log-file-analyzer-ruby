# Formats analyzer output for terminal, JSON, and CSV consumers.
# Connects to: src/main.rb, src/services/log_analyzer.rb.
# Created: 2026-06-29

require "csv"
require "json"

module LogFileAnalyzer
  module Utils
    # Renders analyzer output in supported formats.
    class ReportFormatter
      DEFAULT_TOP_LIMIT = 5

      # Builds a formatter with a top endpoint limit.
      # @param top_limit [Integer] number of endpoints to show
      def initialize(top_limit: DEFAULT_TOP_LIMIT)
        @top_limit = top_limit
      end

      # Formats a report as text, JSON, or CSV.
      # @param summary [Hash] analyzer summary
      # @param format [String] output format name
      # @return [String]
      def format(summary, format:)
        return format_comparison_report(summary, format: format) if comparison_report?(summary)

        case format
        when "csv"
          build_csv_report(summary)
        when "json"
          JSON.pretty_generate(summary.merge("top_endpoints" => limited_endpoints(summary)))
        when "text"
          build_text_report(summary)
        else
          raise ArgumentError, "Unsupported output format: #{format}"
        end
      end

      private

      # Checks whether the provided payload is a comparison report.
      # @param summary [Hash] analyzer summary or comparison payload
      # @return [Boolean]
      def comparison_report?(summary)
        summary["report_type"] == "comparison"
      end

      # Formats a comparison payload in one of the supported output formats.
      # @param comparison_report [Hash] comparison payload
      # @param format [String] output format name
      # @return [String]
      def format_comparison_report(comparison_report, format:)
        case format
        when "csv"
          build_comparison_csv_report(comparison_report)
        when "json"
          JSON.pretty_generate(limit_comparison_endpoints(comparison_report))
        when "text"
          build_comparison_text_report(comparison_report)
        else
          raise ArgumentError, "Unsupported output format: #{format}"
        end
      end

      # Limits the top endpoint list to the configured size.
      # @param summary [Hash] analyzer summary
      # @return [Array<Hash>]
      def limited_endpoints(summary)
        summary.fetch("top_endpoints").first(@top_limit)
      end

      # Applies top-endpoint limits to all endpoint-heavy sections in comparison output.
      # @param comparison_report [Hash] comparison payload
      # @return [Hash]
      def limit_comparison_endpoints(comparison_report)
        {
          "report_type" => comparison_report.fetch("report_type"),
          "current" => comparison_report.fetch("current").merge(
            "top_endpoints" => limited_endpoints(comparison_report.fetch("current"))
          ),
          "comparison" => comparison_report.fetch("comparison").merge(
            "top_endpoints" => limited_endpoints(comparison_report.fetch("comparison"))
          ),
          "delta" => comparison_report.fetch("delta").merge(
            "top_endpoints" => comparison_report.fetch("delta").fetch("top_endpoints").first(@top_limit)
          )
        }
      end

      # Builds the default human-readable terminal report.
      # @param summary [Hash] analyzer summary
      # @return [String]
      def build_text_report(summary)
        top_endpoints = limited_endpoints(summary).map do |endpoint|
          "  - #{endpoint.fetch('endpoint')}: #{endpoint.fetch('requests')} requests"
        end

        [
          "Log Analysis Summary",
          "Total requests: #{summary.fetch('total_requests')}",
          "Error requests: #{summary.fetch('error_requests')}",
          "Error rate: #{sprintf('%.2f', summary.fetch('error_rate'))}%",
          "Methods:",
          build_breakdown_lines(summary.fetch("methods")),
          "Status families:",
          build_breakdown_lines(summary.fetch("status_families")),
          "Status codes:",
          build_breakdown_lines(summary.fetch("status_codes")),
          "Time buckets:",
          build_time_bucket_lines(summary.fetch("time_buckets")),
          "Top endpoints:",
          (top_endpoints.empty? ? "  - No endpoints found" : top_endpoints.join("\n"))
        ].join("\n")
      end

      # Builds the default human-readable comparison report.
      # @param comparison_report [Hash] comparison payload
      # @return [String]
      def build_comparison_text_report(comparison_report)
        current_summary = comparison_report.fetch("current")
        comparison_summary = comparison_report.fetch("comparison")
        deltas = comparison_report.fetch("delta")

        endpoint_lines = deltas.fetch("top_endpoints").first(@top_limit).map do |entry|
          "  - #{entry.fetch('endpoint')}: current #{entry.fetch('current')}, comparison #{entry.fetch('comparison')}, delta #{format_signed_number(entry.fetch('delta'))}"
        end

        [
          "Log Comparison Summary",
          "Current total requests: #{current_summary.fetch('total_requests')}",
          "Comparison total requests: #{comparison_summary.fetch('total_requests')}",
          "Summary deltas:",
          build_summary_delta_lines(deltas.fetch("summary")),
          "Method deltas:",
          build_comparison_breakdown_lines(deltas.fetch("methods")),
          "Status family deltas:",
          build_comparison_breakdown_lines(deltas.fetch("status_families")),
          "Status code deltas:",
          build_comparison_breakdown_lines(deltas.fetch("status_codes")),
          "Endpoint deltas:",
          (endpoint_lines.empty? ? "  - No endpoints found" : endpoint_lines.join("\n"))
        ].join("\n")
      end

      # Builds text lines for a generic request breakdown section.
      # @param breakdown [Array<Hash>] summary breakdown entries
      # @return [String]
      def build_breakdown_lines(breakdown)
        lines = breakdown.map do |entry|
          "  - #{entry.fetch('label')}: #{entry.fetch('requests')} requests"
        end

        lines.empty? ? "  - No data found" : lines.join("\n")
      end

      # Builds text lines for time-bucket trend summaries.
      # @param time_buckets [Array<Hash>] bucketed summary entries
      # @return [String]
      def build_time_bucket_lines(time_buckets)
        lines = time_buckets.flat_map do |entry|
          bucket_lines = [
            "  - #{entry.fetch('label')}: #{entry.fetch('requests')} requests, #{entry.fetch('errors')} errors"
          ]
          bucket_lines.concat(build_time_bucket_series_lines(entry.fetch("series")))
        end

        lines.empty? ? "  - No bucketed data found" : lines.join("\n")
      end

      # Builds text lines for comparison summary metrics.
      # @param summary_deltas [Array<Hash>] comparison summary rows
      # @return [String]
      def build_summary_delta_lines(summary_deltas)
        summary_deltas.map do |entry|
          "  - #{entry.fetch('label')}: current #{entry.fetch('current')}, comparison #{entry.fetch('comparison')}, delta #{format_signed_number(entry.fetch('delta'))}"
        end.join("\n")
      end

      # Builds text lines for comparison breakdown sections.
      # @param breakdown [Array<Hash>] comparison breakdown rows
      # @return [String]
      def build_comparison_breakdown_lines(breakdown)
        lines = breakdown.map do |entry|
          "  - #{entry.fetch('label')}: current #{entry.fetch('current')}, comparison #{entry.fetch('comparison')}, delta #{format_signed_number(entry.fetch('delta'))}"
        end

        lines.empty? ? "  - No data found" : lines.join("\n")
      end

      # Builds text lines for a bucket's secondary series breakdown.
      # @param series [Array<Hash>] per-bucket series entries
      # @return [Array<String>]
      def build_time_bucket_series_lines(series)
        series.map do |entry|
          "    #{entry.fetch('label')}: #{entry.fetch('requests')} requests"
        end
      end

      # Builds a machine-friendly CSV report with sectioned rows.
      # @param summary [Hash] analyzer summary
      # @return [String]
      def build_csv_report(summary)
        CSV.generate do |csv|
          csv << %w[section label requests value]
          csv << ["summary", "total_requests", nil, summary.fetch("total_requests")]
          csv << ["summary", "error_requests", nil, summary.fetch("error_requests")]
          csv << ["summary", "error_rate", nil, summary.fetch("error_rate")]
          append_breakdown_rows(csv, "methods", summary.fetch("methods"))
          append_breakdown_rows(csv, "status_families", summary.fetch("status_families"))
          append_breakdown_rows(csv, "status_codes", summary.fetch("status_codes"))
          append_time_bucket_rows(csv, summary.fetch("time_buckets"))
          limited_endpoints(summary).each do |endpoint|
            csv << ["top_endpoints", endpoint.fetch("endpoint"), endpoint.fetch("requests"), nil]
          end
        end
      end

      # Builds a machine-friendly CSV comparison report with sectioned rows.
      # @param comparison_report [Hash] comparison payload
      # @return [String]
      def build_comparison_csv_report(comparison_report)
        CSV.generate do |csv|
          csv << %w[section label current comparison delta]
          append_comparison_summary_rows(csv, comparison_report.fetch("delta").fetch("summary"))
          append_comparison_breakdown_rows(csv, "method_deltas", comparison_report.fetch("delta").fetch("methods"))
          append_comparison_breakdown_rows(csv, "status_family_deltas", comparison_report.fetch("delta").fetch("status_families"))
          append_comparison_breakdown_rows(csv, "status_code_deltas", comparison_report.fetch("delta").fetch("status_codes"))
          comparison_report.fetch("delta").fetch("top_endpoints").first(@top_limit).each do |entry|
            csv << ["endpoint_deltas", entry.fetch("endpoint"), entry.fetch("current"), entry.fetch("comparison"), entry.fetch("delta")]
          end
        end
      end

      # Appends generic breakdown rows to the CSV output.
      # @param csv [CSV] csv builder
      # @param section [String] breakdown section name
      # @param breakdown [Array<Hash>] summary breakdown entries
      # @return [void]
      def append_breakdown_rows(csv, section, breakdown)
        breakdown.each do |entry|
          csv << [section, entry.fetch("label"), entry.fetch("requests"), nil]
        end
      end

      # Appends time-bucket rows to the CSV output.
      # @param csv [CSV] csv builder
      # @param time_buckets [Array<Hash>] bucketed summary entries
      # @return [void]
      def append_time_bucket_rows(csv, time_buckets)
        time_buckets.each do |entry|
          csv << ["time_buckets", entry.fetch("label"), entry.fetch("requests"), entry.fetch("errors")]
          entry.fetch("series").each do |series_entry|
            csv << ["time_bucket_series", entry.fetch("label"), series_entry.fetch("requests"), series_entry.fetch("label")]
          end
        end
      end

      # Appends comparison summary rows to the CSV output.
      # @param csv [CSV] csv builder
      # @param summary_rows [Array<Hash>] comparison summary rows
      # @return [void]
      def append_comparison_summary_rows(csv, summary_rows)
        summary_rows.each do |entry|
          csv << ["summary_deltas", entry.fetch("label"), entry.fetch("current"), entry.fetch("comparison"), entry.fetch("delta")]
        end
      end

      # Appends comparison breakdown rows to the CSV output.
      # @param csv [CSV] csv builder
      # @param section [String] comparison section name
      # @param rows [Array<Hash>] comparison breakdown rows
      # @return [void]
      def append_comparison_breakdown_rows(csv, section, rows)
        rows.each do |entry|
          csv << [section, entry.fetch("label"), entry.fetch("current"), entry.fetch("comparison"), entry.fetch("delta")]
        end
      end

      # Formats signed numeric deltas consistently for text output.
      # @param value [Numeric] delta value
      # @return [String]
      def format_signed_number(value)
        number = value.is_a?(Float) ? Kernel.format("%.2f", value) : value.to_s
        value.negative? ? number : "+#{number}"
      end
    end
  end
end
