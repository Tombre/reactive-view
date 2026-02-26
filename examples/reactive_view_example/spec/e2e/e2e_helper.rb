require 'pathname'
require_relative '../spec_helper'
require_relative 'support/app_runner'
require_relative 'support/playwright_helpers'

APP_ROOT = Pathname.new(File.expand_path('../..', __dir__))

RSpec.configure do |config|
  config.include E2E::PlaywrightHelpers

  config.before(:suite) do
    @runner = E2E::AppRunner.new(root: APP_ROOT)
    @runner.start
    ENV['E2E_BASE_URL'] = "http://127.0.0.1:#{@runner.app_port}"
  end

  config.after(:suite) do
    @runner&.stop
  end
end
