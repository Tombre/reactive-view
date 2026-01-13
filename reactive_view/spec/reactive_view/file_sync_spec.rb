# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReactiveView::FileSync do
  describe '.private_path?' do
    context 'with underscore-prefixed folders' do
      it 'returns true for top-level private folders' do
        expect(described_class.private_path?('_components/Button.tsx')).to be true
      end

      it 'returns true for nested private folders' do
        expect(described_class.private_path?('users/_partials/Card.tsx')).to be true
      end

      it 'returns true for deeply nested private folders' do
        expect(described_class.private_path?('admin/dashboard/_widgets/Chart.tsx')).to be true
      end
    end

    context 'with underscore-prefixed files' do
      it 'returns true for private files at top level' do
        expect(described_class.private_path?('_helpers.ts')).to be true
      end

      it 'returns true for private files in subdirectories' do
        expect(described_class.private_path?('utils/_formatters.ts')).to be true
      end
    end

    context 'with regular paths' do
      it 'returns false for simple page routes' do
        expect(described_class.private_path?('index.tsx')).to be false
        expect(described_class.private_path?('about.tsx')).to be false
      end

      it 'returns false for nested page routes' do
        expect(described_class.private_path?('users/index.tsx')).to be false
        expect(described_class.private_path?('users/[id].tsx')).to be false
      end

      it 'returns false for grouped routes' do
        expect(described_class.private_path?('(admin)/dashboard.tsx')).to be false
        expect(described_class.private_path?('(admin)/users/index.tsx')).to be false
      end

      it 'returns false for dynamic routes' do
        expect(described_class.private_path?('[...slug].tsx')).to be false
        expect(described_class.private_path?('blog/[[id]].tsx')).to be false
      end
    end

    context 'with Pathname objects' do
      it 'handles Pathname input' do
        expect(described_class.private_path?(Pathname.new('_components/Button.tsx'))).to be true
        expect(described_class.private_path?(Pathname.new('users/index.tsx'))).to be false
      end
    end

    context 'edge cases' do
      it 'returns false for files that contain underscore but do not start with it' do
        expect(described_class.private_path?('my_page.tsx')).to be false
        expect(described_class.private_path?('user_profile/index.tsx')).to be false
      end

      it 'returns true when any segment starts with underscore' do
        expect(described_class.private_path?('public/_private/file.tsx')).to be true
      end

      it 'returns false for empty path' do
        expect(described_class.private_path?('')).to be false
      end
    end
  end
end
