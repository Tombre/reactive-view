# frozen_string_literal: true

module ReactiveView
  module Benchmark
    # Main orchestrator for running benchmarks.
    class Runner
      DEFAULT_SCENARIOS = [
        { name: 'static', path: '/about', description: 'Static page (no loader)' },
        { name: 'interactive', path: '/counter', description: 'Interactive page with signals' },
        { name: 'list', path: '/users', loader_path: 'users/index', description: 'List with loader + DB query' },
        { name: 'dynamic', path: '/users/1', loader_path: 'users/[id]', description: 'Dynamic route with loader' }
      ].freeze

      # @param iterations [Integer] Number of measured iterations per scenario
      # @param warmup [Integer] Number of warm-up iterations
      # @param concurrency [Array<Integer>] Concurrency levels to test
      # @param scenarios [Array<Hash>] Scenario configurations
      # @param modes [Array<Symbol>] Modes to test (:development, :production)
      # @param output_path [String, Pathname, nil] Output file path (defaults to Rails.root/BENCHMARKS.md)
      # @param rails_port [Integer] Port for Rails server
      # @param daemon_port [Integer] Port for SolidStart daemon
      def initialize(
        iterations: 100,
        warmup: 10,
        concurrency: [1, 5, 10],
        scenarios: DEFAULT_SCENARIOS,
        modes: %i[development production],
        output_path: nil,
        rails_port: 3000,
        daemon_port: 3001
      )
        @iterations = iterations
        @warmup = warmup
        @concurrency_levels = Array(concurrency)
        @scenario_configs = scenarios
        @modes = Array(modes)
        @output_path = output_path || default_output_path
        @rails_port = rails_port
        @daemon_port = daemon_port
      end

      # Default output path - project root if we can find it, otherwise Rails.root
      def default_output_path
        # Try to find project root by looking for reactive_view gem directory
        current = Rails.root
        while current.to_s != '/'
          return current.join('BENCHMARKS.md') if File.exist?(current.join('reactive_view', 'reactive_view.gemspec'))

          current = current.parent
        end
        # Fall back to Rails.root if not in the mono-repo structure
        Rails.root.join('BENCHMARKS.md')
      end

      # Run the full benchmark suite
      # @return [Hash] Complete results
      def run
        validate_setup!

        puts banner
        puts ''

        results = {
          environment: collect_environment_info,
          configuration: collect_configuration,
          modes: {}
        }

        @modes.each do |mode|
          puts '=' * 60
          puts "#{mode.to_s.capitalize} Mode"
          puts '=' * 60

          begin
            results[:modes][mode] = run_mode(mode)
          rescue StandardError => e
            puts "ERROR: #{e.message}"
            results[:modes][mode] = { error: e.message }
          end

          puts ''
        end

        # Generate report
        puts 'Generating report...'
        Reporter.new(results).write(@output_path)

        puts ''
        puts '=' * 60
        puts 'Benchmark complete!'
        puts "Results written to: #{@output_path}"
        puts '=' * 60

        results
      end

      private

      def banner
        <<~BANNER
          ╔══════════════════════════════════════════════════════════╗
          ║           ReactiveView Benchmark Suite                   ║
          ╠══════════════════════════════════════════════════════════╣
          ║  Iterations: #{@iterations.to_s.ljust(10)} Warm-up: #{@warmup.to_s.ljust(15)} ║
          ║  Scenarios:  #{@scenario_configs.length.to_s.ljust(10)} Concurrency: #{@concurrency_levels.join(', ').ljust(12)} ║
          ║  Modes:      #{@modes.map(&:to_s).join(', ').ljust(43)} ║
          ╚══════════════════════════════════════════════════════════╝
        BANNER
      end

      def validate_setup!
        working_dir = ReactiveView.configuration.working_directory_absolute_path

        unless File.directory?(working_dir)
          raise BenchmarkError,
                "Working directory not found: #{working_dir}. Run 'bin/rails reactive_view:setup' first."
        end

        package_json = File.join(working_dir, 'package.json')
        return if File.exist?(package_json)

        raise BenchmarkError, "package.json not found in #{working_dir}. Run 'bin/rails reactive_view:setup' first."
      end

      def run_mode(mode)
        server_manager = ServerManager.new(
          rails_port: @rails_port,
          daemon_port: @daemon_port,
          mode: mode
        )

        mode_results = { sequential: {}, concurrent: {} }

        begin
          server_manager.start_all

          rails_base_url = server_manager.rails_url

          # Factory for creating renderer instances
          renderer_factory = lambda {
            ReactiveView::Renderer.new(
              host: 'localhost',
              port: @daemon_port,
              timeout: 30
            )
          }

          # Sequential benchmarks
          puts ''
          puts 'Sequential benchmarks:'
          puts '-' * 40

          @scenario_configs.each do |config|
            scenario = Scenario.new(**config.slice(:name, :path, :loader_path, :description))

            print "  #{scenario.name.ljust(15)}... "

            begin
              renderer = renderer_factory.call
              stats = scenario.run(
                renderer: renderer,
                rails_base_url: rails_base_url,
                iterations: @iterations,
                warmup: @warmup
              )

              mode_results[:sequential][scenario.name] = {
                scenario: scenario,
                statistics: stats
              }

              puts "done (mean: #{stats.to_h[:mean_ms].round(1)}ms, p99: #{stats.to_h[:p99_ms].round(1)}ms)"
            rescue StandardError => e
              puts "FAILED: #{e.message}"
              mode_results[:sequential][scenario.name] = { error: e.message }
            end
          end

          # Concurrent benchmarks
          puts ''
          puts 'Concurrent benchmarks:'
          puts '-' * 40

          @concurrency_levels.each do |concurrency|
            puts "  #{concurrency} thread#{concurrency > 1 ? 's' : ''}:"
            mode_results[:concurrent][concurrency] = {}

            @scenario_configs.each do |config|
              scenario = Scenario.new(**config.slice(:name, :path, :loader_path, :description))

              print "    #{scenario.name.ljust(13)}... "

              begin
                concurrent_runner = ConcurrentRunner.new(concurrency: concurrency)
                result = concurrent_runner.run(
                  scenario: scenario,
                  renderer_factory: renderer_factory,
                  rails_base_url: rails_base_url,
                  total_requests: @iterations,
                  warmup: @warmup
                )

                mode_results[:concurrent][concurrency][scenario.name] = result

                puts "done (#{result[:requests_per_second]} req/s, mean: #{result[:statistics].to_h[:mean_ms].round(1)}ms)"
              rescue StandardError => e
                puts "FAILED: #{e.message}"
                mode_results[:concurrent][concurrency][scenario.name] = { error: e.message }
              end
            end
          end

          mode_results
        ensure
          server_manager.stop_all
        end
      end

      def collect_environment_info
        {
          ruby_version: RUBY_VERSION,
          rails_version: Rails.version,
          node_version: detect_node_version,
          reactive_view_version: ReactiveView::VERSION,
          platform: RUBY_PLATFORM,
          cpu: detect_cpu,
          timestamp: Time.now.utc.iso8601
        }
      end

      def collect_configuration
        {
          iterations: @iterations,
          warmup: @warmup,
          concurrency_levels: @concurrency_levels,
          daemon_port: @daemon_port,
          rails_port: @rails_port,
          modes: @modes
        }
      end

      def detect_node_version
        `node --version`.strip
      rescue StandardError
        'unknown'
      end

      def detect_cpu
        case RUBY_PLATFORM
        when /darwin/
          `sysctl -n machdep.cpu.brand_string`.strip
        when /linux/
          File.read('/proc/cpuinfo').match(/model name\s*:\s*(.+)/)&.[](1)&.strip || 'unknown'
        else
          'unknown'
        end
      rescue StandardError
        'unknown'
      end
    end
  end
end
