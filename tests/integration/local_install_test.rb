# Tests the repo-local gem install workflow and installed executable path.
# Connects to: bin/install, bin/uninstall, src/utils/local_gem_installation.rb.
# Created: 2026-06-29

require_relative "../test_helper"
require "fileutils"
require "open3"
require "rbconfig"

module LogFileAnalyzer
  class LocalInstallTest < Minitest::Test
    # Verifies the packaged gem can be installed locally and run through its installed command.
    # @return [void]
    def test_local_install_exposes_a_working_version_command
      uninstall_local_package

      stdout, stderr, status = Open3.capture3(RbConfig.ruby, install_script_path)

      assert status.success?, "Expected install success but got stderr: #{stderr}"
      assert_includes stdout, "Installed command:"
      assert File.exist?(installed_executable_path), "Expected installed command at #{installed_executable_path}"

      version_stdout, version_stderr, version_status = Open3.capture3(installed_executable_path, "--version")

      assert version_status.success?, "Expected installed command success but got stderr: #{version_stderr}"
      assert_equal "#{LogFileAnalyzer::VERSION}\n", version_stdout
      refute_match(/not recognized|No such file|cannot load/i, version_stderr)
    ensure
      uninstall_local_package
    end

    private

    # Runs the local uninstall script to reset the repo-local gem directories.
    # @return [void]
    def uninstall_local_package
      system(RbConfig.ruby, uninstall_script_path)
    end

    # Resolves the install script path under the repository root.
    # @return [String]
    def install_script_path
      File.expand_path("../../bin/install", __dir__)
    end

    # Resolves the uninstall script path under the repository root.
    # @return [String]
    def uninstall_script_path
      File.expand_path("../../bin/uninstall", __dir__)
    end

    # Resolves the expected installed executable path for the current platform.
    # @return [String]
    def installed_executable_path
      executable_name = Gem.win_platform? ? "log-file-analyzer.bat" : "log-file-analyzer"
      File.expand_path("../../tmp/bin/#{executable_name}", __dir__)
    end
  end
end
