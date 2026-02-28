# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'tmpdir'

RSpec.describe ReactiveView::FileSync::DirectorySetup do
  let(:tmp_dir) { Pathname.new(Dir.mktmpdir('reactive_view_directory_setup')) }
  let(:working_dir) { tmp_dir.join('.reactive_view') }
  let(:template_dir) { tmp_dir.join('template') }

  before do
    FileUtils.mkdir_p(template_dir.join('src'))
    FileUtils.mkdir_p(template_dir.join('node_modules/foo'))
    FileUtils.mkdir_p(template_dir.join('.output/server'))
    FileUtils.mkdir_p(template_dir.join('.vinxi/client'))
    File.write(template_dir.join('app.config.ts'), 'export default {}')

    allow(ReactiveView.configuration).to receive(:working_directory_absolute_path).and_return(working_dir)
    allow(described_class).to receive(:gem_template_path).and_return(template_dir)
    allow(Rails).to receive(:root).and_return(tmp_dir)
  end

  after do
    FileUtils.rm_rf(tmp_dir)
  end

  describe '.setup' do
    it 'creates the working directory from template files' do
      allow(described_class).to receive(:missing_packages).and_return([], [])

      described_class.setup

      expect(working_dir).to exist
      expect(working_dir.join('app.config.ts')).to exist
      expect(working_dir.join('src/routes')).to exist
      expect(working_dir.join('node_modules')).not_to exist
      expect(working_dir.join('.output')).not_to exist
      expect(working_dir.join('.vinxi')).not_to exist
    end

    it 'installs missing dependencies when packages are absent' do
      runtime_dependencies = {
        '@reactive-view/core' => '^0.1.0',
        'vinxi' => '^0.5.3'
      }

      allow(described_class).to receive(:required_runtime_dependencies).and_return(runtime_dependencies)
      allow(described_class).to receive(:missing_packages)
        .with(runtime_dependencies.keys)
        .and_return(['vinxi'])
      allow(described_class).to receive(:missing_packages)
        .with(described_class::REQUIRED_DEV_DEPENDENCIES.keys)
        .and_return(['typescript'])

      expect(described_class).to receive(:install_dependencies)
        .with(runtime_dependencies, ['vinxi'], ['typescript'])

      described_class.setup
    end

    it 'skips npm installation when all required packages are present' do
      allow(described_class).to receive(:missing_packages).and_return([], [])

      expect(described_class).not_to receive(:install_dependencies)

      described_class.setup
    end

    it 'refreshes managed template files when working directory already exists' do
      allow(described_class).to receive(:missing_packages).and_return([], [])
      FileUtils.mkdir_p(working_dir)
      working_dir.join('app.config.ts').write('outdated-config')

      described_class.setup

      expect(working_dir.join('app.config.ts').read).to eq('export default {}')
    end
  end

  describe '.install_dependencies' do
    it 'adds missing dependencies to package.json before npm install' do
      package_json = tmp_dir.join('package.json')
      package_json.write(
        JSON.pretty_generate(
          {
            'name' => 'test-app',
            'dependencies' => { 'vinxi' => '^0.5.0' },
            'devDependencies' => {}
          }
        ) + "\n"
      )

      allow(Dir).to receive(:chdir).with(tmp_dir).and_yield
      allow(described_class).to receive(:system).with('npm install --silent').and_return(true)

      described_class.send(
        :install_dependencies,
        {
          '@reactive-view/core' => '^0.1.0',
          'vinxi' => '^0.5.3'
        },
        ['@reactive-view/core', 'vinxi'],
        ['typescript']
      )

      updated = JSON.parse(package_json.read)
      expect(updated.dig('dependencies', '@reactive-view/core')).to eq('^0.1.0')
      expect(updated.dig('dependencies', 'vinxi')).to eq('^0.5.0')
      expect(updated.dig('devDependencies', 'typescript')).to eq('^5.7.2')
    end

    it 'raises when package.json is missing at Rails root' do
      expect do
        described_class.send(:install_dependencies, { 'vinxi' => '^0.5.3' }, ['vinxi'], [])
      end.to raise_error(ReactiveView::Error, 'Missing package.json at Rails root')
    end
  end

  describe '.package_installed?' do
    it 'detects packages hoisted to an ancestor node_modules directory' do
      workspace_app_root = tmp_dir.join('apps/example')
      FileUtils.mkdir_p(workspace_app_root)
      FileUtils.mkdir_p(tmp_dir.join('node_modules/vinxi'))

      allow(Rails).to receive(:root).and_return(workspace_app_root)

      expect(described_class.send(:package_installed?, 'vinxi')).to be true
    end
  end
end
