# Writes rendered analyzer reports to stdout or a file path.
# Connects to: src/main.rb, src/utils/report_formatter.rb.
# Created: 2026-06-29

module LogFileAnalyzer
  module Utils
    # Handles report delivery to stdout or the filesystem.
    class OutputWriter
      # Writes a report to stdout when no output path is provided, otherwise to a file.
      # @param report [String] rendered report content
      # @param output_path [String, nil] optional output file path
      # @param logger [Logger] diagnostic logger
      # @return [String, nil] expanded output path when written to disk
      def write(report, output_path:, logger:)
        return write_to_stdout(report) if output_path.nil? || output_path.strip.empty?

        expanded_path = File.expand_path(output_path)
        validate_parent_directory!(expanded_path, logger: logger)
        File.write(expanded_path, report)
        logger.info("Report written to #{expanded_path}")
        expanded_path
      end

      private

      # Writes a report to stdout.
      # @param report [String] rendered report content
      # @return [nil]
      def write_to_stdout(report)
        puts report
        nil
      end

      # Verifies the target directory exists before writing.
      # @param output_path [String] expanded output file path
      # @param logger [Logger] diagnostic logger
      # @return [void]
      def validate_parent_directory!(output_path, logger:)
        directory_path = File.dirname(output_path)
        return if Dir.exist?(directory_path)

        logger.error("Output directory does not exist: #{directory_path}")
        raise ArgumentError, "Output directory does not exist: #{directory_path}"
      end
    end
  end
end
