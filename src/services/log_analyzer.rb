# Aggregates parsed log entries into request and error metrics.
# Connects to: src/models/log_entry.rb, src/utils/report_formatter.rb.
# Created: 2026-06-29

require "time"

module LogFileAnalyzer
  module Services
    # Calculates request totals, error rates, and endpoint rankings.
    class LogAnalyzer
      ERROR_STATUS_START = 400
      STATUS_FAMILY_DIVISOR = 100

      # Builds a summary hash from parsed log entries.
      # @param entries [Array<LogEntry>] parsed log entries
      # @param time_bucket [String] bucket mode: none, minute, or hour
      # @return [Hash]
      def summarize(entries, time_bucket: "none")
        total_requests = entries.length
        error_requests = entries.count { |entry| error_status?(entry.status_code) }
        endpoint_counts = entries.each_with_object(Hash.new(0)) do |entry, counts|
          counts[entry.endpoint] += 1
        end
        method_counts = entries.each_with_object(Hash.new(0)) do |entry, counts|
          counts[entry.http_method] += 1
        end
        status_code_counts = entries.each_with_object(Hash.new(0)) do |entry, counts|
          counts[entry.status_code] += 1
        end
        status_family_counts = entries.each_with_object(Hash.new(0)) do |entry, counts|
          counts[status_family_label(entry.status_code)] += 1
        end

        {
          "total_requests" => total_requests,
          "error_requests" => error_requests,
          "error_rate" => calculate_error_rate(total_requests, error_requests),
          "methods" => build_breakdown(method_counts),
          "status_families" => build_breakdown(status_family_counts),
          "status_codes" => build_breakdown(status_code_counts),
          "time_buckets" => build_time_buckets(entries, time_bucket: time_bucket),
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

      # Converts a status code into a status family label.
      # @param status_code [Integer] response status code
      # @return [String]
      def status_family_label(status_code)
        "#{status_code / STATUS_FAMILY_DIVISOR}xx"
      end

      # Sorts a count hash into a stable array for output.
      # @param counts [Hash] raw count hash
      # @return [Array<Hash>]
      def build_breakdown(counts)
        counts
          .sort_by { |label, count| [-count, label.to_s] }
          .map { |label, count| { "label" => label.to_s, "requests" => count } }
      end

      # Builds a chronological request/error series for the selected bucket mode.
      # @param entries [Array<LogEntry>] parsed log entries
      # @param time_bucket [String] bucket mode
      # @return [Array<Hash>]
      def build_time_buckets(entries, time_bucket:)
        return [] if time_bucket == "none"

        bucket_counts = entries.each_with_object(Hash.new { |hash, key| hash[key] = { requests: 0, errors: 0 } }) do |entry, counts|
          next if entry.timestamp.nil?

          bucket_label = format_time_bucket(entry.timestamp, time_bucket)
          counts[bucket_label][:requests] += 1
          counts[bucket_label][:errors] += 1 if error_status?(entry.status_code)
        end

        bucket_counts
          .sort_by { |label, _counts| label }
          .map do |label, counts|
            {
              "label" => label,
              "requests" => counts[:requests],
              "errors" => counts[:errors]
            }
          end
      end

      # Formats a timestamp into the selected bucket label.
      # @param timestamp [Time] entry timestamp
      # @param time_bucket [String] bucket mode
      # @return [String]
      def format_time_bucket(timestamp, time_bucket)
        utc_time = timestamp.utc

        case time_bucket
        when "minute"
          utc_time.strftime("%Y-%m-%dT%H:%M:00Z")
        when "hour"
          utc_time.strftime("%Y-%m-%dT%H:00:00Z")
        else
          raise ArgumentError, "Unsupported time bucket: #{time_bucket}"
        end
      end
    end
  end
end
