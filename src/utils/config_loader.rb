# Loads optional CLI defaults from a local YAML config file.
# Connects to: src/main.rb, README.md, .log-file-analyzer.yml.
# Created: 2026-06-29

require "yaml"

module LogFileAnalyzer
  module Utils
    # Reads and normalizes supported config values from disk.
    class ConfigLoader
      DEFAULT_CONFIG_PATH = ".log-file-analyzer.yml"
      ALLOWED_KEYS = %w[format input_format top start_time end_time input_paths].freeze

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
        config = payload.each_with_object({}) do |(key, value), result|
          string_key = key.to_s
          next unless ALLOWED_KEYS.include?(string_key)

          result[string_key.to_sym] = value
        end

        normalize_input_paths!(config)
        normalize_top!(config)
        config
      end

      # Normalizes config input paths to an array of strings.
      # @param config [Hash] config hash being normalized
      # @return [void]
      def normalize_input_paths!(config)
        return unless config.key?(:input_paths)

        config[:input_paths] = Array(config[:input_paths]).map(&:to_s)
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
    end
  end
end
