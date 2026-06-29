# Validates CLI file paths before log processing begins.
# Connects to: src/main.rb, src/services/log_parser.rb.
# Created: 2026-06-29

module LogFileAnalyzer
  module Utils
    # Validates a requested log file path.
    # @param file_path [String] user-provided log file path
    # @param logger [Logger] diagnostic logger
    # @return [String] expanded path
    def self.validate_log_file!(file_path, logger:)
      raise ArgumentError, "Log file path is required." if file_path.nil? || file_path.strip.empty?

      expanded_path = File.expand_path(file_path)

      unless File.exist?(expanded_path)
        logger.error("Log file does not exist: #{expanded_path}")
        raise ArgumentError, "Log file does not exist: #{expanded_path}"
      end

      unless File.file?(expanded_path)
        logger.error("Log path is not a file: #{expanded_path}")
        raise ArgumentError, "Log path is not a file: #{expanded_path}"
      end

      expanded_path
    end
  end
end
