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

  describe '#sanitize_js_identifier' do
    it 'returns valid identifiers unchanged' do
      result = generator.send(:sanitize_js_identifier, 'validName')
      expect(result).to eq('validName')
    end

    it 'allows underscores and dollar signs' do
      result = generator.send(:sanitize_js_identifier, '_private$var')
      expect(result).to eq('_private$var')
    end

    it 'replaces invalid characters with underscores' do
      result = generator.send(:sanitize_js_identifier, 'my-mutation-name')
      expect(result).to eq('my_mutation_name')
    end

    it 'prefixes identifiers starting with numbers' do
      result = generator.send(:sanitize_js_identifier, '123abc')
      expect(result).to eq('_123abc')
    end

    it 'handles empty strings' do
      result = generator.send(:sanitize_js_identifier, '')
      expect(result).to eq('_unnamed')
    end

    it 'handles reserved words by adding suffix' do
      result = generator.send(:sanitize_js_identifier, 'class')
      expect(result).to eq('class_')
    end

    it 'handles reserved words case-insensitively' do
      result = generator.send(:sanitize_js_identifier, 'CLASS')
      expect(result).to eq('CLASS_')
    end

    it 'handles symbols' do
      result = generator.send(:sanitize_js_identifier, :update_user)
      expect(result).to eq('update_user')
    end

    it 'replaces special characters' do
      result = generator.send(:sanitize_js_identifier, 'hello@world.com')
      expect(result).to eq('hello_world_com')
    end
  end

  describe '#valid_js_identifier?' do
    it 'returns true for valid identifiers' do
      expect(generator.send(:valid_js_identifier?, 'validName')).to be true
    end

    it 'returns true for identifiers starting with underscore' do
      expect(generator.send(:valid_js_identifier?, '_private')).to be true
    end

    it 'returns true for identifiers starting with dollar sign' do
      expect(generator.send(:valid_js_identifier?, '$element')).to be true
    end

    it 'returns false for identifiers starting with numbers' do
      expect(generator.send(:valid_js_identifier?, '123abc')).to be false
    end

    it 'returns false for identifiers with hyphens' do
      expect(generator.send(:valid_js_identifier?, 'my-var')).to be false
    end

    it 'returns false for reserved words' do
      expect(generator.send(:valid_js_identifier?, 'class')).to be false
      expect(generator.send(:valid_js_identifier?, 'function')).to be false
      expect(generator.send(:valid_js_identifier?, 'return')).to be false
    end

    it 'returns false for empty strings' do
      expect(generator.send(:valid_js_identifier?, '')).to be false
    end

    it 'returns false for nil' do
      expect(generator.send(:valid_js_identifier?, nil)).to be false
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
