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

      # Limits the top endpoint list to the configured size.
      # @param summary [Hash] analyzer summary
      # @return [Array<Hash>]
      def limited_endpoints(summary)
        summary.fetch("top_endpoints").first(@top_limit)
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
          "Top endpoints:",
          (top_endpoints.empty? ? "  - No endpoints found" : top_endpoints.join("\n"))
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
          limited_endpoints(summary).each do |endpoint|
            csv << ["top_endpoints", endpoint.fetch("endpoint"), endpoint.fetch("requests"), nil]
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
    end
  end
end
