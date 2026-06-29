# Parses Apache and Nginx common log lines into log entries.
# Connects to: src/models/log_entry.rb, src/services/log_parser.rb.
# Created: 2026-06-29

require_relative "../../models/log_entry"

module LogFileAnalyzer
  module Services
    module LineParsers
      # Parses one common-log-format line.
      class CommonLogLineParser
        LOG_PATTERN = /
          ^
          \S+\s+\S+\s+\S+\s+
          \[[^\]]+\]\s+
          "(?<method>[A-Z]+)\s+(?<endpoint>\S+)(?:\s+[^"]+)?"\s+
          (?<status>\d{3})\s+
          \S+
        /x.freeze

        # Parses a line into a LogEntry when the format matches.
        # @param line [String] raw log line
        # @return [LogEntry, nil]
        def parse(line)
          match_data = LOG_PATTERN.match(line)
          return nil unless match_data

          LogEntry.new(
            http_method: match_data[:method],
            endpoint: normalize_endpoint(match_data[:endpoint]),
            status_code: match_data[:status].to_i
          )
        end

        private

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
