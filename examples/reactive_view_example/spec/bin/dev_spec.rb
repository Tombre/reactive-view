# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'tmpdir'

require_relative '../spec_helper'

RSpec.describe 'bin/dev startup flow' do
  let(:source_script_path) { File.expand_path('../../bin/dev', __dir__) }

  def with_fake_app
    Dir.mktmpdir('reactive-view-bin-dev-spec') do |dir|
      FileUtils.mkdir_p(File.join(dir, 'bin'))
      FileUtils.mkdir_p(File.join(dir, 'db'))
      FileUtils.mkdir_p(File.join(dir, 'tmp'))

      FileUtils.cp(source_script_path, File.join(dir, 'bin/dev'))
      FileUtils.chmod(0o755, File.join(dir, 'bin/dev'))

      File.write(
        File.join(dir, 'bin/rails'),
        <<~BASH
          #!/usr/bin/env bash
          set -e

          mkdir -p tmp
          printf "%s\n" "$*" >> tmp/rails-invocations.log

          case "$1" in
            reactive_view:setup)
              mkdir -p .reactive_view
              ;;
            reactive_view:sync)
              ;;
            server)
              printf "%s\n" "$*" > tmp/server-command.log
              ;;
          esac
        BASH
      )
      FileUtils.chmod(0o755, File.join(dir, 'bin/rails'))

      yield dir
    end
  end

  def run_dev_script(app_dir:)
    env = {
      'PORT' => '3131'
    }

    Open3.capture3(env, File.join(app_dir, 'bin/dev'), chdir: app_dir)
  end

  it 'runs setup, sync, and starts rails server when working directory is missing' do
    with_fake_app do |app_dir|
      stdout, stderr, status = run_dev_script(app_dir: app_dir)
      expect(status.success?).to be(true), stderr

      invocations = File.read(File.join(app_dir, 'tmp/rails-invocations.log'))
      expect(invocations).to include('reactive_view:setup')
      expect(invocations).to include('reactive_view:sync')

      server_command = File.read(File.join(app_dir, 'tmp/server-command.log'))
      expect(server_command).to include('server -b 0.0.0.0 -p 3131')
      expect(stdout).to include('auto-starts in development')
    end
  end

  it 'skips setup when working directory already exists' do
    with_fake_app do |app_dir|
      FileUtils.mkdir_p(File.join(app_dir, '.reactive_view'))

      _stdout, stderr, status = run_dev_script(app_dir: app_dir)
      expect(status.success?).to be(true), stderr

      invocations = File.read(File.join(app_dir, 'tmp/rails-invocations.log'))
      expect(invocations).not_to include('reactive_view:setup')
      expect(invocations).to include('reactive_view:sync')
    end
  end
end
