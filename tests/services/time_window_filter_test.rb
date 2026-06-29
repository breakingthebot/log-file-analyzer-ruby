# Tests time-window filtering for parsed log entries.
# Connects to: src/services/time_window_filter.rb, src/models/log_entry.rb.
# Created: 2026-06-29

require_relative "../test_helper"
require "time"

module LogFileAnalyzer
  module Services
    class TimeWindowFilterTest < Minitest::Test
      # Verifies entries outside the requested time window are excluded.
      # @return [void]
      def test_filter_returns_entries_inside_inclusive_window
        entries = sample_entries

        filtered_entries = TimeWindowFilter.new.filter(
          entries,
          start_time: Time.iso8601("2026-06-29T10:00:01Z"),
          end_time: Time.iso8601("2026-06-29T10:00:03Z")
        )

        assert_equal 3, filtered_entries.length
        assert_equal ["/api/users", "/api/users", "/health"], filtered_entries.map(&:endpoint)
      end

      # Verifies missing bounds leave the list unchanged on that side.
      # @return [void]
      def test_filter_handles_open_ended_ranges
        entries = sample_entries

        filtered_entries = TimeWindowFilter.new.filter(
          entries,
          start_time: nil,
          end_time: Time.iso8601("2026-06-29T10:00:01Z")
        )

        assert_equal 2, filtered_entries.length
        assert_equal ["/", "/api/users"], filtered_entries.map(&:endpoint)
      end

      private

      # Builds stable timestamped entries for filtering tests.
      # @return [Array<LogEntry>]
      def sample_entries
        [
          LogEntry.new(http_method: "GET", endpoint: "/", status_code: 200, timestamp: Time.iso8601("2026-06-29T10:00:00Z")),
          LogEntry.new(http_method: "GET", endpoint: "/api/users", status_code: 200, timestamp: Time.iso8601("2026-06-29T10:00:01Z")),
          LogEntry.new(http_method: "POST", endpoint: "/api/users", status_code: 500, timestamp: Time.iso8601("2026-06-29T10:00:02Z")),
          LogEntry.new(http_method: "GET", endpoint: "/health", status_code: 404, timestamp: Time.iso8601("2026-06-29T10:00:03Z"))
        ]
      end
    end
  end
end
