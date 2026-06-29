# Entry point for the Ruby log file analyzer CLI.
# Connects to: src/config/version.rb, src/services/log_parser.rb, src/services/log_analyzer.rb, src/utils/report_formatter.rb.
# Created: 2026-06-29

require "optparse"
require "time"

require_relative "config/version"
require_relative "config/time_bucket_options"
require_relative "services/log_parser"
require_relative "services/log_analyzer"
require_relative "services/time_window_filter"
require_relative "utils/config_loader"
require_relative "utils/input_path_resolver"
require_relative "utils/logger_factory"
require_relative "utils/output_writer"
require_relative "utils/report_formatter"
require_relative "utils/time_window_parser"

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
      file_paths = Utils::InputPathResolver.new.resolve!(options[:input_paths], logger: logger)
      time_window = Utils::TimeWindowParser.new.parse(
        start_time_text: options[:start_time],
        end_time_text: options[:end_time]
      )

      entries = Services::LogParser.new(logger: logger, input_format: options[:input_format]).parse_files(file_paths)
      filtered_entries = Services::TimeWindowFilter.new.filter(
        entries,
        start_time: time_window[:start_time],
        end_time: time_window[:end_time]
      )
      summary = Services::LogAnalyzer.new.summarize(filtered_entries, time_bucket: options[:time_bucket])
      report = Utils::ReportFormatter.new(top_limit: options[:top]).format(summary, format: options[:format])
      output_path = Utils::OutputWriter.new.write(report, output_path: options[:output_path], logger: logger)
      puts "Report written to #{output_path}" unless output_path.nil?
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
      default_options = {
        format: "text",
        input_format: "auto",
        time_bucket: "none",
        top: Utils::ReportFormatter::DEFAULT_TOP_LIMIT
      }
      cli_options = {}

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: log-file-analyzer [options] LOG_PATH [LOG_PATH ...]"

        opts.on("--format FORMAT", %w[text json csv], "Output format: text, json, or csv") do |format|
          cli_options[:format] = format
        end

        opts.on("--input-format FORMAT", Services::LineParserFactory::SUPPORTED_FORMATS, "Input format: auto, common, or json") do |input_format|
          cli_options[:input_format] = input_format
        end

        opts.on("--start-time TIME", "Inclusive ISO 8601 start time filter") do |start_time|
          cli_options[:start_time] = start_time
        end

        opts.on("--end-time TIME", "Inclusive ISO 8601 end time filter") do |end_time|
          cli_options[:end_time] = end_time
        end

        opts.on("--top COUNT", Integer, "Number of top endpoints to display") do |count|
          raise OptionParser::InvalidArgument, "Top count must be positive." if count <= 0

          cli_options[:top] = count
        end

        opts.on("--time-bucket BUCKET", LogFileAnalyzer::Config::TIME_BUCKET_OPTIONS, "Time bucket: none, minute, or hour") do |time_bucket|
          cli_options[:time_bucket] = time_bucket
        end

        opts.on("--output PATH", "Optional output file path for the rendered report") do |output_path|
          cli_options[:output_path] = output_path
        end

        opts.on("--config PATH", "Optional YAML config file path") do |config_path|
          cli_options[:config_path] = config_path
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
      config_options = Utils::ConfigLoader.new.load(cli_options[:config_path])
      config_options[:input_paths] = remaining unless remaining.empty?

      merge_options(default_options, config_options, cli_options)
    end

    # Merges defaults, config values, and CLI values using increasing precedence.
    # @param default_options [Hash] built-in defaults
    # @param config_options [Hash] loaded config values
    # @param cli_options [Hash] explicit CLI values
    # @return [Hash]
    def merge_options(default_options, config_options, cli_options)
      default_options
        .merge(config_options)
        .merge(cli_options)
    end
  end
end
