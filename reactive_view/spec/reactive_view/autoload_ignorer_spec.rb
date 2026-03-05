# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe ReactiveView::AutoloadIgnorer do
  AutoloaderStub = Struct.new(:ignored_paths) do
    def ignore(path)
      ignored_paths << path
    end
  end

  let(:logger) { instance_double(Logger, debug: nil, info: nil) }

  describe '.ignore_pages_paths!' do
    it 'ignores grouped route directories and loader file globs under app/pages' do
      tmp_dir = Pathname.new(Dir.mktmpdir('reactive_view_autoload_ignorer'))
      pages_path = tmp_dir.join('app/pages')

      grouped_dir = pages_path.join('(admin)')
      loader_file = pages_path.join('ai/chat.loader.rb')
      nested_loader_file = pages_path.join('users/[id].loader.rb')
      regular_ruby_file = pages_path.join('models/user.rb')

      FileUtils.mkdir_p(grouped_dir)
      FileUtils.mkdir_p(loader_file.dirname)
      FileUtils.mkdir_p(nested_loader_file.dirname)
      FileUtils.mkdir_p(regular_ruby_file.dirname)

      loader_file.write("# frozen_string_literal: true\n")
      nested_loader_file.write("# frozen_string_literal: true\n")
      regular_ruby_file.write("# frozen_string_literal: true\n")

      main_autoloader = AutoloaderStub.new([])
      once_autoloader = AutoloaderStub.new([])

      result = described_class.ignore_pages_paths!(
        pages_path: pages_path,
        autoloaders: [main_autoloader, once_autoloader],
        logger: logger
      )

      expect(result[:grouped_dirs]).to contain_exactly(grouped_dir.to_s)
      expect(result[:loader_files]).to contain_exactly(loader_file.to_s, nested_loader_file.to_s)

      loader_glob = pages_path.join('**/*.loader.rb').to_s

      [main_autoloader, once_autoloader].each do |autoloader|
        expect(autoloader.ignored_paths).to include(grouped_dir.to_s)
        expect(autoloader.ignored_paths).to include(loader_glob)
        expect(autoloader.ignored_paths).not_to include(regular_ruby_file.to_s)
      end
    ensure
      FileUtils.rm_rf(tmp_dir)
    end

    it 'returns empty results when app/pages does not exist' do
      tmp_dir = Pathname.new(Dir.mktmpdir('reactive_view_autoload_ignorer'))
      pages_path = tmp_dir.join('app/pages')
      autoloader = AutoloaderStub.new([])

      result = described_class.ignore_pages_paths!(pages_path: pages_path, autoloaders: [autoloader], logger: logger)

      expect(result).to eq(grouped_dirs: [], loader_files: [])
      expect(autoloader.ignored_paths).to be_empty
    ensure
      FileUtils.rm_rf(tmp_dir)
    end
  end
end
