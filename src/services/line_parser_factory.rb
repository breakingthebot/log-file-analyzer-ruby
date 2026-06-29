# Chooses the right line parser set for a requested input format.
# Connects to: src/services/log_parser.rb, src/services/line_parsers/*.
# Created: 2026-06-29

require_relative "line_parsers/common_log_line_parser"
require_relative "line_parsers/json_log_line_parser"

module LogFileAnalyzer
  module Services
    # Builds the parser chain for a supported input format.
    class LineParserFactory
      SUPPORTED_FORMATS = %w[auto common json].freeze

      # Builds parser objects for the requested input format.
      # @param input_format [String] requested parser mode
      # @return [Array<Object>]
      def self.build(input_format)
        case input_format
        when "auto"
          [LineParsers::JsonLogLineParser.new, LineParsers::CommonLogLineParser.new]
        when "common"
          [LineParsers::CommonLogLineParser.new]
        when "json"
          [LineParsers::JsonLogLineParser.new]
        else
          raise ArgumentError, "Unsupported input format: #{input_format}"
        end
      end
    end
  end
end
