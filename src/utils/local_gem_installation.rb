# Resolves repo-local gem packaging and install paths for the Ruby CLI.
# Connects to: bin/install, bin/uninstall, tests/integration/local_install_test.rb.
# Created: 2026-06-29

require "fileutils"
require "rbconfig"

module LogFileAnalyzer
  module Utils
    # Provides stable local packaging and install locations for the CLI gem.
    module LocalGemInstallation
      module_function

      # Resolves the repository root from this file's location.
      # @return [String]
      def project_root
        File.expand_path("../..", __dir__)
      end

      # Resolves the local package output directory.
      # @return [String]
      def package_directory
        File.join(project_root, "tmp", "pkg")
      end

      # Resolves the local gem installation directory.
      # @return [String]
      def install_directory
        File.join(project_root, "tmp", "gem-home")
      end

      # Resolves the repo-local home directory used by gem commands.
      # @return [String]
      def home_directory
        File.join(project_root, "tmp", "home")
      end

      # Resolves the repo-local gem spec cache directory.
      # @return [String]
      def spec_cache_directory
        File.join(project_root, "tmp", "cache", "gem")
      end

      # Resolves the local executable install directory.
      # @return [String]
      def executable_directory
        File.join(project_root, "tmp", "bin")
      end

      # Resolves the expected built gem path for the current version.
      # @return [String]
      def package_path
        File.join(package_directory, "log-file-analyzer-#{LogFileAnalyzer::VERSION}.gem")
      end

      # Resolves the built gem filename without any directory prefix.
      # @return [String]
      def package_file_name
        File.basename(package_path)
      end

      # Resolves the installed command path for the current platform.
      # @return [String]
      def executable_path
        executable_name = Gem.win_platform? ? "log-file-analyzer.bat" : "log-file-analyzer"
        File.join(executable_directory, executable_name)
      end

      # Resolves the installed gem's executable source file.
      # @return [String]
      def installed_source_executable_path
        File.join(install_directory, "gems", "log-file-analyzer-#{LogFileAnalyzer::VERSION}", "exe", "log-file-analyzer")
      end

      # Resolves the gem command for the active Ruby installation.
      # @return [String]
      def gem_command
        executable_name = Gem.win_platform? ? "gem.cmd" : "gem"
        File.join(RbConfig::CONFIG["bindir"], executable_name)
      end

      # Resolves the Ruby executable for the active runtime.
      # @return [String]
      def ruby_command
        RbConfig.ruby
      end

      # Ensures the local package and install directories exist.
      # @return [void]
      def prepare_directories!
        FileUtils.mkdir_p([package_directory, install_directory, executable_directory, home_directory, spec_cache_directory])
      end

      # Returns the environment overrides required for repo-local gem commands.
      # @return [Hash]
      def gem_environment
        {
          "HOME" => home_directory,
          "USERPROFILE" => home_directory,
          "GEM_SPEC_CACHE" => spec_cache_directory,
          "XDG_CACHE_HOME" => File.join(project_root, "tmp", "cache")
        }
      end
    end
  end
end
