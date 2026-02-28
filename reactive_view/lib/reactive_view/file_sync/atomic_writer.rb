# frozen_string_literal: true

require 'tempfile'
require 'fileutils'

module ReactiveView
  class FileSync
    # Provides atomic file write operations to prevent corruption from partial
    # writes during crashes or interrupts.
    #
    # The pattern used is:
    # 1. Write content to a temporary file in the same directory as the target
    # 2. Rename the temporary file to the target path (atomic on POSIX systems)
    #
    # This ensures that the target file is either the old content or the new
    # content, never a partial write.
    #
    # @example
    #   AtomicWriter.write('/path/to/file.ts', 'content')
    #
    module AtomicWriter
      module_function

      # Write content to a file atomically.
      #
      # Uses a temp file + rename pattern to ensure atomicity. The temp file
      # is created in the same directory as the target to ensure the rename
      # operation is atomic (same filesystem).
      #
      # @param path [Pathname, String] Destination file path
      # @param content [String] Content to write
      # @return [Boolean] true if write succeeded
      # @raise [SystemCallError] if write fails and error handling is not silent
      def write(path, content)
        path = Pathname.new(path) unless path.is_a?(Pathname)
        FileUtils.mkdir_p(path.dirname)

        # Create temp file in the same directory as target for atomic rename
        # The temp file name includes process ID and a unique identifier
        temp_path = path.dirname.join(".#{path.basename}.#{Process.pid}.tmp")

        begin
          # Write to temp file
          File.open(temp_path, 'wb') do |f|
            f.write(content)
            f.fsync # Ensure content is flushed to disk
          end

          # Atomic rename
          FileUtils.mv(temp_path, path)
          true
        rescue StandardError => e
          # Clean up temp file if it exists
          temp_path.delete if temp_path.exist?
          raise e
        end
      end
    end
  end
end
