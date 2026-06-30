# Evaluates summary metrics against optional CLI failure thresholds.
# Connects to: src/main.rb, src/services/log_analyzer.rb, tests/services/threshold_evaluator_test.rb.
# Created: 2026-06-30

module LogFileAnalyzer
  module Services
    # Checks whether summary metrics exceed configured automation limits.
    class ThresholdEvaluator
      THRESHOLD_EXIT_CODE = 2
      STATUS_FAMILY_5XX = "5xx"

      # Evaluates threshold settings against the generated summary.
      # @param summary [Hash] analyzer summary hash
      # @param options [Hash] parsed CLI options
      # @return [Hash]
      def evaluate(summary, options)
        breaches = []
        add_breach_if_needed(
          breaches,
          threshold_name: "--max-error-rate",
          actual_value: summary["error_rate"],
          threshold_value: options[:max_error_rate]
        )
        add_breach_if_needed(
          breaches,
          threshold_name: "--max-error-requests",
          actual_value: summary["error_requests"],
          threshold_value: options[:max_error_requests]
        )
        add_breach_if_needed(
          breaches,
          threshold_name: "--max-5xx-requests",
          actual_value: five_xx_requests(summary),
          threshold_value: options[:max_5xx_requests]
        )

        {
          exceeded: !breaches.empty?,
          exit_code: breaches.empty? ? 0 : THRESHOLD_EXIT_CODE,
          message: build_message(breaches)
        }
      end

      private

      # Adds a threshold breach when the configured limit is exceeded.
      # @param breaches [Array<String>] accumulated breach descriptions
      # @param threshold_name [String] CLI flag name
      # @param actual_value [Numeric] measured value from the summary
      # @param threshold_value [Numeric, nil] configured threshold value
      # @return [void]
      def add_breach_if_needed(breaches, threshold_name:, actual_value:, threshold_value:)
        return if threshold_value.nil?
        return unless actual_value > threshold_value

        breaches << "#{threshold_name} exceeded: actual #{actual_value}, limit #{threshold_value}"
      end

      # Extracts the total 5xx count from the summary breakdown.
      # @param summary [Hash] analyzer summary hash
      # @return [Integer]
      def five_xx_requests(summary)
        family_row = summary.fetch("status_families", []).find { |row| row["label"] == STATUS_FAMILY_5XX }
        family_row.nil? ? 0 : family_row["requests"]
      end

      # Builds a user-facing breach message.
      # @param breaches [Array<String>] threshold breach descriptions
      # @return [String, nil]
      def build_message(breaches)
        return nil if breaches.empty?

        "Threshold check failed: #{breaches.join('; ')}"
      end
    end
  end
end
