# Defines supported time-bucket series options for trend breakdowns.
# Connects to: src/main.rb, src/services/log_analyzer.rb, src/utils/config_loader.rb.
# Created: 2026-06-29

module LogFileAnalyzer
  module Config
    TIME_BUCKET_SERIES_OPTIONS = %w[none method status-family].freeze
  end
end
