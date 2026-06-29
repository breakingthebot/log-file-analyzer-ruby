# Parses and validates CLI time-window arguments.
# Connects to: src/main.rb, src/services/time_window_filter.rb.
# Created: 2026-06-29

require "time"

module LogFileAnalyzer
  module Utils
    # Converts CLI timestamp strings into a validated time window.
    class TimeWindowParser
      # Parses optional start and end time arguments.
      # @param start_time_text [String, nil] CLI start timestamp
      # @param end_time_text [String, nil] CLI end timestamp
      # @return [Hash]
      def parse(start_time_text:, end_time_text:)
        start_time = parse_time(start_time_text, label: "start")
        end_time = parse_time(end_time_text, label: "end")

        if !start_time.nil? && !end_time.nil? && start_time > end_time
          raise ArgumentError, "Start time must be earlier than or equal to end time."
        end

        { start_time: start_time, end_time: end_time }
      end

      private

      # Parses one timestamp string into a Time object.
      # @param value [String, nil] timestamp text
      # @param label [String] argument label for error messages
      # @return [Time, nil]
      def parse_time(value, label:)
        return nil if value.nil? || value.strip.empty?

        Time.iso8601(value)
      rescue ArgumentError
        raise ArgumentError, "Invalid #{label} time. Use ISO 8601 format, for example 2026-06-29T10:00:00Z."
      end
    end
  end
end
