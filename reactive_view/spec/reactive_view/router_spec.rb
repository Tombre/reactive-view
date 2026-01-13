# frozen_string_literal: true

require 'spec_helper'

# Load the router
require 'reactive_view/loader_registry'
require 'reactive_view/router'

RSpec.describe ReactiveView::Router do
  before do
    ReactiveView.configure do |config|
      config.pages_path = 'app/pages'
    end
  end

  describe '.segment_to_route' do
    it 'converts dynamic segments [id] to :id' do
      expect(described_class.send(:segment_to_route, '[id]')).to eq(':id')
    end

    it 'converts catch-all segments [...slug] to *slug' do
      expect(described_class.send(:segment_to_route, '[...slug]')).to eq('*slug')
    end

    it 'converts optional segments [[id]] to (/:id)' do
      expect(described_class.send(:segment_to_route, '[[id]]')).to eq('(/:id)')
    end

    it 'converts index to empty string' do
      expect(described_class.send(:segment_to_route, 'index')).to eq('')
    end

    it 'preserves static segments' do
      expect(described_class.send(:segment_to_route, 'users')).to eq('users')
      expect(described_class.send(:segment_to_route, 'about')).to eq('about')
    end
  end

  describe '.normalize_route_path' do
    it 'adds leading slash to paths' do
      expect(described_class.send(:normalize_route_path, 'users')).to eq('/users')
    end

    it 'returns / for empty paths' do
      expect(described_class.send(:normalize_route_path, '')).to eq('/')
    end

    it 'removes duplicate slashes' do
      expect(described_class.send(:normalize_route_path, 'users//profile')).to eq('/users/profile')
    end

    it 'removes trailing slashes' do
      expect(described_class.send(:normalize_route_path, 'users/')).to eq('/users')
    end
  end

  describe '.calculate_priority' do
    it 'gives lowest priority to catch-all segments' do
      catch_all = described_class.send(:calculate_priority, ['blog', '[...slug]'])
      static = described_class.send(:calculate_priority, %w[blog posts])

      expect(catch_all).to be > static
    end

    it 'gives lower priority to optional segments than dynamic' do
      optional = described_class.send(:calculate_priority, ['users', '[[id]]'])
      dynamic = described_class.send(:calculate_priority, ['users', '[id]'])

      expect(optional).to be > dynamic
    end

    it 'gives lower priority to dynamic segments than static' do
      dynamic = described_class.send(:calculate_priority, ['users', '[id]'])
      static = described_class.send(:calculate_priority, %w[users new])

      expect(dynamic).to be > static
    end

    it 'calculates priority based on segment count and type' do
      # Priority is calculated as sum of segment weights minus a small adjustment for length
      # Static segments add 1 each
      short = described_class.send(:calculate_priority, ['users']) # 1 - 0.1 = 0.9
      long = described_class.send(:calculate_priority, %w[users list]) # 2 - 0.2 = 1.8

      # More static segments = higher priority number
      expect(long).to be > short
    end
  end

  describe '.sort_routes' do
    it 'sorts static routes before dynamic routes' do
      routes = [
        { segments: ['users', '[id]'], priority: 11 },
        { segments: %w[users new], priority: 2 }
      ]

      sorted = described_class.send(:sort_routes, routes)

      expect(sorted.first[:segments]).to eq(%w[users new])
    end

    it 'sorts dynamic routes before catch-all routes' do
      routes = [
        { segments: ['blog', '[...slug]'], priority: 1001 },
        { segments: ['blog', '[id]'], priority: 11 }
      ]

      sorted = described_class.send(:sort_routes, routes)

      expect(sorted.first[:segments]).to eq(['blog', '[id]'])
    end
  end

  describe '.parse_route' do
    it 'parses a simple page route' do
      route = described_class.send(:parse_route, Pathname.new('about.tsx'))

      expect(route[:file_path]).to eq('about.tsx')
      expect(route[:route_path]).to eq('/about')
      expect(route[:loader_path]).to eq('about')
    end

    it 'parses an index route' do
      route = described_class.send(:parse_route, Pathname.new('index.tsx'))

      expect(route[:file_path]).to eq('index.tsx')
      expect(route[:route_path]).to eq('/')
      expect(route[:loader_path]).to eq('index')
    end

    it 'parses a nested route' do
      route = described_class.send(:parse_route, Pathname.new('users/index.tsx'))

      expect(route[:file_path]).to eq('users/index.tsx')
      expect(route[:route_path]).to eq('/users')
      expect(route[:loader_path]).to eq('users/index')
    end

    it 'parses a dynamic route' do
      route = described_class.send(:parse_route, Pathname.new('users/[id].tsx'))

      expect(route[:file_path]).to eq('users/[id].tsx')
      expect(route[:route_path]).to eq('/users/:id')
      expect(route[:loader_path]).to eq('users/[id]')
    end

    it 'parses a catch-all route' do
      route = described_class.send(:parse_route, Pathname.new('blog/[...slug].tsx'))

      expect(route[:file_path]).to eq('blog/[...slug].tsx')
      expect(route[:route_path]).to eq('/blog/*slug')
      expect(route[:loader_path]).to eq('blog/[...slug]')
    end

    it 'parses an optional parameter route' do
      route = described_class.send(:parse_route, Pathname.new('users/[[id]].tsx'))

      expect(route[:file_path]).to eq('users/[[id]].tsx')
      expect(route[:route_path]).to eq('/users/(/:id)')
      expect(route[:loader_path]).to eq('users/[[id]]')
    end
  end

  describe '.scan_directory' do
    let(:temp_dir) { Dir.mktmpdir }
    let(:pages_path) { Pathname.new(temp_dir) }

    before do
      allow(ReactiveView.configuration).to receive(:pages_absolute_path).and_return(pages_path)
    end

    after do
      FileUtils.rm_rf(temp_dir)
    end

    it 'excludes files in private folders (underscore prefix)' do
      # Create regular route files
      FileUtils.mkdir_p(pages_path.join('users'))
      File.write(pages_path.join('index.tsx'), '')
      File.write(pages_path.join('users/index.tsx'), '')

      # Create private folder with files
      FileUtils.mkdir_p(pages_path.join('_components'))
      File.write(pages_path.join('_components/Button.tsx'), '')
      File.write(pages_path.join('_components/Navigation.tsx'), '')

      routes = described_class.send(:scan_directory, pages_path)
      file_paths = routes.map { |r| r[:file_path] }

      expect(file_paths).to include('index.tsx')
      expect(file_paths).to include('users/index.tsx')
      expect(file_paths).not_to include('_components/Button.tsx')
      expect(file_paths).not_to include('_components/Navigation.tsx')
    end

    it 'excludes private files (underscore prefix)' do
      File.write(pages_path.join('index.tsx'), '')
      File.write(pages_path.join('_helpers.ts'), '')

      routes = described_class.send(:scan_directory, pages_path)
      file_paths = routes.map { |r| r[:file_path] }

      expect(file_paths).to include('index.tsx')
      expect(file_paths).not_to include('_helpers.ts')
    end

    it 'excludes nested private folders' do
      FileUtils.mkdir_p(pages_path.join('users/_partials'))
      File.write(pages_path.join('users/index.tsx'), '')
      File.write(pages_path.join('users/_partials/Card.tsx'), '')

      routes = described_class.send(:scan_directory, pages_path)
      file_paths = routes.map { |r| r[:file_path] }

      expect(file_paths).to include('users/index.tsx')
      expect(file_paths).not_to include('users/_partials/Card.tsx')
    end
  end
end
