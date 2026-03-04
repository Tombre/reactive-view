# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'json'
require 'fileutils'

RSpec.describe ReactiveView::Doctor do
  let(:tmp_root) { Pathname.new(Dir.mktmpdir('reactive_view_doctor')) }
  let(:working_dir) { tmp_root.join('.reactive_view') }
  let(:configuration) { instance_double(ReactiveView::Configuration, working_directory_absolute_path: working_dir) }
  let(:doctor) { described_class.new(rails_root: tmp_root, configuration: configuration) }

  before do
    tmp_root.join('node_modules', '@reactive-view', 'core', 'dist').mkpath
    tmp_root.join('node_modules', '@reactive-view', 'core', 'dist', 'cli.js').write('// built')
    tmp_root.join('package.json').write(
      JSON.pretty_generate(
        {
          dependencies: {
            '@reactive-view/core' => '^0.1.0'
          }
        }
      )
    )

    working_dir.mkpath
    working_dir.join('app.config.ts').write('// config')

    allow(doctor).to receive(:capture_command).with('node', '-v').and_return(['v20.11.0', true])
  end

  after do
    FileUtils.rm_rf(tmp_root)
  end

  it 'reports success when required pieces exist' do
    result = doctor.diagnose

    expect(result[:ok]).to be(true)
    expect(result[:checks]).to all(include(:name, :ok, :message, :fix))
  end

  it 'fails when node is unavailable' do
    allow(doctor).to receive(:capture_command).with('node', '-v').and_return(['', false])

    result = doctor.diagnose
    node_check = result[:checks].find { |check| check[:name] == 'Node.js' }

    expect(node_check[:ok]).to be(false)
    expect(node_check[:fix]).to include('Install Node.js 18+')
  end

  it 'fails when .reactive_view is missing' do
    FileUtils.rm_rf(working_dir)

    result = doctor.diagnose
    working_dir_check = result[:checks].find { |check| check[:name] == 'Working directory' }

    expect(working_dir_check[:ok]).to be(false)
    expect(working_dir_check[:fix]).to include('reactive_view:setup')
  end

  it 'fails for file dependency when dist cli is missing' do
    local_core = tmp_root.join('vendor', 'reactive_view_core')
    local_core.mkpath
    tmp_root.join('package.json').write(
      JSON.pretty_generate(
        {
          dependencies: {
            '@reactive-view/core' => 'file:vendor/reactive_view_core'
          }
        }
      )
    )

    result = doctor.diagnose
    local_build_check = result[:checks].find { |check| check[:name] == 'Local core build' }

    expect(local_build_check[:ok]).to be(false)
    expect(local_build_check[:fix]).to include('npm run build --prefix')
  end
end
