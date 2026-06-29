# Parses common access log lines into structured entries.
# Connects to: src/models/log_entry.rb, src/utils/logger_factory.rb.
# Created: 2026-06-29

require_relative "../models/log_entry"

module LogFileAnalyzer
  module Services
    # Parses Apache or Nginx style common log lines.
    class LogParser
      LOG_PATTERN = /
        ^
        \S+\s+\S+\s+\S+\s+
        \[[^\]]+\]\s+
        "(?<method>[A-Z]+)\s+(?<endpoint>\S+)(?:\s+[^"]+)?"\s+
        (?<status>\d{3})\s+
        \S+
      /x.freeze

      # Builds a parser with a logger.
      # @param logger [Logger] diagnostic logger
      def initialize(logger:)
        @logger = logger
      end

      # Parses a log file into valid log entries.
      # @param file_path [String] path to the log file
      # @return [Array<LogEntry>]
      def parse_file(file_path)
        entries = []

        File.foreach(file_path).with_index(1) do |line, line_number|
          entry = parse_line(line)
          entries << entry if entry
        rescue StandardError => e
          @logger.warn("Failed to parse line #{line_number}: #{e.message}")
        end

        entries
      end

      private

      # Parses one log line into a LogEntry.
      # @param line [String] raw log line
      # @return [LogEntry, nil]
      def parse_line(line)
        match_data = LOG_PATTERN.match(line)
        return nil unless match_data

        LogEntry.new(
          http_method: match_data[:method],
          endpoint: normalize_endpoint(match_data[:endpoint]),
          status_code: match_data[:status].to_i
        )
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
