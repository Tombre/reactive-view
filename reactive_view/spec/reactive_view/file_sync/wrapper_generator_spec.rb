# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReactiveView::FileSync::WrapperGenerator do
  let(:temp_dir) { Dir.mktmpdir }
  let(:pages_path) { Pathname.new(File.join(temp_dir, 'pages')) }
  let(:working_dir) { Pathname.new(File.join(temp_dir, 'working')) }
  let(:routes_path) { working_dir.join('src', 'routes') }

  before do
    FileUtils.mkdir_p(pages_path)
    FileUtils.mkdir_p(routes_path)

    allow(ReactiveView.configuration).to receive(:pages_absolute_path).and_return(pages_path)
    allow(ReactiveView.configuration).to receive(:working_directory_absolute_path).and_return(working_dir)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '.generate_all' do
    it 'generates wrappers for regular TSX files' do
      File.write(pages_path.join('index.tsx'), 'export default function Index() {}')
      File.write(pages_path.join('about.tsx'), 'export default function About() {}')

      described_class.generate_all

      expect(routes_path.join('index.tsx')).to exist
      expect(routes_path.join('about.tsx')).to exist
    end

    it 'skips files in private folders (underscore prefix)' do
      # Create regular page
      File.write(pages_path.join('index.tsx'), 'export default function Index() {}')

      # Create private folder with files
      FileUtils.mkdir_p(pages_path.join('_components'))
      File.write(pages_path.join('_components/Button.tsx'), 'export default function Button() {}')
      File.write(pages_path.join('_components/Navigation.tsx'), 'export default function Navigation() {}')

      described_class.generate_all

      expect(routes_path.join('index.tsx')).to exist
      expect(routes_path.join('_components')).not_to exist
      expect(routes_path.join('_components/Button.tsx')).not_to exist
      expect(routes_path.join('_components/Navigation.tsx')).not_to exist
    end

    it 'skips private files (underscore prefix)' do
      File.write(pages_path.join('index.tsx'), 'export default function Index() {}')
      File.write(pages_path.join('_helpers.tsx'), 'export function helper() {}')

      described_class.generate_all

      expect(routes_path.join('index.tsx')).to exist
      expect(routes_path.join('_helpers.tsx')).not_to exist
    end

    it 'skips nested private folders' do
      FileUtils.mkdir_p(pages_path.join('users'))
      FileUtils.mkdir_p(pages_path.join('users/_partials'))
      File.write(pages_path.join('users/index.tsx'), 'export default function Users() {}')
      File.write(pages_path.join('users/_partials/Card.tsx'), 'export default function Card() {}')

      described_class.generate_all

      expect(routes_path.join('users/index.tsx')).to exist
      expect(routes_path.join('users/_partials')).not_to exist
      expect(routes_path.join('users/_partials/Card.tsx')).not_to exist
    end

    it 'generates wrappers for grouped routes but not private folders' do
      FileUtils.mkdir_p(pages_path.join('(admin)'))
      FileUtils.mkdir_p(pages_path.join('_shared'))
      File.write(pages_path.join('(admin)/dashboard.tsx'), 'export default function Dashboard() {}')
      File.write(pages_path.join('_shared/Layout.tsx'), 'export default function Layout() {}')

      described_class.generate_all

      expect(routes_path.join('(admin)/dashboard.tsx')).to exist
      expect(routes_path.join('_shared')).not_to exist
    end
  end
end
