# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReactiveView::Types::TypescriptGenerator do
  let(:generator) { described_class.new }

  describe '#path_to_interface_name' do
    it 'converts simple paths to interface names' do
      result = generator.send(:path_to_interface_name, 'users/index')
      expect(result).to eq('UsersIndexLoaderData')
    end

    it 'handles dynamic segments' do
      result = generator.send(:path_to_interface_name, 'users/[id]')
      expect(result).to eq('UsersIdLoaderData')
    end

    it 'strips route group parentheses' do
      result = generator.send(:path_to_interface_name, '(admin)/dashboard')
      expect(result).to eq('AdminDashboardLoaderData')
    end

    it 'handles multiple route groups' do
      result = generator.send(:path_to_interface_name, '(admin)/(auth)/login')
      expect(result).to eq('AdminAuthLoginLoaderData')
    end

    it 'handles route groups with dynamic segments' do
      result = generator.send(:path_to_interface_name, '(admin)/users/[id]')
      expect(result).to eq('AdminUsersIdLoaderData')
    end

    it 'handles catch-all routes' do
      result = generator.send(:path_to_interface_name, 'docs/[...slug]')
      expect(result).to eq('DocsSlugLoaderData')
    end

    it 'handles optional catch-all routes' do
      result = generator.send(:path_to_interface_name, 'docs/[[...slug]]')
      expect(result).to eq('DocsSlugLoaderData')
    end

    it 'handles complex paths with multiple features' do
      result = generator.send(:path_to_interface_name, '(admin)/(auth)/users/[id]/edit')
      expect(result).to eq('AdminAuthUsersIdEditLoaderData')
    end
  end

  describe '#dry_type_to_typescript' do
    it 'converts String to string' do
      result = generator.send(:dry_type_to_typescript, ReactiveView::Types::String)
      expect(result).to eq('string')
    end

    it 'converts Integer to number' do
      result = generator.send(:dry_type_to_typescript, ReactiveView::Types::Integer)
      expect(result).to eq('number')
    end

    it 'converts Bool to boolean' do
      result = generator.send(:dry_type_to_typescript, ReactiveView::Types::Bool)
      expect(result).to eq('boolean')
    end

    it 'converts Array[String] to string[]' do
      result = generator.send(:dry_type_to_typescript, ReactiveView::Types::Array(ReactiveView::Types::String))
      expect(result).to eq('string[]')
    end

    it 'converts Optional[String] to string | null' do
      result = generator.send(:dry_type_to_typescript, ReactiveView::Types::String.optional)
      expect(result).to eq('string | null')
    end

    it 'converts Hash.schema to object type' do
      schema = ReactiveView::Types::Hash.schema(
        id: ReactiveView::Types::Integer,
        name: ReactiveView::Types::String
      )
      result = generator.send(:dry_type_to_typescript, schema)
      expect(result).to eq('{ id: number; name: string }')
    end

    it 'converts Date to string (ISO format)' do
      result = generator.send(:dry_type_to_typescript, ReactiveView::Types::Date)
      expect(result).to eq('string')
    end
  end
end
