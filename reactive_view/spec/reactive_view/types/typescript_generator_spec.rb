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

  describe '#build_use_form_hook' do
    let(:update_params_schema) do
      ReactiveView::Types::Hash.schema(
        name: ReactiveView::Types::String,
        email: ReactiveView::Types::String
      )
    end

    let(:update_mutation_data) do
      { update: { params_schema: update_params_schema, response_schema: nil, response_mode: :single } }
    end

    let(:delete_mutation_data) do
      { delete: { params_schema: ReactiveView::Types::Hash, response_schema: nil, response_mode: :single } }
    end

    let(:multi_mutation_data) do
      {
        update: { params_schema: update_params_schema, response_schema: nil, response_mode: :single },
        delete: { params_schema: ReactiveView::Types::Hash, response_schema: nil, response_mode: :single }
      }
    end

    it 'generates a MutationName union type from mutation names' do
      result = generator.send(:build_use_form_hook, update_mutation_data, false)
      expect(result).to include('type MutationName = "update";')
    end

    it 'generates a union of multiple mutation names' do
      result = generator.send(:build_use_form_hook, multi_mutation_data, false)
      expect(result).to include('type MutationName = "update" | "delete";')
    end

    it 'generates a _mutations map with action and Form entries' do
      result = generator.send(:build_use_form_hook, multi_mutation_data, false)
      expect(result).to include('update: { action: updateAction, Form: UpdateForm }')
      expect(result).to include('delete: { action: deleteAction, Form: DeleteForm }')
    end

    it 'generates useForm overload for stream handles when streams exist' do
      result = generator.send(:build_use_form_hook, multi_mutation_data, true)
      expect(result).to include('export function useForm<T extends MutationName>(name: T): readonly [')
      expect(result).to include('export function useForm<T extends StreamMutationName>(stream: StreamHandle<T>): StreamFormComponent;')
      expect(result).not_to include('FormSubmission')
      expect(result).not_to include('as any')
    end

    it 'generates stream-aware implementation when streams exist' do
      result = generator.send(:build_use_form_hook, update_mutation_data, true)
      expect(result).to include('if (typeof nameOrStream === "string") {')
      expect(result).to include('const mutation = _mutations[nameOrStream];')
      expect(result).to include('return [mutation.Form, useSubmission(mutation.action)] as const;')
      expect(result).to include('return nameOrStream.Form;')
    end

    it 'generates mutation-only implementation when no streams exist' do
      result = generator.send(:build_use_form_hook, update_mutation_data, false)
      expect(result).not_to include('StreamMutationName')
      expect(result).not_to include('nameOrStream.Form')
      expect(result).to include('const mutation = _mutations[nameOrStream];')
    end

    it 'generates JSDoc with example using the first mutation' do
      result = generator.send(:build_use_form_hook, update_mutation_data, false)
      expect(result).to include('const [UpdateForm, submission] = useForm("update");')
    end

    it 'works with a single mutation' do
      result = generator.send(:build_use_form_hook, delete_mutation_data, false)
      expect(result).to include('type MutationName = "delete";')
      expect(result).to include('delete: { action: deleteAction, Form: DeleteForm }')
      expect(result).to include('export function useForm<T extends MutationName>(name: T): readonly [')
    end
  end

  describe '#build_mutation' do
    let(:params_schema) do
      ReactiveView::Types::Hash.schema(
        name: ReactiveView::Types::String,
        email: ReactiveView::Types::String
      )
    end

    it 'generates params interface from params_schema' do
      data = { params_schema: params_schema, response_schema: nil }
      result = generator.send(:build_mutation, 'users/[id]', :update, data)

      expect(result).to include('export interface UpdateParams')
      expect(result).to include('name: string')
      expect(result).to include('email: string')
    end

    it 'generates action constant' do
      data = { params_schema: params_schema, response_schema: nil }
      result = generator.send(:build_mutation, 'users/[id]', :update, data)

      expect(result).to include('export const updateAction = createMutation<UpdateParams>("users/[id]", "update")')
    end

    it 'generates Form component' do
      data = { params_schema: params_schema, response_schema: nil }
      result = generator.send(:build_mutation, 'users/[id]', :update, data)

      expect(result).to include('export function UpdateForm(')
      expect(result).to include('action={updateAction}')
    end

    it 'generates response interface when response_schema differs from params_schema' do
      response_schema = ReactiveView::Types::Hash.schema(
        id: ReactiveView::Types::Integer,
        name: ReactiveView::Types::String
      )
      data = { params_schema: params_schema, response_schema: response_schema }
      result = generator.send(:build_mutation, 'users/[id]', :update, data)

      expect(result).to include('export interface UpdateParams')
      expect(result).to include('export interface UpdateResponse')
      expect(result).to include('id: number')
    end

    it 'does not generate response interface when response_schema is nil' do
      data = { params_schema: params_schema, response_schema: nil }
      result = generator.send(:build_mutation, 'users/[id]', :update, data)

      expect(result).not_to include('UpdateResponse')
    end

    it 'generates Record<string, unknown> for empty params schema' do
      data = { params_schema: ReactiveView::Types::Hash, response_schema: nil }
      result = generator.send(:build_mutation, 'users/[id]', :delete, data)

      expect(result).to include('export type DeleteParams = Record<string, unknown>')
    end
  end

  describe '#build_streaming_section' do
    let(:update_schema) do
      ReactiveView::Types::Hash.schema(
        name: ReactiveView::Types::String,
        email: ReactiveView::Types::String
      )
    end

    let(:delete_schema) { ReactiveView::Types::Hash }

    let(:generate_schema) do
      ReactiveView::Types::Hash.schema(
        prompt: ReactiveView::Types::String
      )
    end

    let(:generate_response_schema) do
      ReactiveView::Types::Hash.schema(
        word: ReactiveView::Types::String
      )
    end

    def mutation_data_for(*names)
      names.each_with_object({}) do |name, memo|
        params_schema = name == :generate ? generate_schema : ReactiveView::Types::Hash
        response_schema = name == :generate ? generate_response_schema : params_schema
        memo[name] = {
          params_schema: params_schema,
          response_schema: response_schema,
          response_mode: :stream
        }
      end
    end

    def build_streaming(path, mutation_data)
      loader = {
        path: path,
        mutation_data: mutation_data
      }
      generator.send(:build_streaming_section, loader)
    end

    it 'generates a StreamMutationName union type from mutation names' do
      result = build_streaming('users/index', mutation_data_for(:update))
      expect(result).to include('type StreamMutationName = "update";')
    end

    it 'generates a union of multiple mutation names' do
      result = build_streaming('users/index', mutation_data_for(:update, :delete))
      expect(result).to include('type StreamMutationName = "update" | "delete";')
    end

    it 'includes the Streaming section header comment' do
      result = build_streaming('users/index', mutation_data_for(:update))
      expect(result).to include('// Streaming (SSE)')
    end

    it 'generates a useStream function with generic constraint' do
      result = build_streaming('users/index', mutation_data_for(:update))
      expect(result).to include('export function useStream<T extends StreamMutationName>(name: T)')
    end

    it 'generates a typed stream params map' do
      result = build_streaming('users/index', mutation_data_for(:update))
      expect(result).to include('type StreamParamsMap = {')
      expect(result).to include('"update": UpdateParams;')
    end

    it 'generates a typed stream response map' do
      result = build_streaming('ai/chat', mutation_data_for(:generate))
      expect(result).to include('type StreamResponseMap = {')
      expect(result).to include('"generate": GenerateResponse;')
    end

    it 'generates a useStream function that returns a StreamHandle' do
      result = build_streaming('users/index', mutation_data_for(:update))
      expect(result).to include('): StreamHandle<T> {')
      expect(result).to include('StreamState<StreamParamsMap[T]>')
    end

    it 'calls createStream with the correct loader path' do
      result = build_streaming('ai/chat', mutation_data_for(:generate))
      expect(result).to include('createStream<StreamParamsMap[T]>("ai/chat", name)')
    end

    it 'generates a StreamForm component and attaches it to the stream handle' do
      result = build_streaming('users/index', mutation_data_for(:update))
      expect(result).to include('function StreamForm(')
      expect(result).to include('messages: streamData.messages')
    end

    it 'generates StreamForm with onSubmit handler that calls stream.start with typed params' do
      result = build_streaming('users/index', mutation_data_for(:update))
      expect(result).to include('stream.start(params as StreamParamsMap[T])')
      expect(result).to include('e.preventDefault()')
      expect(result).to include('new FormData(e.target as HTMLFormElement)')
    end

    it 'calls user onSubmit before stream.start so UI prep runs first' do
      result = build_streaming('users/index', mutation_data_for(:update))
      on_submit_pos = result.index('props.onSubmit')
      start_pos = result.index('stream.start(params as StreamParamsMap[T])')
      expect(on_submit_pos).to be < start_pos
    end

    it 'generates JSDoc with example using the first mutation' do
      result = build_streaming('ai/chat', mutation_data_for(:generate))
      expect(result).to include('const stream = useStream("generate")')
      expect(result).to include('const StreamForm = useForm(stream);')
    end

    it 'generates JSDoc with programmatic example' do
      result = build_streaming('ai/chat', mutation_data_for(:generate))
      expect(result).to include('const stream = useStream("generate")')
      expect(result).to include('stream.start({ prompt: "Hello" })')
      expect(result).to include('stream.messages()')
    end

    it 'works with a single mutation' do
      result = build_streaming('ai/chat', mutation_data_for(:generate))
      expect(result).to include('type StreamMutationName = "generate";')
      expect(result).to include('export function useStream<T extends StreamMutationName>(name: T)')
      expect(result).to include('createStream<StreamParamsMap[T]>("ai/chat", name)')
    end

    it 'works with multiple mutations' do
      result = build_streaming('ai/chat', mutation_data_for(:generate, :update, :delete))
      expect(result).to include('type StreamMutationName = "generate" | "update" | "delete";')
    end
  end

  describe '#build_imports' do
    it 'includes createStream, useStreamData, and StreamState imports when stream mutations exist' do
      result = generator.send(:build_imports, true, true)
      expect(result).to include('createStream')
      expect(result).to include('useStreamData')
      expect(result).to include('StreamState')
    end

    it 'does not include stream imports when no stream mutations exist' do
      result = generator.send(:build_imports, true, false)
      expect(result).not_to include('createStream')
      expect(result).not_to include('StreamState')
    end

    it 'includes createMutation when mutations exist' do
      result = generator.send(:build_imports, true, false)
      expect(result).to include('createMutation')
    end
  end

  describe '#build_loader_file' do
    let(:generate_schema) do
      ReactiveView::Types::Hash.schema(
        prompt: ReactiveView::Types::String
      )
    end

    let(:load_schema) do
      ReactiveView::Types::Hash.schema(
        greeting: ReactiveView::Types::String
      )
    end

    def build_file(path:, load_schema: nil, mutation_data: {})
      loader = {
        path: path,
        class_name: 'TestLoader',
        interface_name: 'TestLoaderData',
        load_schema: load_schema,
        mutation_data: mutation_data
      }
      generator.send(:build_loader_file, loader)
    end

    it 'includes streaming section when mutations exist' do
      result = build_file(
        path: 'ai/chat',
        mutation_data: {
          generate: { params_schema: generate_schema, response_schema: generate_schema, response_mode: :stream }
        }
      )
      expect(result).to include('// Streaming (SSE)')
      expect(result).to include('useStream')
    end

    it 'does not include streaming section when no mutations exist' do
      result = build_file(path: 'users/index', load_schema: load_schema)
      expect(result).not_to include('// Streaming (SSE)')
      expect(result).not_to include('useStream')
    end

    it 'includes both mutations and streaming sections together' do
      result = build_file(
        path: 'ai/chat',
        load_schema: load_schema,
        mutation_data: {
          generate: { params_schema: generate_schema, response_schema: generate_schema, response_mode: :stream }
        }
      )
      expect(result).to include('// Mutations')
      expect(result).to include('// Streaming (SSE)')
      expect(result).to include('// Loader Data')
    end

    it 'includes createStream import when stream mutations exist' do
      result = build_file(
        path: 'ai/chat',
        mutation_data: {
          generate: { params_schema: generate_schema, response_schema: generate_schema, response_mode: :stream }
        }
      )
      expect(result).to include('createStream')
    end

    it 'does not include streaming section for non-stream mutations' do
      result = build_file(
        path: 'users/index',
        mutation_data: {
          update: { params_schema: generate_schema, response_schema: nil, response_mode: :single }
        }
      )
      expect(result).not_to include('// Streaming (SSE)')
      expect(result).not_to include('useStream(')
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
