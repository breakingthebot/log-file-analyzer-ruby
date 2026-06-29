# Parses supported log files into structured entries.
# Connects to: src/services/line_parser_factory.rb, src/utils/logger_factory.rb.
# Created: 2026-06-29

require_relative "line_parser_factory"

module LogFileAnalyzer
  module Services
    # Parses supported log formats by delegating line parsing to format-specific handlers.
    class LogParser
      # Builds a parser with a logger.
      # @param logger [Logger] diagnostic logger
      # @param input_format [String] requested input format
      def initialize(logger:, input_format: "auto")
        @logger = logger
        @line_parsers = LineParserFactory.build(input_format)
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
        @line_parsers.each do |line_parser|
          entry = line_parser.parse(line)
          return entry if entry
        end

        nil
      end
    end
  end
end
