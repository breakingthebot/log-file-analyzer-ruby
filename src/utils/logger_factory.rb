# Builds application loggers with consistent formatting.
# Connects to: src/services/log_parser.rb, src/utils/path_validator.rb, src/main.rb.
# Created: 2026-06-29

require "logger"
require "time"

module LogFileAnalyzer
  module Utils
    # Creates a logger for application diagnostics.
    # @param stream [IO] output stream for logs
    # @return [Logger]
    def self.build_logger(stream: $stderr)
      logger = Logger.new(stream)
      logger.level = Logger::INFO
      logger.progname = "log-file-analyzer"
      logger.formatter = proc do |severity, datetime, progname, message|
        "#{datetime.utc.iso8601} #{severity} #{progname}: #{message}\n"
      end
      logger
    end
  end
end
