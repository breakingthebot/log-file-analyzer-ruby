# Tests CLI report writing behavior when an output file is requested.
# Connects to: src/main.rb, src/utils/output_writer.rb.
# Created: 2026-06-29

require_relative "../test_helper"
require "tmpdir"
require "open3"
require "rbconfig"

module LogFileAnalyzer
  class OutputCliTest < Minitest::Test
    # Verifies the CLI writes a rendered report to the requested file path.
    # @return [void]
    def test_run_writes_report_to_output_file
      Dir.mktmpdir do |directory_path|
        output_path = File.join(directory_path, "report.csv")

        exit_code = Main.run(
          [
            "--format", "csv",
            "--output", output_path,
            fixture_path("server.log")
          ]
        )

        assert_equal 0, exit_code
        assert File.exist?(output_path)
        assert_includes File.read(output_path), "section,label,requests,value"
      end
    end

    # Verifies the CLI can analyze a gzip-compressed log file through the main entry point.
    # @return [void]
    def test_run_accepts_gzip_input_file
      exit_code = Main.run([fixture_path("server.log.gz")])

      assert_equal 0, exit_code
    end

    # Verifies the executable preserves the threshold failure exit code contract.
    # @return [void]
    def test_executable_returns_threshold_exit_code
      _stdout, _stderr, status = Open3.capture3(
        RbConfig.ruby,
        executable_path,
        "--max-error-rate",
        "30",
        fixture_path("server.log")
      )

      assert_equal Main::THRESHOLD_FAILURE_EXIT_CODE, status.exitstatus
    end

    # Verifies the CLI can render a comparison report to JSON output.
    # @return [void]
    def test_run_writes_comparison_report_to_output_file
      Dir.mktmpdir do |directory_path|
        output_path = File.join(directory_path, "comparison.json")

        exit_code = Main.run(
          [
            "--format", "json",
            "--output", output_path,
            "--compare-to", fixture_path("batch/common-a.log"),
            fixture_path("server.log")
          ]
        )

        assert_equal 0, exit_code
        report = JSON.parse(File.read(output_path))
        assert_equal "comparison", report["report_type"]
        assert_equal 5, report["current"]["total_requests"]
        assert_equal 2, report["comparison"]["total_requests"]
      end
    end

    private

    # Resolves a fixture path for the current test suite.
    # @param file_name [String] fixture file name
    # @return [String]
    def fixture_path(file_name)
      File.expand_path("../fixtures/#{file_name}", __dir__)
    end

    # Resolves the CLI executable path under the repository root.
    # @return [String]
    def executable_path
      File.expand_path("../../exe/log-file-analyzer", __dir__)
    end
  end
end
