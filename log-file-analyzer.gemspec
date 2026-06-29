# Gem specification for packaging the Ruby log file analyzer CLI.
# Connects to: Gemfile, exe/log-file-analyzer, src/config/version.rb.
# Created: 2026-06-29

require_relative "src/config/version"

Gem::Specification.new do |spec|
  spec.name = "log-file-analyzer"
  spec.version = LogFileAnalyzer::VERSION
  spec.authors = ["OpenAI Codex"]
  spec.email = ["noreply@example.com"]
  spec.summary = "CLI for analyzing server access logs."
  spec.description = "Reads common access logs and reports request counts, error rates, and top endpoints."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4.0"
  spec.homepage = "https://github.com/breakingthebot/log-file-analyzer-ruby"

  spec.files = Dir[
    "src/**/*.rb",
    "exe/*",
    "README.md",
    "CHANGELOG.md",
    "LICENSE",
    ".env.example"
  ]
  spec.bindir = "exe"
  spec.executables = ["log-file-analyzer"]
  spec.require_paths = ["src"]
end
