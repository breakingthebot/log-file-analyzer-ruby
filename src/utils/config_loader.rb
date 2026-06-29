# Loads optional CLI defaults from a local YAML config file.
# Connects to: src/main.rb, README.md, .log-file-analyzer.yml.
# Created: 2026-06-29

require "yaml"
require_relative "../config/time_bucket_options"
require_relative "../services/line_parser_factory"

module LogFileAnalyzer
  module Utils
    # Reads and normalizes supported config values from disk.
    class ConfigLoader
      DEFAULT_CONFIG_PATH = ".log-file-analyzer.yml"
      ALLOWED_KEYS = %w[format input_format top start_time end_time input_paths time_bucket output_path].freeze
      FORMAT_OPTIONS = %w[text json csv].freeze

      # Loads config values from a YAML file when it exists.
      # @param config_path [String, nil] optional config path override
      # @return [Hash]
      def load(config_path = nil)
        resolved_path = File.expand_path(config_path || DEFAULT_CONFIG_PATH)
        return {} unless File.exist?(resolved_path)

        payload = YAML.safe_load_file(resolved_path, permitted_classes: [], aliases: false)
        return {} if payload.nil?
        raise ArgumentError, "Config file must contain a top-level mapping." unless payload.is_a?(Hash)

        normalize_config(payload)
      rescue Psych::SyntaxError => e
        raise ArgumentError, "Invalid config file syntax: #{e.message}"
      end

      private

      # Normalizes supported keys into the internal option shape.
      # @param payload [Hash] raw YAML mapping
      # @return [Hash]
      def normalize_config(payload)
        reject_unsupported_keys!(payload)

        config = payload.each_with_object({}) do |(key, value), result|
          string_key = key.to_s
          result[string_key.to_sym] = value
        end

        normalize_format!(config)
        normalize_input_format!(config)
        normalize_input_paths!(config)
        normalize_output_path!(config)
        normalize_top!(config)
        normalize_time_bucket!(config)
        config
      end

      # Rejects unknown config keys so shared defaults fail loudly.
      # @param payload [Hash] raw YAML mapping
      # @return [void]
      def reject_unsupported_keys!(payload)
        unsupported_keys = payload.keys.map(&:to_s) - ALLOWED_KEYS
        return if unsupported_keys.empty?

        raise ArgumentError, "Unsupported config keys: #{unsupported_keys.sort.join(', ')}."
      end

      # Validates the configured output format.
      # @param config [Hash] config hash being normalized
      # @return [void]
      def normalize_format!(config)
        return unless config.key?(:format)

        config[:format] = config[:format].to_s
        return if FORMAT_OPTIONS.include?(config[:format])

        raise ArgumentError, "Config value for format must be one of: #{FORMAT_OPTIONS.join(', ')}."
      end

      # Validates the configured input format.
      # @param config [Hash] config hash being normalized
      # @return [void]
      def normalize_input_format!(config)
        return unless config.key?(:input_format)

        config[:input_format] = config[:input_format].to_s
        return if LogFileAnalyzer::Services::LineParserFactory::SUPPORTED_FORMATS.include?(config[:input_format])

        raise ArgumentError, "Config value for input_format must be one of: #{LogFileAnalyzer::Services::LineParserFactory::SUPPORTED_FORMATS.join(', ')}."
      end

      # Normalizes config input paths to an array of strings.
      # @param config [Hash] config hash being normalized
      # @return [void]
      def normalize_input_paths!(config)
        return unless config.key?(:input_paths)

        unless config[:input_paths].is_a?(String) || config[:input_paths].is_a?(Array)
          raise ArgumentError, "Config value for input_paths must be a string or an array of strings."
        end

        config[:input_paths] = Array(config[:input_paths]).map do |value|
          value.to_s
        end

        if config[:input_paths].any? { |value| value.strip.empty? }
          raise ArgumentError, "Config value for input_paths cannot contain blank paths."
        end
      end

      # Validates the configured output path value.
      # @param config [Hash] config hash being normalized
      # @return [void]
      def normalize_output_path!(config)
        return unless config.key?(:output_path)

        config[:output_path] = config[:output_path].to_s
        return unless config[:output_path].strip.empty?

        raise ArgumentError, "Config value for output_path cannot be blank."
      end

      # Validates and normalizes the configured top count.
      # @param config [Hash] config hash being normalized
      # @return [void]
      def normalize_top!(config)
        return unless config.key?(:top)

        config[:top] = Integer(config[:top])
        raise ArgumentError, "Config value for top must be a positive integer." if config[:top] <= 0
      rescue ArgumentError, TypeError
        raise ArgumentError, "Config value for top must be a positive integer."
      end

      # Validates the configured time bucket value.
      # @param config [Hash] config hash being normalized
      # @return [void]
      def normalize_time_bucket!(config)
        return unless config.key?(:time_bucket)

        config[:time_bucket] = config[:time_bucket].to_s
        return if LogFileAnalyzer::Config::TIME_BUCKET_OPTIONS.include?(config[:time_bucket])

        raise ArgumentError, "Config value for time_bucket must be one of: #{LogFileAnalyzer::Config::TIME_BUCKET_OPTIONS.join(', ')}."
      end
    end
  end
end
