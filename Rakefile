# frozen_string_literal: true

# Root Rakefile for ReactiveView project
# Provides convenient access to benchmark tasks from project root

EXAMPLE_APP_PATH = File.expand_path("examples/reactive_view_example", __dir__)

namespace :benchmark do
  desc "Run full benchmark suite (development and production modes)"
  task :run do
    run_benchmark_task("reactive_view:benchmark:run")
  end

  desc "Quick benchmark (fewer iterations, production only)"
  task :quick do
    run_benchmark_task("reactive_view:benchmark:quick")
  end

  desc "Benchmark production mode only"
  task :production do
    run_benchmark_task("reactive_view:benchmark:production")
  end

  desc "Benchmark development mode only"
  task :development do
    run_benchmark_task("reactive_view:benchmark:development")
  end

  desc "Benchmark a specific route (usage: rake benchmark:route[/users,50])"
  task :route, [:path, :iterations] do |_t, args|
    path = args[:path] || "/about"
    iterations = args[:iterations] || "50"
    run_benchmark_task("reactive_view:benchmark:route[#{path},#{iterations}]")
  end
end

# Default task
desc "Run the full benchmark suite"
task benchmark: "benchmark:run"

# Helper to run tasks in the example app context
def run_benchmark_task(task_name)
  unless File.directory?(EXAMPLE_APP_PATH)
    abort "Error: Example app not found at #{EXAMPLE_APP_PATH}"
  end

  puts "Running benchmark from: #{EXAMPLE_APP_PATH}"
  puts ""

  Dir.chdir(EXAMPLE_APP_PATH) do
    system("bin/rails #{task_name}") || exit(1)
  end
end
