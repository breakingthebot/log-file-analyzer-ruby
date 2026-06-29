# Defines supported time-bucket options for trend summaries.
# Connects to: src/main.rb, src/services/log_analyzer.rb, src/utils/config_loader.rb.
# Created: 2026-06-29

module LogFileAnalyzer
  module Config
    TIME_BUCKET_OPTIONS = %w[none minute hour].freeze
  end
end
