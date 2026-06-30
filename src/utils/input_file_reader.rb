# Reads plain-text and gzip-compressed log files line by line.
# Connects to: src/services/log_parser.rb, src/services/file_format_detector.rb.
# Created: 2026-06-30

require "zlib"

module LogFileAnalyzer
  module Utils
    # Streams supported input files without forcing callers to care about compression.
    module InputFileReader
      GZIP_EXTENSION = ".gz"

      module_function

      # Iterates over each line in a plain-text or gzip-compressed file.
      # @param file_path [String] absolute path to the input file
      # @yieldparam line [String] one raw line from the file
      # @return [void]
      def each_line(file_path, &block)
        return enum_for(__method__, file_path) unless block_given?

        compressed_file?(file_path) ? each_gzip_line(file_path, &block) : File.foreach(file_path, &block)
      end

      # Checks whether the current file path is gzip-compressed.
      # @param file_path [String] absolute path to the input file
      # @return [Boolean]
      def compressed_file?(file_path)
        file_path.downcase.end_with?(GZIP_EXTENSION)
      end

      # Iterates over each line in a gzip-compressed file.
      # @param file_path [String] absolute path to the gzip file
      # @yieldparam line [String] one raw line from the file
      # @return [void]
      def each_gzip_line(file_path)
        return enum_for(__method__, file_path) unless block_given?

        Zlib::GzipReader.open(file_path) do |gzip_reader|
          gzip_reader.each_line do |line|
            yield line
          end
        end
      end
    end
  end
end
