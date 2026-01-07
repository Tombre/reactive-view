# frozen_string_literal: true

module ReactiveView
  module Benchmark
    # Executes benchmarks with multiple concurrent threads.
    class ConcurrentRunner
      # @param concurrency [Integer] Number of concurrent threads
      def initialize(concurrency:)
        @concurrency = concurrency
      end

      # Run benchmark with concurrent requests
      # @param scenario [Scenario] The scenario to benchmark
      # @param renderer_factory [Proc] Factory to create renderer instances (one per thread)
      # @param rails_base_url [String] Base URL for Rails callbacks
      # @param total_requests [Integer] Total number of requests to make
      # @param warmup [Integer] Number of warm-up iterations (sequential)
      # @return [Hash] Results including :statistics, :total_time, :requests_per_second, :concurrency
      def run(scenario:, renderer_factory:, rails_base_url:, total_requests:, warmup:)
        # Create a renderer for warm-up
        warmup_renderer = renderer_factory.call

        # Warm-up phase (sequential, not measured)
        warmup.times do
          scenario.render_once(warmup_renderer, rails_base_url)
        rescue StandardError
          # Ignore warm-up errors
        end

        # Concurrent measurement phase
        queue = Queue.new
        total_requests.times { queue << true }

        timings = []
        errors = []
        mutex = Mutex.new

        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        threads = @concurrency.times.map do
          Thread.new do
            # Each thread gets its own renderer to avoid connection issues
            thread_renderer = renderer_factory.call

            loop do
              # Non-blocking pop, returns nil if queue is empty
              break unless queue.pop(true)

              timing = scenario.measure do
                scenario.render_once(thread_renderer, rails_base_url)
              end

              mutex.synchronize { timings << timing }
            rescue ThreadError
              # Queue is empty
              break
            rescue StandardError => e
              mutex.synchronize { errors << e }
            end
          end
        end

        threads.each(&:join)

        total_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

        raise BenchmarkError, "All concurrent requests failed: #{errors.first.message}" if errors.any? && timings.empty?

        {
          statistics: Statistics.new(timings),
          total_time: total_time,
          requests_per_second: (timings.count / total_time).round(2),
          concurrency: @concurrency,
          successful_requests: timings.count,
          failed_requests: errors.count
        }
      end
    end
  end
end
