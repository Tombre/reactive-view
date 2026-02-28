# frozen_string_literal: true

require 'benchmark'
require 'logger'
require 'rack/mock'
require 'set'
require_relative '../lib/reactive_view/configuration'
require_relative '../lib/reactive_view/dev_proxy'

ReactiveView.singleton_class.attr_accessor :configuration unless ReactiveView.respond_to?(:configuration)

unless ReactiveView.respond_to?(:logger)
  ReactiveView.define_singleton_method(:logger) { @logger ||= Logger.new($stdout) }
end

ReactiveView.configuration ||= ReactiveView::Configuration.new
ReactiveView.configuration.daemon_host = 'localhost'
ReactiveView.configuration.daemon_port = 3001

iterations = Integer(ENV.fetch('ITERATIONS', '20000'))
warmup = Integer(ENV.fetch('WARMUP', '1000'))

app = ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['fallback']] }
proxy = ReactiveView::DevProxy.new(app)
response = Struct.new(:status, :headers, :body).new(200, { 'content-type' => 'application/javascript' }, 'ok')
connection_ids = Set.new

proxy.define_singleton_method(:make_request) do |connection, *_args|
  connection_ids << connection.object_id
  response
end

env = Rack::MockRequest.env_for('/_build/@vite/client')

warmup.times { proxy.call(env) }

elapsed = Benchmark.realtime do
  iterations.times { proxy.call(env) }
end

requests_per_second = (iterations / elapsed).round(2)
ms_per_request = ((elapsed / iterations) * 1000).round(4)

puts 'ReactiveView::DevProxy benchmark (connection reuse check)'
puts "iterations=#{iterations} warmup=#{warmup}"
puts "elapsed=#{elapsed.round(4)}s req/s=#{requests_per_second} mean=#{ms_per_request}ms"
puts "unique_connection_objects=#{connection_ids.size}"
puts 'expected: unique_connection_objects=1'
