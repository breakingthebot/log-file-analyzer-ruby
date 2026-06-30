# Aggregates parsed log entries into request and error metrics.
# Connects to: src/models/log_entry.rb, src/utils/report_formatter.rb.
# Created: 2026-06-29

require "time"
require_relative "summary_accumulator"

module LogFileAnalyzer
  module Services
    # Calculates request totals, error rates, and endpoint rankings.
    class LogAnalyzer
      ERROR_STATUS_START = 400
      STATUS_FAMILY_DIVISOR = 100

      # Builds a summary hash from parsed log entries.
      # @param entries [Array<LogEntry>] parsed log entries
      # @param time_bucket [String] bucket mode: none, minute, or hour
      # @param time_bucket_series [String] series mode: none, method, or status-family
      # @return [Hash]
      def summarize(entries, time_bucket: "none", time_bucket_series: "none")
        summarize_stream(entries.each, time_bucket: time_bucket, time_bucket_series: time_bucket_series)
      end

      # Builds a summary hash from a streamed entry source.
      # @param entry_stream [Enumerable<LogEntry>] streamed parsed log entries
      # @param time_bucket [String] bucket mode
      # @param time_bucket_series [String] series mode
      # @return [Hash]
      def summarize_stream(entry_stream, time_bucket: "none", time_bucket_series: "none")
        accumulator = SummaryAccumulator.new(time_bucket: time_bucket, time_bucket_series: time_bucket_series)
        entry_stream.each { |entry| accumulator.add(entry) }
        accumulator.summary
      end
    end
  end
end
