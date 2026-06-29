# Parses newline-delimited JSON log lines into log entries.
# Connects to: src/models/log_entry.rb, src/services/log_parser.rb.
# Created: 2026-06-29

require "json"
require "time"
require_relative "../../models/log_entry"

module LogFileAnalyzer
  module Services
    module LineParsers
      # Parses one structured JSON log line.
      class JsonLogLineParser
        METHOD_KEYS = %w[method http_method request_method].freeze
        ENDPOINT_KEYS = %w[endpoint path request_path url].freeze
        STATUS_KEYS = %w[status status_code response_status].freeze
        TIMESTAMP_KEYS = %w[timestamp time occurred_at requested_at].freeze

        # Parses a line into a LogEntry when the format matches.
        # @param line [String] raw log line
        # @return [LogEntry, nil]
        def parse(line)
          payload = JSON.parse(line)
          method = fetch_value(payload, METHOD_KEYS)
          endpoint = fetch_value(payload, ENDPOINT_KEYS)
          status_code = fetch_value(payload, STATUS_KEYS)
          timestamp = fetch_value(payload, TIMESTAMP_KEYS)
          return nil if method.nil? || endpoint.nil? || status_code.nil? || timestamp.nil?

          LogEntry.new(
            http_method: method.to_s.upcase,
            endpoint: normalize_endpoint(endpoint.to_s),
            status_code: Integer(status_code),
            timestamp: Time.iso8601(timestamp.to_s)
          )
        rescue JSON::ParserError
          nil
        rescue ArgumentError
          nil
        end

        private

        # Fetches the first present value from the candidate key list.
        # @param payload [Hash] parsed JSON object
        # @param keys [Array<String>] candidate keys
        # @return [Object, nil]
        def fetch_value(payload, keys)
          keys.each do |key|
            return payload[key] if payload.key?(key)
          end

          nil
        end

        # Removes query strings so endpoint counts stay consistent.
        # @param endpoint [String] raw request target
        # @return [String]
        def normalize_endpoint(endpoint)
          endpoint.split("?").first
        end
      end
    end
  end
end
