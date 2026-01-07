# frozen_string_literal: true

module ReactiveView
  module Benchmark
    # Defines and executes a single benchmark test case.
    class Scenario
      attr_reader :name, :path, :loader_path, :description

      # @param name [String] Unique identifier for this scenario
      # @param path [String] URL path to render (e.g., "/users/1")
      # @param loader_path [String, nil] Loader path (auto-derived if nil)
      # @param description [String, nil] Human-readable description
      def initialize(name:, path:, loader_path: nil, description: nil)
        @name = name
        @path = path
        @loader_path = loader_path || derive_loader_path(path)
        @description = description || "Benchmark for #{path}"
      end

      # Execute sequential benchmark
      # @param renderer [ReactiveView::Renderer] Renderer instance
      # @param rails_base_url [String] Base URL for Rails callbacks
      # @param iterations [Integer] Number of measured iterations
      # @param warmup [Integer] Number of warm-up iterations (not measured)
      # @return [Statistics] Statistical results
      def run(renderer:, rails_base_url:, iterations:, warmup:)
        errors = []

        # Warm-up phase (not measured)
        warmup.times do
          render_once(renderer, rails_base_url)
        rescue StandardError => e
          errors << e
        end

        # Measurement phase
        timings = []
        iterations.times do
          timing = measure { render_once(renderer, rails_base_url) }
          timings << timing
        rescue StandardError => e
          errors << e
        end

        if errors.any? && timings.empty?
          raise BenchmarkError, "All requests failed for #{@path}: #{errors.first.message}"
        end

        Statistics.new(timings)
      end

      # Perform a single render request
      # @param renderer [ReactiveView::Renderer] Renderer instance
      # @param rails_base_url [String] Base URL for Rails callbacks
      # @return [String] Rendered HTML
      def render_once(renderer, rails_base_url)
        renderer.render(
          path: @path,
          loader_path: @loader_path,
          rails_base_url: rails_base_url,
          cookies: nil
        )
      end

      # Measure execution time of a block
      # @yield Block to measure
      # @return [Float] Execution time in seconds
      def measure
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        yield
        Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
      end

      private

      # Derive loader path from URL path
      # Converts /users/1 -> users/[id], /users -> users/index, etc.
      def derive_loader_path(path)
        # Remove leading slash
        clean_path = path.sub(%r{^/}, '')

        # Handle root path
        return 'index' if clean_path.empty?

        segments = clean_path.split('/')

        # Check if last segment looks like a dynamic ID
        if segments.last&.match?(/^\d+$/)
          # Replace numeric ID with [id]
          segments[-1] = '[id]'
        elsif segments.length == 1
          # Single segment like /about stays as-is
          return segments.first
        end

        segments.join('/')
      end
    end
  end
end
