# frozen_string_literal: true

namespace :reactive_view do
  desc 'Setup ReactiveView (creates working directory and installs dependencies)'
  task setup: :environment do
    puts 'Setting up ReactiveView...'

    ReactiveView::FileSync.sync_all

    puts 'Setup complete!'
  end

  desc 'Regenerate route wrappers and TypeScript types'
  task sync: :environment do
    puts 'Syncing files...'

    ReactiveView::FileSync.sync_all

    puts 'Sync complete!'
  end

  namespace :types do
    desc 'Generate TypeScript types from loader signatures'
    task generate: :environment do
      puts 'Generating TypeScript types...'

      # Ensure loaders are loaded
      ReactiveView::LoaderRegistry.load_all

      # Generate types
      result = ReactiveView::Types::TypescriptGenerator.generate

      puts 'Types generated:'
      puts "  Per-route loaders: #{ReactiveView.configuration.working_directory}/types/loaders/"
      puts "  Route map: #{ReactiveView.configuration.working_directory}/types/loader-data.d.ts"
      puts "  Files created: #{result[:loader_files].count}"
    end
  end

  namespace :daemon do
    desc 'Start the SolidStart daemon'
    task start: :environment do
      puts 'Starting SolidStart daemon...'

      if ReactiveView::Daemon.instance.start
        puts 'Daemon started successfully!'
        puts "Running at: #{ReactiveView.configuration.daemon_url}"
      else
        puts 'Failed to start daemon. Check .reactive_view/daemon.log for details.'
        exit 1
      end
    end

    desc 'Stop the SolidStart daemon'
    task stop: :environment do
      puts 'Stopping SolidStart daemon...'
      ReactiveView::Daemon.instance.stop
      puts 'Daemon stopped.'
    end

    desc 'Restart the SolidStart daemon'
    task restart: :environment do
      puts 'Restarting SolidStart daemon...'
      ReactiveView::Daemon.instance.restart
      puts 'Daemon restarted.'
    end

    desc 'Check daemon status'
    task status: :environment do
      if ReactiveView::Daemon.instance.running?
        puts "Daemon is running (PID: #{ReactiveView::Daemon.instance.pid})"
        puts "URL: #{ReactiveView.configuration.daemon_url}"
      else
        puts 'Daemon is not running'
      end
    end
  end

  desc 'Run environment diagnostics for ReactiveView'
  task doctor: :environment do
    result = ReactiveView::Doctor.new.report
    exit 1 unless result[:ok]
  end

  desc 'Build for production'
  task build: :environment do
    puts 'Building for production...'

    # Ensure files are synced
    ReactiveView::FileSync.sync_all

    # Run the build from Rails root
    Dir.chdir(Rails.root.to_s) do
      unless system('npx reactiveview build')
        puts 'Build failed!'
        exit 1
      end
    end

    puts 'Build complete!'
    working_dir = ReactiveView.configuration.working_directory_absolute_path
    puts "Output at: #{working_dir}/.output"
  end

  desc 'Show routes'
  task routes: :environment do
    puts 'ReactiveView Routes:'
    puts '=' * 60

    pages_path = ReactiveView.configuration.pages_absolute_path

    unless pages_path.exist?
      puts "No pages directory found at #{pages_path}"
      exit 0
    end

    Dir.glob(pages_path.join('**', '*.tsx')).sort.each do |file|
      relative = Pathname.new(file).relative_path_from(pages_path)
      path = relative.to_s.sub(/\.tsx$/, '')

      # Convert to route
      route = '/' + path.split('/').map do |segment|
        case segment
        when /^\[\.\.\.(.*?)\]$/
          "*#{::Regexp.last_match(1)}"
        when /^\[\[(.*?)\]\]$/
          "(/:#{::Regexp.last_match(1)})"
        when /^\[(.*?)\]$/
          ":#{::Regexp.last_match(1)}"
        when 'index'
          ''
        else
          segment
        end
      end.join('/').gsub(%r{//+}, '/').sub(%r{/$}, '')

      route = '/' if route.empty?

      loader_file = file.sub(/\.tsx$/, '.loader.rb')
      has_loader = File.exist?(loader_file)

      loader_indicator = has_loader ? ' [loader]' : ''

      puts "  #{route.ljust(30)} -> #{relative}#{loader_indicator}"
    end
  end

  namespace :benchmark do
    desc 'Run full benchmark suite (development and production modes)'
    task run: :environment do
      ReactiveView::Benchmark::Runner.new.run
    end

    desc 'Quick benchmark (fewer iterations, production only)'
    task quick: :environment do
      ReactiveView::Benchmark::Runner.new(
        iterations: 20,
        warmup: 5,
        concurrency: [1, 5],
        modes: [:production]
      ).run
    end

    desc 'Benchmark production mode only'
    task production: :environment do
      ReactiveView::Benchmark::Runner.new(
        iterations: 100,
        warmup: 10,
        concurrency: [1, 5, 10],
        modes: [:production]
      ).run
    end

    desc 'Benchmark development mode only'
    task development: :environment do
      ReactiveView::Benchmark::Runner.new(
        iterations: 100,
        warmup: 10,
        concurrency: [1, 5, 10],
        modes: [:development]
      ).run
    end

    desc 'Benchmark a specific route (usage: rake reactive_view:benchmark:route[/users,50])'
    task :route, %i[path iterations] => :environment do |_t, args|
      path = args[:path] || '/about'
      iterations = (args[:iterations] || 50).to_i

      ReactiveView::Benchmark::Runner.new(
        iterations: iterations,
        warmup: 5,
        concurrency: [1, 5],
        scenarios: [{ name: 'custom', path: path, description: "Custom route: #{path}" }],
        modes: [:production]
      ).run
    end
  end
end
