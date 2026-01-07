# frozen_string_literal: true

module ReactiveView
  module Benchmark
    # Calculates statistical measures from timing arrays.
    # All timings are stored in seconds internally.
    class Statistics
      attr_reader :timings

      # @param timings [Array<Float>] Array of timing measurements in seconds
      def initialize(timings)
        @timings = timings.sort
        @count = @timings.length
      end

      # @return [Integer] Number of samples
      attr_reader :count

      # @return [Float] Total time in seconds
      def sum
        @sum ||= @timings.sum
      end

      # @return [Float] Average time in seconds
      def mean
        return 0.0 if @count.zero?

        @mean ||= sum / @count.to_f
      end

      # @return [Float] Median (50th percentile) in seconds
      def median
        percentile(50)
      end

      # @return [Float] Minimum time in seconds
      def min
        @timings.first || 0.0
      end

      # @return [Float] Maximum time in seconds
      def max
        @timings.last || 0.0
      end

      # @return [Float] Standard deviation in seconds
      def std_dev
        return 0.0 if @count < 2

        @std_dev ||= begin
          variance = @timings.sum { |t| (t - mean)**2 } / (@count - 1).to_f
          Math.sqrt(variance)
        end
      end

      # Calculate a specific percentile
      # @param p [Numeric] Percentile to calculate (0-100)
      # @return [Float] Value at the given percentile in seconds
      def percentile(p)
        return 0.0 if @count.zero?
        return @timings.first if @count == 1

        rank = (p / 100.0) * (@count - 1)
        lower = @timings[rank.floor]
        upper = @timings[rank.ceil]
        lower + (upper - lower) * (rank - rank.floor)
      end

      # @return [Float] 95th percentile in seconds
      def p95
        percentile(95)
      end

      # @return [Float] 99th percentile in seconds
      def p99
        percentile(99)
      end

      # Calculate distribution buckets for histogram display
      # @param bucket_ranges [Array<Numeric>] Upper bounds for buckets in milliseconds
      # @return [Hash<String, Integer>] Bucket labels mapped to counts
      def distribution_buckets(bucket_ranges = nil)
        bucket_ranges ||= [5, 10, 15, 20, 25, 50, 100]

        buckets = {}
        prev_bound = 0

        bucket_ranges.each do |upper_ms|
          label = format_bucket_label(prev_bound, upper_ms)
          upper_sec = upper_ms / 1000.0
          prev_sec = prev_bound / 1000.0

          count = @timings.count { |t| t >= prev_sec && t < upper_sec }
          buckets[label] = count
          prev_bound = upper_ms
        end

        # Final bucket for anything above the last range
        label = ">#{bucket_ranges.last}ms"
        upper_sec = bucket_ranges.last / 1000.0
        buckets[label] = @timings.count { |t| t >= upper_sec }

        buckets
      end

      # Export all statistics as a hash
      # @return [Hash] All statistics with times in milliseconds
      def to_h
        {
          count: count,
          sum_ms: to_ms(sum),
          mean_ms: to_ms(mean),
          median_ms: to_ms(median),
          min_ms: to_ms(min),
          max_ms: to_ms(max),
          std_dev_ms: to_ms(std_dev),
          p95_ms: to_ms(p95),
          p99_ms: to_ms(p99)
        }
      end

      # Convert seconds to milliseconds
      # @param seconds [Float] Time in seconds
      # @return [Float] Time in milliseconds
      def to_ms(seconds)
        (seconds * 1000).round(2)
      end

      private

      def format_bucket_label(lower, upper)
        if lower.zero?
          "<#{upper}ms"
        else
          "#{lower}-#{upper}ms"
        end
      end
    end
  end
end
