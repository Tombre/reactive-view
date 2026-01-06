# frozen_string_literal: true

namespace :reactive_view do
  desc 'Setup ReactiveView (creates working directory and installs dependencies)'
  task setup: :environment do
    puts 'Setting up ReactiveView...'

    ReactiveView::FileSync.sync_all

    puts 'Setup complete!'
  end

  desc 'Sync TSX files from app/pages to the SolidStart directory'
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
      ReactiveView::Types::TypescriptGenerator.generate

      puts 'Types generated at:'
      puts "  #{ReactiveView.configuration.working_directory}/" \
           'src/lib/reactive-view/types/generated.d.ts'
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

  desc 'Build for production'
  task build: :environment do
    puts 'Building for production...'

    working_dir = ReactiveView.configuration.working_directory_absolute_path

    # Ensure files are synced
    ReactiveView::FileSync.sync_all

    # Run the build
    Dir.chdir(working_dir) do
      unless system('npm run build')
        puts 'Build failed!'
        exit 1
      end
    end

    puts 'Build complete!'
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
end
