# Tests CLI time-window parsing and validation.
# Connects to: src/utils/time_window_parser.rb, src/main.rb.
# Created: 2026-06-29

require_relative "../test_helper"

module LogFileAnalyzer
  module Utils
    class TimeWindowParserTest < Minitest::Test
      # Verifies ISO 8601 CLI strings convert into Time objects.
      # @return [void]
      def test_parse_returns_start_and_end_times
        time_window = TimeWindowParser.new.parse(
          start_time_text: "2026-06-29T10:00:00Z",
          end_time_text: "2026-06-29T10:05:00Z"
        )

        assert_equal Time.iso8601("2026-06-29T10:00:00Z"), time_window[:start_time]
        assert_equal Time.iso8601("2026-06-29T10:05:00Z"), time_window[:end_time]
      end

      # Verifies invalid time ordering raises a clear error.
      # @return [void]
      def test_parse_rejects_reversed_ranges
        error = assert_raises(ArgumentError) do
          TimeWindowParser.new.parse(
            start_time_text: "2026-06-29T10:05:00Z",
            end_time_text: "2026-06-29T10:00:00Z"
          )
        end

        assert_equal "Start time must be earlier than or equal to end time.", error.message
      end
    end
  end
end
