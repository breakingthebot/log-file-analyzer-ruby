# Resolves CLI input paths into a stable list of log files.
# Connects to: src/main.rb, src/services/log_parser.rb.
# Created: 2026-06-29

module LogFileAnalyzer
  module Utils
    # Expands file and directory inputs into supported log files.
    class InputPathResolver
      SUPPORTED_PATTERNS = ["*.jsonl", "*.log", "*.jsonl.gz", "*.log.gz"].freeze

      # Resolves one or more CLI input paths into absolute file paths.
      # @param input_paths [Array<String>] user-provided paths
      # @param logger [Logger] diagnostic logger
      # @return [Array<String>]
      def resolve!(input_paths, logger:)
        if input_paths.nil? || input_paths.empty? || input_paths.all? { |path| path.nil? || path.strip.empty? }
          raise ArgumentError, "At least one log file or directory path is required."
        end

        resolved_paths = input_paths.flat_map do |input_path|
          resolve_one_path!(input_path, logger: logger)
        end

        resolved_paths.uniq
      end

      private

      # Resolves one path into one or more supported file paths.
      # @param input_path [String] user-provided path
      # @param logger [Logger] diagnostic logger
      # @return [Array<String>]
      def resolve_one_path!(input_path, logger:)
        expanded_path = File.expand_path(input_path)

        unless File.exist?(expanded_path)
          logger.error("Input path does not exist: #{expanded_path}")
          raise ArgumentError, "Input path does not exist: #{expanded_path}"
        end

        return [expanded_path] if File.file?(expanded_path)
        return resolve_directory!(expanded_path, logger: logger) if File.directory?(expanded_path)

        logger.error("Input path is not a regular file or directory: #{expanded_path}")
        raise ArgumentError, "Input path is not a regular file or directory: #{expanded_path}"
      end

      # Resolves a directory into supported log files in stable order.
      # @param directory_path [String] absolute directory path
      # @param logger [Logger] diagnostic logger
      # @return [Array<String>]
      def resolve_directory!(directory_path, logger:)
        file_paths = Dir.children(directory_path)
          .map { |entry| File.join(directory_path, entry) }
          .select { |path| File.file?(path) && supported_file?(path) }
          .sort

        if file_paths.empty?
          logger.error("Directory contains no supported log files: #{directory_path}")
          raise ArgumentError, "Directory contains no supported log files: #{directory_path}"
        end

        file_paths
      end

      # Checks whether a file path matches the supported log file extensions.
      # @param file_path [String] absolute file path
      # @return [Boolean]
      def supported_file?(file_path)
        SUPPORTED_PATTERNS.any? do |pattern|
          File.fnmatch?(pattern, File.basename(file_path))
        end
      end
    end
  end
end
