# frozen_string_literal: true

module ReactiveView
  module Benchmark
    # Generates markdown reports from benchmark results.
    class Reporter
      HISTOGRAM_WIDTH = 50

      # @param results [Hash] Benchmark results from Runner
      def initialize(results)
        @results = results
      end

      # Write report to file
      # @param path [String, Pathname] Output file path
      # @return [void]
      def write(path)
        File.write(path, generate_markdown)
      end

      # Generate the full markdown report
      # @return [String] Markdown content
      def generate_markdown
        [
          header,
          environment_section,
          configuration_section,
          summary_section,
          mode_comparison_section,
          detailed_results_section,
          concurrent_results_section,
          notes_section
        ].compact.join("\n")
      end

      private

      def header
        <<~MD
          # ReactiveView Benchmark Results

          Generated: #{@results[:environment][:timestamp]}
        MD
      end

      def environment_section
        env = @results[:environment]
        <<~MD
          ## Environment

          | Property | Value |
          |----------|-------|
          | Ruby Version | #{env[:ruby_version]} |
          | Rails Version | #{env[:rails_version]} |
          | Node Version | #{env[:node_version]} |
          | ReactiveView Version | #{env[:reactive_view_version]} |
          | Platform | #{env[:platform]} |
          | CPU | #{env[:cpu]} |
        MD
      end

      def configuration_section
        config = @results[:configuration]
        <<~MD
          ## Configuration

          | Setting | Value |
          |---------|-------|
          | Iterations | #{config[:iterations]} |
          | Warm-up | #{config[:warmup]} |
          | Concurrency Levels | #{config[:concurrency_levels].join(', ')} |
          | Daemon Port | #{config[:daemon_port]} |
          | Rails Port | #{config[:rails_port]} |
          | Modes Tested | #{config[:modes].map(&:to_s).map(&:capitalize).join(', ')} |
        MD
      end

      def summary_section
        # Use production mode if available, otherwise first available mode
        primary_mode = @results[:modes][:production] ? :production : @results[:modes].keys.first
        return '' unless primary_mode

        mode_results = @results[:modes][primary_mode]
        return '' unless mode_results[:sequential]&.any?

        rows = mode_results[:sequential].map do |_name, data|
          stats = data[:statistics]
          h = stats.to_h
          "| #{data[:scenario].description} | #{fmt(h[:mean_ms])} | #{fmt(h[:median_ms])} | #{fmt(h[:p95_ms])} | #{fmt(h[:p99_ms])} | #{fmt(h[:min_ms])} | #{fmt(h[:max_ms])} |"
        end.join("\n")

        throughput_rows = build_throughput_summary(mode_results)

        <<~MD
          ---

          ## Summary (#{primary_mode.to_s.capitalize} Mode)

          ### Sequential Requests

          | Scenario | Mean | Median | P95 | P99 | Min | Max |
          |----------|------|--------|-----|-----|-----|-----|
          #{rows}

          ### Concurrent Requests (Throughput)

          #{throughput_rows}
        MD
      end

      def build_throughput_summary(mode_results)
        return 'No concurrent benchmarks run.' unless mode_results[:concurrent]&.any?

        concurrency_levels = mode_results[:concurrent].keys.sort
        scenarios = mode_results[:sequential].keys

        # Header
        header = '| Scenario | ' + concurrency_levels.map { |c| "#{c} Thread#{c > 1 ? 's' : ''}" }.join(' | ') + ' |'
        separator = '|----------|' + concurrency_levels.map { '---------' }.join('|') + '|'

        rows = scenarios.map do |scenario_name|
          cells = concurrency_levels.map do |concurrency|
            result = mode_results[:concurrent][concurrency][scenario_name]
            result ? "#{result[:requests_per_second]} req/s" : 'N/A'
          end
          "| #{scenario_name} | #{cells.join(' | ')} |"
        end

        [header, separator, *rows].join("\n")
      end

      def mode_comparison_section
        return '' unless @results[:modes].keys.length > 1
        return '' unless @results[:modes][:development] && @results[:modes][:production]

        dev_results = @results[:modes][:development][:sequential]
        prod_results = @results[:modes][:production][:sequential]

        return '' unless dev_results&.any? && prod_results&.any?

        rows = prod_results.keys.map do |name|
          dev_data = dev_results[name]
          prod_data = prod_results[name]

          next unless dev_data && prod_data

          dev_mean = dev_data[:statistics].to_h[:mean_ms]
          prod_mean = prod_data[:statistics].to_h[:mean_ms]
          improvement = (dev_mean / prod_mean).round(1)

          "| #{prod_data[:scenario].description} | #{fmt(dev_mean)} | #{fmt(prod_mean)} | #{improvement}x faster |"
        end.compact.join("\n")

        <<~MD
          ---

          ## Mode Comparison

          ### Development vs Production (Mean Response Time)

          | Scenario | Development | Production | Improvement |
          |----------|-------------|------------|-------------|
          #{rows}
        MD
      end

      def detailed_results_section
        sections = []

        @results[:modes].each do |mode, mode_results|
          next unless mode_results[:sequential]&.any?

          mode_sections = mode_results[:sequential].map do |_name, data|
            scenario = data[:scenario]
            stats = data[:statistics]
            h = stats.to_h

            histogram = build_histogram(stats)

            <<~MD
              ### #{scenario.description} - #{mode.to_s.capitalize}

              #{scenario.description}

              ```
              Iterations: #{stats.count}
              Mean:       #{fmt(h[:mean_ms])}
              Median:     #{fmt(h[:median_ms])}
              Std Dev:    #{fmt(h[:std_dev_ms])}
              P95:        #{fmt(h[:p95_ms])}
              P99:        #{fmt(h[:p99_ms])}
              Min:        #{fmt(h[:min_ms])}
              Max:        #{fmt(h[:max_ms])}

              Response Time Distribution:
              #{histogram}
              ```
            MD
          end

          sections.concat(mode_sections)
        end

        return '' if sections.empty?

        <<~MD
          ---

          ## Detailed Results

          #{sections.join("\n")}
        MD
      end

      def concurrent_results_section
        sections = []

        @results[:modes].each do |mode, mode_results|
          next unless mode_results[:concurrent]&.any?

          mode_results[:concurrent].each do |concurrency, scenario_results|
            next if scenario_results.empty?

            rows = scenario_results.map do |name, result|
              stats = result[:statistics].to_h
              "| #{name} | #{result[:requests_per_second]} | #{fmt(stats[:mean_ms])} | #{fmt(stats[:p95_ms])} | #{fmt(stats[:p99_ms])} |"
            end.join("\n")

            sections << <<~MD
              ### #{concurrency} Concurrent Thread#{concurrency > 1 ? 's' : ''} - #{mode.to_s.capitalize}

              | Scenario | Req/s | Mean | P95 | P99 |
              |----------|-------|------|-----|-----|
              #{rows}
            MD
          end
        end

        return '' if sections.empty?

        <<~MD
          ---

          ## Concurrent Performance Details

          #{sections.join("\n")}
        MD
      end

      def notes_section
        <<~MD
          ---

          ## Notes

          - All times are in milliseconds (ms)
          - Benchmarks run on a single machine; network latency is minimal (~0.1ms)
          - Production mode uses `npx reactiveview build` + `npx reactiveview start` (optimized Vinxi bundle)
          - Development mode uses `npx reactiveview dev` (Vite dev server with HMR)
          - Database queries are included in loader scenarios
          - Results may vary based on hardware, system load, and database size
          - Warm-up iterations allow JIT compilation and cache warming before measurement
        MD
      end

      def build_histogram(stats)
        buckets = stats.distribution_buckets
        return '  No data' if buckets.values.sum.zero?

        max_count = buckets.values.max
        return '  No data' if max_count.zero?

        buckets.map do |label, count|
          percentage = (count.to_f / stats.count * 100).round
          bar_length = (count.to_f / max_count * HISTOGRAM_WIDTH).round
          bar = "\u2588" * bar_length

          format("  %8s | %-#{HISTOGRAM_WIDTH}s %d%%", label, bar, percentage)
        end.join("\n")
      end

      def fmt(value)
        return 'N/A' if value.nil?

        "#{value.round(1)}ms"
      end
    end
  end
end
