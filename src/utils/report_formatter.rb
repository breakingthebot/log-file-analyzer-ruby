# Formats analyzer output for terminal and JSON consumers.
# Connects to: src/main.rb, src/services/log_analyzer.rb.
# Created: 2026-06-29

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

      # Formats a report as either text or JSON.
      # @param summary [Hash] analyzer summary
      # @param format [String] output format name
      # @return [String]
      def format(summary, format:)
        case format
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
          "Top endpoints:",
          (top_endpoints.empty? ? "  - No endpoints found" : top_endpoints.join("\n"))
        ].join("\n")
      end
    end
  end
end
