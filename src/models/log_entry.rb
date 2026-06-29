# Represents a parsed access log entry.
# Connects to: src/services/log_parser.rb, src/services/log_analyzer.rb.
# Created: 2026-06-29

module LogFileAnalyzer
  # Immutable data object for one parsed request line.
  LogEntry = Struct.new(:http_method, :endpoint, :status_code, keyword_init: true)
end
