# Accumulates analyzer summary metrics incrementally from streamed log entries.
# Connects to: src/services/log_analyzer.rb, src/models/log_entry.rb.
# Created: 2026-06-30

module LogFileAnalyzer
  module Services
    # Tracks request, error, endpoint, and bucket metrics without storing every entry.
    class SummaryAccumulator
      ERROR_STATUS_START = 400
      STATUS_FAMILY_DIVISOR = 100

      # Builds an accumulator for the requested bucket and series modes.
      # @param time_bucket [String] bucket mode: none, minute, or hour
      # @param time_bucket_series [String] series mode: none, method, or status-family
      def initialize(time_bucket:, time_bucket_series:)
        @time_bucket = time_bucket
        @time_bucket_series = time_bucket_series
        @total_requests = 0
        @error_requests = 0
        @endpoint_counts = Hash.new(0)
        @method_counts = Hash.new(0)
        @status_code_counts = Hash.new(0)
        @status_family_counts = Hash.new(0)
        @time_bucket_counts = Hash.new { |hash, key| hash[key] = { requests: 0, errors: 0, series_counts: Hash.new(0) } }
      end

      # Adds one parsed entry into the running summary state.
      # @param entry [LogEntry] parsed log entry
      # @return [void]
      def add(entry)
        @total_requests += 1
        @error_requests += 1 if error_status?(entry.status_code)
        @endpoint_counts[entry.endpoint] += 1
        @method_counts[entry.http_method] += 1
        @status_code_counts[entry.status_code] += 1
        @status_family_counts[status_family_label(entry.status_code)] += 1
        add_time_bucket_entry(entry)
      end

      # Builds the final summary hash from the accumulated counts.
      # @return [Hash]
      def summary
        {
          "total_requests" => @total_requests,
          "error_requests" => @error_requests,
          "error_rate" => calculate_error_rate,
          "methods" => build_breakdown(@method_counts),
          "status_families" => build_breakdown(@status_family_counts),
          "status_codes" => build_breakdown(@status_code_counts),
          "time_buckets" => build_time_buckets,
          "top_endpoints" => @endpoint_counts
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

      # Calculates the final error percentage.
      # @return [Float]
      def calculate_error_rate
        return 0.0 if @total_requests.zero?

        (@error_requests.to_f / @total_requests * 100).round(2)
      end

      # Converts a status code into a status family label.
      # @param status_code [Integer] response status code
      # @return [String]
      def status_family_label(status_code)
        "#{status_code / STATUS_FAMILY_DIVISOR}xx"
      end

      # Adds one entry into the running time-bucket aggregates when enabled.
      # @param entry [LogEntry] parsed log entry
      # @return [void]
      def add_time_bucket_entry(entry)
        return if @time_bucket == "none"
        return if entry.timestamp.nil?

        bucket_label = format_time_bucket(entry.timestamp)
        @time_bucket_counts[bucket_label][:requests] += 1
        @time_bucket_counts[bucket_label][:errors] += 1 if error_status?(entry.status_code)
        series_label = resolve_time_bucket_series_label(entry)
        @time_bucket_counts[bucket_label][:series_counts][series_label] += 1 unless series_label.nil?
      end

      # Sorts a count hash into a stable array for output.
      # @param counts [Hash] raw count hash
      # @return [Array<Hash>]
      def build_breakdown(counts)
        counts
          .sort_by { |label, count| [-count, label.to_s] }
          .map { |label, count| { "label" => label.to_s, "requests" => count } }
      end

      # Builds the final chronological bucket series.
      # @return [Array<Hash>]
      def build_time_buckets
        return [] if @time_bucket == "none"

        @time_bucket_counts
          .sort_by { |label, _counts| label }
          .map do |label, counts|
            {
              "label" => label,
              "requests" => counts[:requests],
              "errors" => counts[:errors],
              "series" => build_breakdown(counts[:series_counts])
            }
          end
      end

      # Formats a timestamp into the selected bucket label.
      # @param timestamp [Time] entry timestamp
      # @return [String]
      def format_time_bucket(timestamp)
        utc_time = timestamp.utc

        case @time_bucket
        when "minute"
          utc_time.strftime("%Y-%m-%dT%H:%M:00Z")
        when "hour"
          utc_time.strftime("%Y-%m-%dT%H:00:00Z")
        else
          raise ArgumentError, "Unsupported time bucket: #{@time_bucket}"
        end
      end

      # Resolves the series label for the configured bucket series mode.
      # @param entry [LogEntry] parsed log entry
      # @return [String, nil]
      def resolve_time_bucket_series_label(entry)
        case @time_bucket_series
        when "none"
          nil
        when "method"
          entry.http_method
        when "status-family"
          status_family_label(entry.status_code)
        else
          raise ArgumentError, "Unsupported time bucket series: #{@time_bucket_series}"
        end
      end
    end
  end
end
