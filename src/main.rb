# Entry point for the Ruby log file analyzer CLI.
# Connects to: src/config/version.rb, src/services/log_parser.rb, src/services/log_analyzer.rb, src/utils/report_formatter.rb.
# Created: 2026-06-29

require "optparse"
require "time"

require_relative "config/version"
require_relative "services/log_parser"
require_relative "services/log_analyzer"
require_relative "utils/logger_factory"
require_relative "utils/path_validator"
require_relative "utils/report_formatter"

module LogFileAnalyzer
  # Coordinates CLI argument parsing and report generation.
  module Main
    module_function

    # Runs the CLI with the provided arguments.
    # @param argv [Array<String>] command line arguments
    # @return [Integer] process exit code
    def run(argv)
      logger = Utils.build_logger
      options = parse_options(argv)
      file_path = Utils.validate_log_file!(options[:file_path], logger: logger)

      entries = Services::LogParser.new(logger: logger).parse_file(file_path)
      summary = Services::LogAnalyzer.new.summarize(entries)
      report = Utils::ReportFormatter.new(top_limit: options[:top]).format(summary, format: options[:format])

      puts report
      0
    rescue OptionParser::ParseError, ArgumentError => e
      logger&.error(e.message)
      warn(e.message)
      1
    end

    # Parses CLI flags into a simple options hash.
    # @param argv [Array<String>] command line arguments
    # @return [Hash]
    def parse_options(argv)
      options = { format: "text", top: Utils::ReportFormatter::DEFAULT_TOP_LIMIT }

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: log-file-analyzer [options] LOG_FILE"

        opts.on("--format FORMAT", %w[text json], "Output format: text or json") do |format|
          options[:format] = format
        end

        opts.on("--top COUNT", Integer, "Number of top endpoints to display") do |count|
          raise OptionParser::InvalidArgument, "Top count must be positive." if count <= 0

          options[:top] = count
        end

        opts.on("--version", "Print the application version") do
          puts LogFileAnalyzer::VERSION
          exit 0
        end

        opts.on("-h", "--help", "Show help") do
          puts opts
          exit 0
        end
      end

      remaining = parser.parse(argv)
      options[:file_path] = remaining.first
      options
    end
  end
end
