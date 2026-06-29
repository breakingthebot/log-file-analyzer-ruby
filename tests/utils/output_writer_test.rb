# Tests report writing to stdout and filesystem targets.
# Connects to: src/utils/output_writer.rb, src/main.rb.
# Created: 2026-06-29

require_relative "../test_helper"
require "stringio"
require "tmpdir"

module LogFileAnalyzer
  module Utils
    class OutputWriterTest < Minitest::Test
      # Verifies the writer stores reports on disk when an output path is provided.
      # @return [void]
      def test_write_persists_report_to_file
        Dir.mktmpdir do |directory_path|
          output_path = File.join(directory_path, "report.txt")

          written_path = OutputWriter.new.write("hello report", output_path: output_path, logger: logger)

          assert_equal output_path, written_path
          assert_equal "hello report", File.read(output_path)
        end
      end

      # Verifies missing output directories fail with a clear error.
      # @return [void]
      def test_write_rejects_missing_output_directory
        Dir.mktmpdir do |directory_path|
          output_path = File.join(directory_path, "missing", "report.txt")

          error = assert_raises(ArgumentError) do
            OutputWriter.new.write("hello report", output_path: output_path, logger: logger)
          end

          assert_equal "Output directory does not exist: #{File.dirname(output_path)}", error.message
        end
      end

      private

      # Builds a logger that keeps test output quiet.
      # @return [Logger]
      def logger
        @logger ||= Utils.build_logger(stream: StringIO.new)
      end
    end
  end
end
