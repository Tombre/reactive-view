# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'tmpdir'

require_relative '../spec_helper'

RSpec.describe 'ReactiveView example bin scripts' do
  let(:source_reactive_view_script_path) { File.expand_path('../../bin/reactive-view-dev', __dir__) }
  let(:source_dev_wrapper_script_path) { File.expand_path('../../bin/dev', __dir__) }
  let(:source_web_script_path) { File.expand_path('../../bin/web', __dir__) }

  def with_fake_app
    Dir.mktmpdir('reactive-view-bin-spec') do |dir|
      FileUtils.mkdir_p(File.join(dir, 'bin'))
      FileUtils.mkdir_p(File.join(dir, 'tmp'))

      FileUtils.cp(source_reactive_view_script_path, File.join(dir, 'bin/reactive-view-dev'))
      FileUtils.cp(source_dev_wrapper_script_path, File.join(dir, 'bin/dev'))
      FileUtils.cp(source_web_script_path, File.join(dir, 'bin/web'))
      FileUtils.chmod(0o755, File.join(dir, 'bin/reactive-view-dev'))
      FileUtils.chmod(0o755, File.join(dir, 'bin/dev'))
      FileUtils.chmod(0o755, File.join(dir, 'bin/web'))

      File.write(
        File.join(dir, 'Procfile.dev'),
        <<~TEXT
          web: PORT=3000 bin/web
          reactive_view: REACTIVE_VIEW_DAEMON_PORT=3001 bin/reactive-view-dev
        TEXT
      )

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
            server)
              printf "%s\n" "$*" > tmp/server-command.log
              ;;
          esac
        BASH
      )
      FileUtils.chmod(0o755, File.join(dir, 'bin/rails'))

      File.write(
        File.join(dir, 'bin/bundle'),
        <<~BASH
          #!/usr/bin/env bash
          set -e

          mkdir -p tmp
          printf "%s\n" "$*" >> tmp/bundle-invocations.log
        BASH
      )
      FileUtils.chmod(0o755, File.join(dir, 'bin/bundle'))

      yield dir
    end
  end

  def run_script(path:, app_dir:, env_overrides: {})
    env = {
      'PATH' => "#{File.join(app_dir, 'bin')}:#{ENV.fetch('PATH', '')}",
      'PORT' => '3131'
    }.merge(env_overrides)

    Open3.capture3(env, path, chdir: app_dir)
  end

  it 'runs setup before starting orchestrator when working directory is missing' do
    with_fake_app do |app_dir|
      _stdout, stderr, status = run_script(path: File.join(app_dir, 'bin/reactive-view-dev'), app_dir: app_dir)
      expect(status.success?).to be(true), stderr

      rails_log = File.join(app_dir, 'tmp/rails-invocations.log')
      rails_invocations = File.exist?(rails_log) ? File.read(rails_log) : ''
      bundle_invocations = File.read(File.join(app_dir, 'tmp/bundle-invocations.log'))

      expect(rails_invocations).to include('reactive_view:setup')
      expect(bundle_invocations).to include('exec reactiveview doctor --fix')
      expect(bundle_invocations).to include('exec reactiveview dev')
    end
  end

  it 'skips setup when working directory already exists' do
    with_fake_app do |app_dir|
      FileUtils.mkdir_p(File.join(app_dir, '.reactive_view'))

      _stdout, stderr, status = run_script(path: File.join(app_dir, 'bin/reactive-view-dev'), app_dir: app_dir)
      expect(status.success?).to be(true), stderr

      rails_log = File.join(app_dir, 'tmp/rails-invocations.log')
      rails_invocations = File.exist?(rails_log) ? File.read(rails_log) : ''
      bundle_invocations = File.read(File.join(app_dir, 'tmp/bundle-invocations.log'))

      expect(rails_invocations).not_to include('reactive_view:setup')
      expect(bundle_invocations).to include('exec reactiveview doctor --fix')
      expect(bundle_invocations).to include('exec reactiveview dev')
    end
  end

  it 'continues to start dev when doctor --fix exits non-zero' do
    with_fake_app do |app_dir|
      File.write(
        File.join(app_dir, 'bin/bundle'),
        <<~BASH
          #!/usr/bin/env bash
          set -e

          mkdir -p tmp

          if [[ "$*" == *"exec reactiveview doctor --fix"* ]]; then
            printf "%s\n" "$*" >> tmp/bundle-invocations.log
            exit 1
          fi

          printf "%s\n" "$*" >> tmp/bundle-invocations.log
        BASH
      )
      FileUtils.chmod(0o755, File.join(app_dir, 'bin/bundle'))

      _stdout, stderr, status = run_script(path: File.join(app_dir, 'bin/reactive-view-dev'), app_dir: app_dir)
      expect(status.success?).to be(true), stderr

      bundle_invocations = File.read(File.join(app_dir, 'tmp/bundle-invocations.log'))
      expect(bundle_invocations).to include('exec reactiveview doctor --fix')
      expect(bundle_invocations).to include('exec reactiveview dev')
    end
  end

  it 'starts the Procfile runner process from bin/dev' do
    with_fake_app do |app_dir|
      File.write(
        File.join(app_dir, 'bin/forman'),
        <<~BASH
          #!/usr/bin/env bash
          set -e

          mkdir -p tmp
          printf "%s\n" "$*" > tmp/forman-command.log
        BASH
      )
      FileUtils.chmod(0o755, File.join(app_dir, 'bin/forman'))

      _stdout, stderr, status = run_script(path: File.join(app_dir, 'bin/dev'), app_dir: app_dir)
      expect(status.success?).to be(true), stderr

      forman_command = File.read(File.join(app_dir, 'tmp/forman-command.log'))
      expect(forman_command).to include('start -f Procfile.dev')
    end
  end

  it 'selects fallback ports when defaults are occupied and env vars are unset' do
    with_fake_app do |app_dir|
      File.write(
        File.join(app_dir, 'bin/lsof'),
        <<~BASH
          #!/usr/bin/env bash
          set -e

          args="$*"
          if [[ "$args" == *"-iTCP:3000"* ]] || [[ "$args" == *"-iTCP:3001"* ]]; then
            exit 0
          fi

          exit 1
        BASH
      )
      FileUtils.chmod(0o755, File.join(app_dir, 'bin/lsof'))

      File.write(
        File.join(app_dir, 'bin/forman'),
        <<~BASH
          #!/usr/bin/env bash
          set -e

          mkdir -p tmp
          printf "%s\n" "$*" > tmp/forman-command.log
          printf "%s|%s\n" "$PORT" "$REACTIVE_VIEW_DAEMON_PORT" > tmp/forman-env.log
        BASH
      )
      FileUtils.chmod(0o755, File.join(app_dir, 'bin/forman'))

      _stdout, stderr, status = run_script(
        path: File.join(app_dir, 'bin/dev'),
        app_dir: app_dir,
        env_overrides: { 'PORT' => nil, 'REACTIVE_VIEW_DAEMON_PORT' => nil }
      )
      expect(status.success?).to be(true), stderr

      forman_command = File.read(File.join(app_dir, 'tmp/forman-command.log'))
      forman_env = File.read(File.join(app_dir, 'tmp/forman-env.log'))

      expect(forman_command).to include('start -f Procfile.dev')
      expect(forman_env).to include('3200|3301')
    end
  end

  it 'starts the rails server process from bin/web' do
    with_fake_app do |app_dir|
      _stdout, stderr, status = run_script(path: File.join(app_dir, 'bin/web'), app_dir: app_dir)
      expect(status.success?).to be(true), stderr

      server_command = File.read(File.join(app_dir, 'tmp/server-command.log'))
      expect(server_command).to include('server -b 0.0.0.0 -p 3131')
    end
  end
end
