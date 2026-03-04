# frozen_string_literal: true

require 'rails'
require 'active_support/all'
require 'dry-types'
require 'dry-struct'
require 'faraday'
require 'listen'

require_relative 'reactive_view/version'
require_relative 'reactive_view/configuration'

module ReactiveView
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class RenderError < Error; end
  class DaemonUnavailableError < Error; end
  class ValidationError < Error; end
  class LoaderNotFoundError < Error; end
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

    # Logger for ReactiveView operations
    def logger
      @logger ||= Rails.logger
    end

    attr_writer :logger
  end
end

# Load components after the module is defined
require_relative 'reactive_view/templates'
require_relative 'reactive_view/types'
require_relative 'reactive_view/types/dsl'
require_relative 'reactive_view/types/error_formatter'
require_relative 'reactive_view/types/validator'
require_relative 'reactive_view/types/typescript_generator'
require_relative 'reactive_view/shape'
require_relative 'reactive_view/shapes_accessor'
require_relative 'reactive_view/mutation_result'
require_relative 'reactive_view/stream_response'
require_relative 'reactive_view/stream_writer'
require_relative 'reactive_view/loader_registry'
require_relative 'reactive_view/loader'
require_relative 'reactive_view/router'
require_relative 'reactive_view/renderer'
require_relative 'reactive_view/file_sync'
require_relative 'reactive_view/daemon'
require_relative 'reactive_view/dev_proxy'
require_relative 'reactive_view/doctor'
require_relative 'reactive_view/engine'

# Benchmark module (loaded on demand via rake tasks)
require_relative 'reactive_view/benchmark/statistics'
require_relative 'reactive_view/benchmark/scenario'
require_relative 'reactive_view/benchmark/concurrent_runner'
require_relative 'reactive_view/benchmark/server_manager'
require_relative 'reactive_view/benchmark/reporter'
require_relative 'reactive_view/benchmark/runner'
