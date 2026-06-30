# Detects the most likely parser mode for an input file.
# Connects to: src/services/log_parser.rb, src/services/line_parser_factory.rb.
# Created: 2026-06-29

require_relative "../utils/input_file_reader"

module LogFileAnalyzer
  module Services
    # Chooses a parser mode for one file using extension and sample content.
    class FileFormatDetector
      JSON_EXTENSION = ".jsonl"
      JSON_GZIP_EXTENSION = ".jsonl.gz"
      COMMON_EXTENSION = ".log"
      COMMON_GZIP_EXTENSION = ".log.gz"
      SAMPLE_LINE_LIMIT = 10

      # Builds a detector with a logger and parser factory.
      # @param logger [Logger] diagnostic logger
      def initialize(logger:)
        @logger = logger
      end

      # Detects the parser mode for one file.
      # @param file_path [String] path to the input file
      # @return [String]
      def detect(file_path)
        extension_format = detect_from_extension(file_path)
        return extension_format unless extension_format.nil?

        detected_format = detect_from_content(file_path)
        return detected_format unless detected_format.nil?

        @logger.info("Defaulting file format to common for #{file_path}")
        "common"
      end

      private

      # Detects a format by probing the first parseable lines in the file.
      # @param file_path [String] path to the input file
      # @return [String, nil]
      def detect_from_content(file_path)
        parser_candidates = {
          "json" => LineParserFactory.build("json"),
          "common" => LineParserFactory.build("common")
        }

        LogFileAnalyzer::Utils::InputFileReader.each_line(file_path).with_index do |line, index|
          break if index >= SAMPLE_LINE_LIMIT

          parser_candidates.each do |format, parsers|
            return format if parsers.any? { |parser| parser.parse(line) }
          end
        end

        nil
      end

      # Detects a format from a known file extension or compressed extension.
      # @param file_path [String] path to the input file
      # @return [String, nil]
      def detect_from_extension(file_path)
        normalized_path = file_path.downcase
        return "json" if normalized_path.end_with?(JSON_EXTENSION, JSON_GZIP_EXTENSION)
        return "common" if normalized_path.end_with?(COMMON_EXTENSION, COMMON_GZIP_EXTENSION)

        nil
      end
    end
  end
end
