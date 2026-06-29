# Aggregates parsed log entries into request and error metrics.
# Connects to: src/models/log_entry.rb, src/utils/report_formatter.rb.
# Created: 2026-06-29

module LogFileAnalyzer
  module Services
    # Calculates request totals, error rates, and endpoint rankings.
    class LogAnalyzer
      ERROR_STATUS_START = 400

      # Builds a summary hash from parsed log entries.
      # @param entries [Array<LogEntry>] parsed log entries
      # @return [Hash]
      def summarize(entries)
        total_requests = entries.length
        error_requests = entries.count { |entry| error_status?(entry.status_code) }
        endpoint_counts = entries.each_with_object(Hash.new(0)) do |entry, counts|
          counts[entry.endpoint] += 1
        end

        {
          "total_requests" => total_requests,
          "error_requests" => error_requests,
          "error_rate" => calculate_error_rate(total_requests, error_requests),
          "top_endpoints" => endpoint_counts
            .sort_by { |endpoint, count| [-count, endpoint] }
            .map { |endpoint, count| { "endpoint" => endpoint, "requests" => count } }
        }
      end

      private

      # Determines whether a status code counts as an error.
      # @param status_code [Integer] response status code
      # @return [Boolean]
      def error_status?(status_code)
        status_code >= ERROR_STATUS_START
      end

      # Calculates a percentage with a safe zero-division fallback.
      # @param total_requests [Integer] total request count
      # @param error_requests [Integer] error request count
      # @return [Float]
      def calculate_error_rate(total_requests, error_requests)
        return 0.0 if total_requests.zero?

        (error_requests.to_f / total_requests * 100).round(2)
      end
    end
  end
end
