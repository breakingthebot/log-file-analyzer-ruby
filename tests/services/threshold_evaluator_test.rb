# Tests threshold-based exit evaluation for automation-oriented CLI runs.
# Connects to: src/services/threshold_evaluator.rb, src/services/log_analyzer.rb.
# Created: 2026-06-30

require_relative "../test_helper"

module LogFileAnalyzer
  module Services
    class ThresholdEvaluatorTest < Minitest::Test
      # Verifies the evaluator returns success when no thresholds are exceeded.
      # @return [void]
      def test_evaluate_returns_success_without_breaches
        result = ThresholdEvaluator.new.evaluate(summary, {})

        refute result[:exceeded]
        assert_equal 0, result[:exit_code]
        assert_nil result[:message]
      end

      # Verifies the evaluator returns a threshold failure when any limit is exceeded.
      # @return [void]
      def test_evaluate_returns_failure_when_thresholds_are_exceeded
        result = ThresholdEvaluator.new.evaluate(
          summary,
          {
            max_error_rate: 40.0,
            max_error_requests: 1,
            max_5xx_requests: 0
          }
        )

        assert result[:exceeded]
        assert_equal ThresholdEvaluator::THRESHOLD_EXIT_CODE, result[:exit_code]
        assert_includes result[:message], "--max-error-rate exceeded"
        assert_includes result[:message], "--max-error-requests exceeded"
        assert_includes result[:message], "--max-5xx-requests exceeded"
      end

      private

      # Builds a representative summary hash for threshold evaluation.
      # @return [Hash]
      def summary
        {
          "error_rate" => 50.0,
          "error_requests" => 2,
          "status_families" => [
            { "label" => "2xx", "requests" => 2 },
            { "label" => "4xx", "requests" => 1 },
            { "label" => "5xx", "requests" => 1 }
          ]
        }
      end
    end
  end
end
