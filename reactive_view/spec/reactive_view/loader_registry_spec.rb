# frozen_string_literal: true

require 'spec_helper'

# Load the loader registry and loader
require 'reactive_view/loader_registry'
require 'reactive_view/loader'

RSpec.describe ReactiveView::LoaderRegistry do
  before do
    ReactiveView.configure do |config|
      config.pages_path = 'app/pages'
    end
  end

  describe '.path_to_class_name' do
    it 'converts index to Pages::IndexLoader' do
      expect(described_class.path_to_class_name('index')).to eq('Pages::IndexLoader')
    end

    it 'converts nested index to Pages::Users::IndexLoader' do
      expect(described_class.path_to_class_name('users/index')).to eq('Pages::Users::IndexLoader')
    end

    it 'converts dynamic [id] to Pages::Users::IdLoader' do
      expect(described_class.path_to_class_name('users/[id]')).to eq('Pages::Users::IdLoader')
    end

    it 'converts catch-all [...slug] to Pages::Blog::SlugLoader' do
      expect(described_class.path_to_class_name('blog/[...slug]')).to eq('Pages::Blog::SlugLoader')
    end

    it 'converts optional [[id]] to Pages::Users::IdLoader' do
      expect(described_class.path_to_class_name('users/[[id]]')).to eq('Pages::Users::IdLoader')
    end

    it 'handles deeply nested paths' do
      expect(described_class.path_to_class_name('admin/users/[id]/posts'))
        .to eq('Pages::Admin::Users::Id::PostsLoader')
    end
  end

  describe '.file_to_loader_path' do
    let(:pages_path) { Pathname.new('/app/pages') }

    before do
      allow(ReactiveView.configuration).to receive(:pages_absolute_path).and_return(pages_path)
    end

    it 'converts a loader file path to loader path' do
      file_path = '/app/pages/users/index.loader.rb'
      expect(described_class.file_to_loader_path(file_path)).to eq('users/index')
    end

    it 'handles dynamic route loader files' do
      file_path = '/app/pages/users/[id].loader.rb'
      expect(described_class.file_to_loader_path(file_path)).to eq('users/[id]')
    end

    it 'handles root index loader' do
      file_path = '/app/pages/index.loader.rb'
      expect(described_class.file_to_loader_path(file_path)).to eq('index')
    end
  end

  describe '.class_for_path' do
    context 'when loader class exists' do
      before do
        # Define a test loader class
        stub_const('Pages::TestLoader', Class.new(ReactiveView::Loader))
      end

      it 'returns the loader class' do
        expect(described_class.class_for_path('test')).to eq(Pages::TestLoader)
      end
    end

    context 'when loader class does not exist' do
      it 'returns the default ReactiveView::Loader' do
        expect(described_class.class_for_path('nonexistent/path')).to eq(ReactiveView::Loader)
      end
    end
  end
end
