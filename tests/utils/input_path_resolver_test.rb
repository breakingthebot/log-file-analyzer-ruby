# Tests CLI input path expansion for files and directories.
# Connects to: src/utils/input_path_resolver.rb, src/main.rb.
# Created: 2026-06-29

require_relative "../test_helper"
require "stringio"

module LogFileAnalyzer
  module Utils
    class InputPathResolverTest < Minitest::Test
      # Verifies a directory expands into supported log files in stable order.
      # @return [void]
      def test_resolve_directory_returns_supported_files_only
        resolver = InputPathResolver.new

        resolved_paths = resolver.resolve!([fixture_path("batch")], logger: logger)

        assert_equal 5, resolved_paths.length
        assert_equal fixture_path("batch/common-a.log"), resolved_paths[0]
        assert_equal fixture_path("batch/common-b.log"), resolved_paths[1]
        assert_equal fixture_path("batch/common-c.log.gz"), resolved_paths[2]
        assert_equal fixture_path("batch/structured.jsonl"), resolved_paths[3]
        assert_equal fixture_path("batch/structured.jsonl.gz"), resolved_paths[4]
      end

      # Verifies duplicate file references are only counted once.
      # @return [void]
      def test_resolve_removes_duplicate_files
        resolver = InputPathResolver.new

        resolved_paths = resolver.resolve!(
          [fixture_path("batch"), fixture_path("batch/common-a.log")],
          logger: logger
        )

        assert_equal 5, resolved_paths.length
      end

      # Verifies missing input raises a clear error.
      # @return [void]
      def test_resolve_requires_at_least_one_path
        resolver = InputPathResolver.new

        error = assert_raises(ArgumentError) do
          resolver.resolve!([], logger: logger)
        end

        assert_equal "At least one log file or directory path is required.", error.message
      end

      private

      # Builds a logger that keeps test output quiet.
      # @return [Logger]
      def logger
        @logger ||= Utils.build_logger(stream: StringIO.new)
      end

      # Resolves a fixture path for the current test suite.
      # @param relative_path [String] fixture path suffix
      # @return [String]
      def fixture_path(relative_path)
        File.expand_path("../fixtures/#{relative_path}", __dir__)
      end
    end
  end
end
