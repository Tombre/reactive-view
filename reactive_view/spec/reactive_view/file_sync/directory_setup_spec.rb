# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe ReactiveView::FileSync::DirectorySetup do
  describe '.install_dependencies' do
    let(:working_dir) { Pathname.new(Dir.mktmpdir('reactive_view_directory_setup')) }

    after do
      FileUtils.rm_rf(working_dir)
    end

    it 'invokes npm install with argv form' do
      allow(ReactiveView.logger).to receive(:info)
      expect(described_class).to receive(:system).with('npm', 'install', '--silent').and_return(true)

      described_class.send(:install_dependencies, working_dir)
    end

    it 'raises when npm install fails' do
      allow(ReactiveView.logger).to receive(:info)
      allow(described_class).to receive(:system).with('npm', 'install', '--silent').and_return(false)

      expect do
        described_class.send(:install_dependencies, working_dir)
      end.to raise_error(ReactiveView::Error, 'Failed to install npm dependencies')
    end
  end
end
