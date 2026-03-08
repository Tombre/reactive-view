# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe ReactiveView::GuardRegistry do
  describe '.path_to_class_name' do
    it 'converts empty path to Pages::Guard' do
      expect(described_class.path_to_class_name('')).to eq('Pages::Guard')
    end

    it 'converts nested grouped paths to guard class names' do
      expect(described_class.path_to_class_name('(admin)/dashboard')).to eq('Pages::Admin::Dashboard::Guard')
    end
  end

  describe '.file_to_guard_path' do
    let(:pages_path) { Pathname.new('/app/pages') }

    before do
      allow(ReactiveView.configuration).to receive(:pages_absolute_path).and_return(pages_path)
    end

    it 'maps root _guard.rb to an empty guard path' do
      expect(described_class.file_to_guard_path('/app/pages/_guard.rb')).to eq('')
    end

    it 'maps nested _guard.rb to its folder path' do
      expect(described_class.file_to_guard_path('/app/pages/(admin)/dashboard/_guard.rb')).to eq('(admin)/dashboard')
    end
  end

  describe '.classes_for_loader_path' do
    let(:temp_dir) { Pathname.new(Dir.mktmpdir('reactive_view_guard_registry')) }
    let(:pages_path) { temp_dir.join('app/pages') }

    before do
      allow(ReactiveView.configuration).to receive(:pages_absolute_path).and_return(pages_path)
      FileUtils.mkdir_p(pages_path.join('(admin)/dashboard'))
    end

    after do
      FileUtils.rm_rf(temp_dir)
    end

    it 'returns guards from root to nearest ancestor' do
      stub_const('Pages::Guard', Class.new(ReactiveView::RouteGuard))
      stub_const('Pages::Admin::Guard', Class.new(ReactiveView::RouteGuard))
      stub_const('Pages::Admin::Dashboard::Guard', Class.new(ReactiveView::RouteGuard))

      classes = described_class.classes_for_loader_path('(admin)/dashboard/settings')

      expect(classes).to eq([
                              Pages::Guard,
                              Pages::Admin::Guard,
                              Pages::Admin::Dashboard::Guard
                            ])
    end

    it 'includes the loader path itself when it is a layout directory' do
      stub_const('Pages::Admin::Guard', Class.new(ReactiveView::RouteGuard))
      stub_const('Pages::Admin::Dashboard::Guard', Class.new(ReactiveView::RouteGuard))

      classes = described_class.classes_for_loader_path('(admin)/dashboard')

      expect(classes).to eq([
                              Pages::Admin::Guard,
                              Pages::Admin::Dashboard::Guard
                            ])
    end
  end
end
