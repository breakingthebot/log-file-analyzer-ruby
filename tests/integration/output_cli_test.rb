# Tests CLI report writing behavior when an output file is requested.
# Connects to: src/main.rb, src/utils/output_writer.rb.
# Created: 2026-06-29

require_relative "../test_helper"
require "tmpdir"

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

    private

    # Resolves a fixture path for the current test suite.
    # @param file_name [String] fixture file name
    # @return [String]
    def fixture_path(file_name)
      File.expand_path("../fixtures/#{file_name}", __dir__)
    end
  end
end
