# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'timeout'
require 'tmpdir'

require_relative '../spec_helper'

RSpec.describe 'bin/dev startup flow' do
  let(:source_script_path) { File.expand_path('../../bin/dev', __dir__) }

  def with_fake_app
    Dir.mktmpdir('reactive-view-bin-dev-spec') do |dir|
      FileUtils.mkdir_p(File.join(dir, 'bin'))
      FileUtils.mkdir_p(File.join(dir, 'tmp'))
      FileUtils.mkdir_p(File.join(dir, 'tmp/pids'))

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
            db:prepare)
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

  def stop_process(pid)
    return unless pid

    Process.kill('TERM', pid)
    Timeout.timeout(2) { Process.wait(pid) }
  rescue Errno::ESRCH, Errno::ECHILD
    nil
  rescue Timeout::Error
    Process.kill('KILL', pid)
    Process.wait(pid)
  rescue Errno::ESRCH
    nil
  end

  it 'runs setup, sync, and starts rails server when working directory is missing' do
    with_fake_app do |app_dir|
      stdout, stderr, status = run_dev_script(app_dir: app_dir)
      expect(status.success?).to be(true), stderr

      invocations = File.read(File.join(app_dir, 'tmp/rails-invocations.log'))
      expect(invocations).to include('reactive_view:setup')
      expect(invocations).to include('reactive_view:sync')
      expect(invocations).to include('db:prepare')

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
      expect(invocations).to include('db:prepare')
    end
  end

  it 'removes stale server pid files before starting rails' do
    with_fake_app do |app_dir|
      FileUtils.mkdir_p(File.join(app_dir, '.reactive_view'))
      pid_file = File.join(app_dir, 'tmp/pids/server.pid')
      File.write(pid_file, "999999\n")

      stdout, stderr, status = run_dev_script(app_dir: app_dir)
      expect(status.success?).to be(true), stderr
      expect(stdout).to include('Removing stale server PID file')
      expect(File.exist?(pid_file)).to be(false)
    end
  end

  it 'exits early when an existing rails server pid is alive' do
    with_fake_app do |app_dir|
      FileUtils.mkdir_p(File.join(app_dir, '.reactive_view'))
      pid_file = File.join(app_dir, 'tmp/pids/server.pid')
      File.write(pid_file, "#{Process.pid}\n")

      stdout, _stderr, status = run_dev_script(app_dir: app_dir)
      expect(status.success?).to be(false)
      expect(stdout).to include('A process is already running')
      expect(stdout).to include("PID #{Process.pid}")
      expect(File.exist?(File.join(app_dir, 'tmp/server-command.log'))).to be(false)
    end
  end

  it 'stops an existing rails server process and continues startup' do
    with_fake_app do |app_dir|
      FileUtils.mkdir_p(File.join(app_dir, '.reactive_view'))
      pid_file = File.join(app_dir, 'tmp/pids/server.pid')

      existing_server_pid = Process.spawn(
        'ruby',
        '-e',
        '$0 = "bin/rails server"; trap("TERM") { exit }; loop { sleep 1 }',
        out: File::NULL,
        err: File::NULL
      )

      File.write(pid_file, "#{existing_server_pid}\n")

      stdout, stderr, status = run_dev_script(app_dir: app_dir)
      expect(status.success?).to be(true), stderr
      expect(stdout).to include('Stopping existing Rails server')
      expect(File.exist?(pid_file)).to be(false)
      _pid, process_status = Process.wait2(existing_server_pid)
      expect(process_status).to be_a(Process::Status)
    ensure
      stop_process(existing_server_pid)
    end
  end
end
