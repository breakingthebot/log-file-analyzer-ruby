# Filters parsed log entries to a requested time window.
# Connects to: src/models/log_entry.rb, src/main.rb.
# Created: 2026-06-29

module LogFileAnalyzer
  module Services
    # Applies inclusive start and end timestamp filtering.
    class TimeWindowFilter
      # Filters entries to the requested time window.
      # @param entries [Array<LogEntry>] parsed log entries
      # @param start_time [Time, nil] inclusive lower bound
      # @param end_time [Time, nil] inclusive upper bound
      # @return [Array<LogEntry>]
      def filter(entries, start_time:, end_time:)
        entries.select do |entry|
          within_start?(entry.timestamp, start_time) && within_end?(entry.timestamp, end_time)
        end
      end

      private

      # Checks whether a timestamp is on or after the requested start time.
      # @param timestamp [Time, nil] entry timestamp
      # @param start_time [Time, nil] lower bound
      # @return [Boolean]
      def within_start?(timestamp, start_time)
        return true if start_time.nil?
        return false if timestamp.nil?

        timestamp >= start_time
      end

      # Checks whether a timestamp is on or before the requested end time.
      # @param timestamp [Time, nil] entry timestamp
      # @param end_time [Time, nil] upper bound
      # @return [Boolean]
      def within_end?(timestamp, end_time)
        return true if end_time.nil?
        return false if timestamp.nil?

        timestamp <= end_time
      end
    end
  end
end
