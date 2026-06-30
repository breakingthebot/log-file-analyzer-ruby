# Parses supported log files into structured entries.
# Connects to: src/services/line_parser_factory.rb, src/utils/logger_factory.rb.
# Created: 2026-06-29

require_relative "file_format_detector"
require_relative "line_parser_factory"
require_relative "../utils/input_file_reader"

module LogFileAnalyzer
  module Services
    # Parses supported log formats by delegating line parsing to format-specific handlers.
    class LogParser
      # Builds a parser with a logger.
      # @param logger [Logger] diagnostic logger
      # @param input_format [String] requested input format
      def initialize(logger:, input_format: "auto")
        @logger = logger
        @input_format = input_format
        @line_parsers = build_line_parsers(input_format)
        @file_format_detector = FileFormatDetector.new(logger: logger)
      end

      # Parses a log file into valid log entries.
      # @param file_path [String] path to the log file
      # @return [Array<LogEntry>]
      def parse_file(file_path)
        entries = []
        file_line_parsers = resolve_line_parsers(file_path)

        Utils::InputFileReader.each_line(file_path).with_index(1) do |line, line_number|
          entry = parse_line(line, file_line_parsers)
          entries << entry if entry
        rescue StandardError => e
          @logger.warn("Failed to parse line #{line_number}: #{e.message}")
        end

        entries
      end

      # Parses multiple log files into one combined entry list.
      # @param file_paths [Array<String>] paths to the log files
      # @return [Array<LogEntry>]
      def parse_files(file_paths)
        file_paths.flat_map { |file_path| parse_file(file_path) }
      end

      private

      # Parses one log line into a LogEntry.
      # @param line [String] raw log line
      # @param line_parsers [Array<Object>] parser candidates for the current file
      # @return [LogEntry, nil]
      def parse_line(line, line_parsers)
        line_parsers.each do |line_parser|
          entry = line_parser.parse(line)
          return entry if entry
        end

        nil
      end

      # Resolves the parser chain for one file.
      # @param file_path [String] path to the input file
      # @return [Array<Object>]
      def resolve_line_parsers(file_path)
        return @line_parsers unless @input_format == "auto"

        detected_format = @file_format_detector.detect(file_path)
        build_line_parsers(detected_format)
      end

      # Builds the parser chain for a specific format.
      # @param input_format [String] requested parser mode
      # @return [Array<Object>]
      def build_line_parsers(input_format)
        LineParserFactory.build(input_format)
      end
    end
  end
end
