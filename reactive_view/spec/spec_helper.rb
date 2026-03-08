# frozen_string_literal: true

require 'bundler/setup'
require 'logger'
require 'pathname'
require 'ostruct'
require 'webmock/rspec'
require 'listen'

# Load ActiveSupport for cache and other utilities
require 'active_support'
require 'active_support/all'
require 'active_support/security_utils'

# Load Action Controller Base (needed for Loader)
require 'action_controller'

# Simple Rails mock for testing without full Rails environment
module Rails
  class << self
    attr_accessor :env, :logger, :root, :cache

    def application
      @application ||= OpenStruct.new(
        secret_key_base: 'test_secret_key_base_12345678901234567890',
        routes: OpenStruct.new(draw: nil, prepend: nil)
      )
    end
  end

  class Env < String
    def development?
      self == 'development'
    end

    def test?
      self == 'test'
    end

    def production?
      self == 'production'
    end
  end
end

Rails.env = Rails::Env.new('test')
Rails.logger = Logger.new($stdout)
Rails.logger.level = Logger::WARN
Rails.root = Pathname.new(File.expand_path('../../', __dir__))
Rails.cache = ActiveSupport::Cache::MemoryStore.new

# Require only the parts we need for testing (not the full gem with Engine)
require 'reactive_view/version'
require 'reactive_view/configuration'

# Define the module first
module ReactiveView
  class Error < StandardError; end
  class RenderError < Error; end
  class DaemonUnavailableError < Error; end
  class ValidationError < Error; end
  class LoaderNotFoundError < Error; end

  class GuardRejectedError < Error
    attr_reader :redirect_path

    def initialize(message = 'Access denied', redirect_path: nil)
      @redirect_path = redirect_path
      super(message)
    end
  end

  class BenchmarkError < Error; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end

    def logger
      @logger ||= Rails.logger
    end

    attr_writer :logger
  end
end

# Load individual components
require 'reactive_view/types'
require 'reactive_view/types/dsl'
require 'reactive_view/types/validator'
require 'reactive_view/types/typescript_generator'
require 'reactive_view/templates'
require 'reactive_view/shape'
require 'reactive_view/shapes_accessor'
require 'reactive_view/mutation_result'
require 'reactive_view/stream_response'
require 'reactive_view/stream_writer'
require 'reactive_view/route_guard'
require 'reactive_view/guard_registry'
require 'reactive_view/guard_runner'
require 'reactive_view/dev_proxy'
require 'reactive_view/dev_orchestrator'
require 'reactive_view/autoload_ignorer'
require 'reactive_view/renderer'
require 'reactive_view/loader_registry'
require 'reactive_view/router'
require 'reactive_view/loader'
require 'reactive_view/file_sync'
require 'reactive_view/file_sync/atomic_writer'
require 'reactive_view/file_sync/wrapper_generator'
require 'reactive_view/file_sync/vite_notifier'
require 'reactive_view/file_sync/file_watcher'

# Load benchmark components
require 'reactive_view/benchmark/statistics'
require 'reactive_view/benchmark/scenario'
require 'reactive_view/benchmark/concurrent_runner'
require 'reactive_view/benchmark/server_manager'
require 'reactive_view/benchmark/reporter'
require 'reactive_view/benchmark/runner'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = false # Disable warnings for cleaner test output
  config.order = :random

  Kernel.srand config.seed

  config.before(:each) do
    ReactiveView.reset_configuration!
  end

  config.after(:suite) do
    ReactiveView::FileSync::FileWatcher.stop
  end
end
