# frozen_string_literal: true

module ReactiveView
  module Types
    # Generates TypeScript type definitions from loader shape definitions.
    #
    # This generator creates two types of output:
    #
    # 1. Per-route loader files in `.reactive_view/types/loaders/`
    #    These provide auto-typed `useLoaderData()` hooks for each route,
    #    plus mutation actions and Form components when mutations are defined.
    #
    # 2. Central route map in `.reactive_view/types/loader-data.d.ts`
    #    This enables cross-route loading with `useLoaderData("route/path", params)`.
    #
    # The generator reads from the new shape system:
    # - `_shapes` for named shape definitions
    # - `_params_shapes` for mutation input types
    # - `_response_shapes` for loader output types
    #
    # @example Per-route loader file with mutations
    #   // .reactive_view/types/loaders/users/[id].ts
    #   import { createMutation, useAction, useSubmission } from "@reactive-view/core";
    #
    #   export interface LoaderData {
    #     user: { id: number; name: string };
    #   }
    #
    #   export interface UpdateParams {
    #     name: string;
    #     email: string;
    #   }
    #
    #   export const updateAction = createMutation("users/[id]", "update");
    #
    #   export function UpdateForm(props) {
    #     return <form action={updateAction} method="post" {...props} />;
    #   }
    #
    class TypescriptGenerator
      # JavaScript reserved words that cannot be used as identifiers
      JS_RESERVED_WORDS = %w[
        break case catch continue debugger default delete do else finally
        for function if in instanceof new return switch this throw try
        typeof var void while with class const enum export extends import
        super implements interface let package private protected public
        static yield null true false undefined NaN Infinity
      ].freeze

      # Pattern for valid JavaScript identifiers (must start with letter, $, or _)
      JS_IDENTIFIER_PATTERN = /\A[a-zA-Z_$][a-zA-Z0-9_$]*\z/
      ROUTE_MAP_FILE = 'types/loader-data.d.ts'
      LOADERS_DIR = 'types/loaders'

      class << self
        # Generate TypeScript types for all loaders
        #
        # @return [Hash] Summary of generated files
        def generate
          new.generate
        end
      end

      def initialize
        @working_dir = ReactiveView.configuration.working_directory_absolute_path
        @route_map_path = @working_dir.join(ROUTE_MAP_FILE)
        @loaders_dir = @working_dir.join(LOADERS_DIR)
      end

      # Generate and write all TypeScript definitions
      #
      # @return [Hash] Summary of generated files
      def generate
        loaders = collect_loaders

        # Generate per-route loader files
        generated_files = generate_loader_files(loaders)

        # Generate central route map
        generate_route_map(loaders)

        ReactiveView.logger.info "[ReactiveView] Generated #{generated_files.count} loader type files"
        ReactiveView.logger.info "[ReactiveView] Generated route map at #{@route_map_path}"

        {
          loader_files: generated_files,
          route_map: @route_map_path.to_s
        }
      end

      private

      # Collect loader metadata from all registered loaders.
      # Uses the new shape system: _shapes, _params_shapes, _response_shapes.
      def collect_loaders
        LoaderRegistry.all_loader_paths.filter_map do |path|
          loader_class = LoaderRegistry.class_for_path(path)

          # Response shape for :load action (used for LoaderData interface)
          load_response_schema = resolve_schema_for_response(loader_class, :load)

          # Collect mutation schemas (params shapes for non-:load actions)
          mutation_data = collect_mutation_data(loader_class)

          # Skip if no load shape and no mutations
          next unless load_response_schema || mutation_data.any?

          {
            path: path,
            class_name: LoaderRegistry.path_to_class_name(path),
            interface_name: path_to_interface_name(path),
            load_schema: load_response_schema,
            mutation_data: mutation_data
          }
        end
      end

      # Resolve the Dry::Types schema for a response shape on a loader.
      #
      # @param loader_class [Class] The loader class
      # @param action [Symbol] The action name
      # @return [Dry::Types::Type, nil] The Dry schema, or nil
      def resolve_schema_for_response(loader_class, action)
        ref = loader_class._response_shapes[action]
        return nil unless ref

        shape_class = loader_class.resolve_shape(ref)
        return nil unless shape_class

        shape_class.dry_schema
      end

      # Resolve the Dry::Types schema for a params shape on a loader.
      #
      # @param loader_class [Class] The loader class
      # @param action [Symbol] The action name
      # @return [Dry::Types::Type, nil] The Dry schema, or nil
      def resolve_schema_for_params(loader_class, action)
        ref = loader_class._params_shapes[action]
        return nil unless ref

        shape_class = loader_class.resolve_shape(ref)
        return nil unless shape_class

        shape_class.dry_schema
      end

      # Collect mutation data for a loader: both params and response schemas.
      #
      # Mutations are discovered from:
      # - _params_shapes entries (excluding :load)
      # - _response_shapes entries (excluding :load)
      # - _shapes entries that are not :load (fallback for shapes without explicit assignment)
      #
      # @param loader_class [Class] The loader class
      # @return [Hash<Symbol, Hash>] Mutation name => { params_schema:, response_schema: }
      def collect_mutation_data(loader_class)
        # Collect all mutation names from params_shapes and response_shapes
        mutation_names = Set.new
        mutation_names.merge(loader_class._params_shapes.keys - [:load])
        mutation_names.merge(loader_class._response_shapes.keys - [:load])

        # Also include shapes that aren't :load and don't have explicit params/response assignment
        # This handles the case where a shape is defined but only used via shapes accessor
        loader_class._shapes.each_key do |name|
          next if name == :load

          mutation_names.add(name) if loader_class._params_shapes.key?(name) ||
                                      !loader_class._response_shapes.key?(name)
        end

        mutation_names.each_with_object({}) do |name, result|
          params_schema = resolve_schema_for_params(loader_class, name)
          response_schema = resolve_schema_for_response(loader_class, name)

          # Fall back to the shape definition if no explicit params/response assignment
          if params_schema.nil? && response_schema.nil?
            shape_class = loader_class._shapes[name]
            if shape_class
              # Use the shape as params schema by default (backward compat for mutations)
              params_schema = shape_class.dry_schema
            end
          end

          next unless params_schema || response_schema

          result[name] = {
            params_schema: params_schema,
            response_schema: response_schema
          }
        end
      end

      # Generate individual loader files for each route
      #
      # @param loaders [Array<Hash>] List of loader metadata
      # @return [Array<String>] List of generated file paths
      def generate_loader_files(loaders)
        # Clean up old loader files first
        FileUtils.rm_rf(@loaders_dir) if @loaders_dir.exist?

        loaders.filter_map do |loader|
          file_path = @loaders_dir.join("#{loader[:path]}.ts")
          content = build_loader_file(loader)

          begin
            FileSync::AtomicWriter.write(file_path, content)
            file_path.to_s
          rescue SystemCallError => e
            ReactiveView.logger.error "[ReactiveView] Failed to write loader file #{file_path}: #{e.message}"
            nil
          end
        end
      end

      # Build content for a per-route loader file
      #
      # @param loader [Hash] Loader metadata
      # @return [String] TypeScript file content
      def build_loader_file(loader)
        # Extract param names from path like "users/[id]" -> ["id"]
        param_names = loader[:path].scan(/\[(\w+)\]/).flatten
        param_names_comment = param_names.empty? ? '' : " (#{param_names.join(', ')})"

        has_mutations = loader[:mutation_data]&.any?

        parts = []

        # Header comment
        parts << <<~TYPESCRIPT
          // Auto-generated by ReactiveView - DO NOT EDIT
          // Source: app/pages/#{loader[:path]}.loader.rb
          // Run `rails reactive_view:types:generate` to regenerate
        TYPESCRIPT

        # Imports
        parts << build_imports(has_mutations)

        # Loader data interface and hooks (if load shape exists)
        parts << build_loader_section(loader, param_names_comment) if loader[:load_schema]

        # Mutation interfaces, actions, and forms
        parts << build_mutations_section(loader) if has_mutations

        # Streaming hooks for mutations
        parts << build_streaming_section(loader) if has_mutations

        parts.join("\n")
      end

      # Build import statements
      def build_imports(has_mutations)
        imports = []

        imports << 'import { createLoaderQuery, createAsync, useParams, type AccessorWithLatest } from "@reactive-view/core";'

        if has_mutations
          imports << 'import type { JSX } from "@reactive-view/core";'
          imports << 'import { createMutation, useAction, useSubmission, useSubmissions } from "@reactive-view/core";'
          imports << 'import type { MutationResult } from "@reactive-view/core";'
          imports << 'import { createStream, type StreamState } from "@reactive-view/core";'
        end

        imports.join("\n") + "\n"
      end

      # Build the loader data section (interface + hooks)
      def build_loader_section(loader, param_names_comment)
        interface_def = generate_nested_interfaces(loader[:load_schema], 'LoaderData')

        <<~TYPESCRIPT

          // ============================================================================
          // Loader Data
          // ============================================================================

          #{interface_def}

          /**
           * Cached query for the #{loader[:path]} route.
           * Call this to preload or fetch data with automatic caching.
           */
          export const getLoaderData = createLoaderQuery<LoaderData>("#{loader[:path]}");

          /**
           * Preload data for the #{loader[:path]} route.
           * Call this in the route's preload function to fetch data before navigation.
           * @param params - Route parameters#{param_names_comment}
           */
          export function preloadData(params: Record<string, string> = {}): void {
            getLoaderData(params);
          }

          /**
           * Load data for the #{loader[:path]} route.
           * Uses cached data from preload when available, avoiding loading flash.
           *
           * @param options - Options passed through to SolidJS `createAsync`
           * @param options.initialValue - Initial value before data loads. When provided, the return type excludes `undefined`.
           * @param options.deferStream - When `true`, defers SSR streaming until data resolves.
           * @param options.name - Name for debugging tools.
           * @returns Accessor containing the loader data
           *
           * @example Basic usage (data may be undefined until loaded)
           * ```tsx
           * const data = useLoaderData();
           * // data() is LoaderData | undefined
           * ```
           *
           * @example With initialValue (data is never undefined)
           * ```tsx
           * const data = useLoaderData({ initialValue: { #{loader[:load_schema]&.respond_to?(:keys) ? loader[:load_schema].keys.first&.name.to_s + ': ...' : '...'} } });
           * // data() is LoaderData
           * ```
           *
           * @example With deferStream (waits for data during SSR streaming)
           * ```tsx
           * const data = useLoaderData({ deferStream: true });
           * ```
           */
          export function useLoaderData(options: { initialValue: LoaderData; name?: string; deferStream?: boolean }): AccessorWithLatest<LoaderData>;
          export function useLoaderData(options?: { name?: string; initialValue?: undefined; deferStream?: boolean }): AccessorWithLatest<LoaderData | undefined>;
          export function useLoaderData(options?: { name?: string; initialValue?: LoaderData; deferStream?: boolean }): AccessorWithLatest<LoaderData | undefined> {
            const params = useParams<Record<string, string>>();
            return createAsync(() => getLoaderData({ ...params }), options as any);
          }
        TYPESCRIPT
      end

      # Build the mutations section (interfaces, actions, forms)
      def build_mutations_section(loader)
        parts = []

        parts << <<~TYPESCRIPT

          // ============================================================================
          // Mutations
          // ============================================================================
        TYPESCRIPT

        loader[:mutation_data].each do |mutation_name, data|
          parts << build_mutation(loader[:path], mutation_name, data)
        end

        # useForm hook that returns [Form, submission] tuple
        parts << build_use_form_hook(loader[:mutation_data])

        # Re-export action utilities for convenience
        parts << <<~TYPESCRIPT

          // Re-export action utilities for convenience
          export { useAction, useSubmission, useSubmissions };
        TYPESCRIPT

        parts.join("\n")
      end

      # Build a single mutation (interface, action, form)
      def build_mutation(loader_path, mutation_name, data)
        # Use the original mutation name for compound identifiers (e.g., deleteAction, DeleteForm)
        # These are safe because they're combined with suffixes that make them valid identifiers
        base_name = mutation_name.to_s
        capitalized_name = base_name.camelize
        action_name = "#{base_name}Action"
        form_name = "#{capitalized_name}Form"

        # Validate the resulting identifiers are valid JS (they should be, given the suffixes)
        unless valid_js_identifier?(action_name)
          action_name = sanitize_js_identifier(action_name)
          ReactiveView.logger.warn "[ReactiveView] Action name sanitized to '#{action_name}'"
        end

        unless valid_js_identifier?(form_name)
          form_name = sanitize_js_identifier(form_name)
          ReactiveView.logger.warn "[ReactiveView] Form name sanitized to '#{form_name}'"
        end

        params_schema = data[:params_schema]
        response_schema = data[:response_schema]

        # Generate params interface
        params_interface = if params_schema&.respond_to?(:keys) && params_schema.keys.any?
                             generate_nested_interfaces(params_schema, "#{capitalized_name}Params")
                           else
                             "export type #{capitalized_name}Params = Record<string, unknown>;"
                           end

        # Generate response interface if different from params
        response_interface = if response_schema && response_schema != params_schema
                               if response_schema.respond_to?(:keys) && response_schema.keys.any?
                                 generate_nested_interfaces(response_schema, "#{capitalized_name}Response")
                               else
                                 "export type #{capitalized_name}Response = Record<string, unknown>;"
                               end
                             end

        result = <<~TYPESCRIPT

          // --- #{mutation_name} mutation ---

          #{params_interface}
        TYPESCRIPT

        if response_interface
          result += <<~TYPESCRIPT

            #{response_interface}
          TYPESCRIPT
        end

        result += <<~TYPESCRIPT

          /**
           * Action for the #{mutation_name} mutation.
           * Use with forms or useAction() for programmatic calls.
           */
          export const #{action_name} = createMutation<#{capitalized_name}Params>("#{loader_path}", "#{mutation_name}");

          /**
           * Form component pre-configured for the #{mutation_name} mutation.
           * Automatically includes CSRF token and submits to the correct endpoint.
           *
           * @example
           * <#{form_name}>
           *   <input name="fieldName" />
           *   <button type="submit">Submit</button>
           * </#{form_name}>
           */
          export function #{form_name}(
            props: Omit<JSX.FormHTMLAttributes<HTMLFormElement>, "action" | "method">
          ) {
            return <form action={#{action_name}} method="post" {...props} />;
          }
        TYPESCRIPT

        result
      end

      # Build the useForm hook that returns [Form, submission] for a given mutation name.
      #
      # Generates a type-safe hook where the mutation name argument is a generic
      # constrained to the union of available mutations. The return type is fully
      # inferred from the action/Form types -- no casts, no manual type annotations --
      # so that `submission.result?.success` etc. are end-to-end type safe.
      #
      # @param mutation_data [Hash] Map of mutation_name => { params_schema:, response_schema: }
      # @return [String] TypeScript code for the useForm hook
      def build_use_form_hook(mutation_data)
        entries = mutation_data.map do |mutation_name, _data|
          base_name = mutation_name.to_s
          capitalized_name = base_name.camelize
          action_name = "#{base_name}Action"
          form_name = "#{capitalized_name}Form"

          # Apply same sanitization as build_mutation
          action_name = sanitize_js_identifier(action_name) unless valid_js_identifier?(action_name)
          form_name = sanitize_js_identifier(form_name) unless valid_js_identifier?(form_name)

          { name: base_name, action_name: action_name, form_name: form_name }
        end

        # Build the MutationName union type
        mutation_names_union = entries.map { |e| "\"#{e[:name]}\"" }.join(' | ')

        # Build the _mutations map entries
        map_entries = entries.map do |e|
          "  #{e[:name]}: { action: #{e[:action_name]}, Form: #{e[:form_name]} }"
        end.join(",\n")

        <<~TYPESCRIPT

          // ============================================================================
          // useForm Hook
          // ============================================================================

          /** Available mutation names for this route */
          type MutationName = #{mutation_names_union};

          /** @internal Mapping of mutation names to their actions and Form components */
          const _mutations = {
          #{map_entries},
          } as const;

          /**
           * Returns a `[Form, submission]` tuple for the given mutation.
           *
           * The Form component is pre-configured to submit to the correct endpoint.
           * The submission object tracks pending state, results, and errors
           * with full type safety (`submission.result?.success`, `submission.result?.errors`, etc.).
           *
           * @param name - The mutation name (#{entries.map { |e| "\"#{e[:name]}\"" }.join(', ')})
           * @returns A readonly tuple of `[FormComponent, Submission]`
           *
           * @example
           * const [#{entries.first[:form_name]}, submission] = useForm("#{entries.first[:name]}");
           *
           * <#{entries.first[:form_name]}>
           *   <input name="fieldName" />
           *   <button type="submit" disabled={submission.pending}>
           *     Submit
           *   </button>
           * </#{entries.first[:form_name]}>
           */
          export function useForm<T extends MutationName>(name: T) {
            const mutation = _mutations[name];
            return [mutation.Form, useSubmission(mutation.action)] as const;
          }
        TYPESCRIPT
      end

      # Build the streaming section (useStream hook for mutations)
      #
      # Generates a `useStream()` hook that returns a `[StreamForm, stream]` tuple,
      # similar to `useForm`. The StreamForm handles form submission and starts the
      # SSE stream. The stream object provides reactive state for tracking data,
      # streaming status, errors, and chunks.
      #
      # @param loader [Hash] Loader metadata including path and mutation_schemas
      # @return [String] TypeScript code for the streaming section
      def build_streaming_section(loader)
        entries = loader[:mutation_schemas].map do |mutation_name, _schema|
          base_name = mutation_name.to_s
          {name: base_name}
        end

        mutation_names_union = entries.map { |e| "\"#{e[:name]}\"" }.join(' | ')

        <<~TYPESCRIPT

          // ============================================================================
          // Streaming (SSE)
          // ============================================================================

          /** Available stream mutation names for this route */
          type StreamMutationName = #{mutation_names_union};

          /**
           * Hook for SSE streaming from a mutation endpoint.
           * Returns a `[StreamForm, stream]` tuple similar to `useForm`.
           *
           * The `StreamForm` component handles form submission and starts the stream.
           * The `stream` object provides reactive state and a programmatic `start()` method.
           *
           * @param name - The mutation name (#{entries.map { |e| "\"#{e[:name]}\"" }.join(', ')})
           * @returns A readonly tuple of `[StreamFormComponent, StreamState]`
           *
           * @example
           * const [StreamForm, stream] = useStream("#{entries.first[:name]}");
           *
           * <StreamForm>
           *   <input name="prompt" />
           *   <button type="submit" disabled={stream.streaming()}>Send</button>
           * </StreamForm>
           *
           * <Show when={stream.data()}>
           *   <p>{stream.data()}</p>
           * </Show>
           *
           * @example Programmatic usage
           * const [, stream] = useStream("#{entries.first[:name]}");
           * stream.start({ prompt: "Hello" });
           */
          export function useStream<T extends StreamMutationName>(name: T): readonly [
            (props: Omit<JSX.FormHTMLAttributes<HTMLFormElement>, "action" | "method">) => JSX.Element,
            StreamState
          ] {
            const stream = createStream("#{loader[:path]}", name);

            function StreamForm(
              props: Omit<JSX.FormHTMLAttributes<HTMLFormElement>, "action" | "method">
            ) {
              return (
                <form
                  {...props}
                  onSubmit={(e: SubmitEvent) => {
                    e.preventDefault();
                    const formData = new FormData(e.target as HTMLFormElement);
                    const params: Record<string, unknown> = {};
                    formData.forEach((value, key) => { params[key] = value; });
                    // Call user's onSubmit BEFORE starting the stream so UI prep
                    // (e.g. adding placeholder messages) runs while streaming() is still false.
                    if (typeof props.onSubmit === "function") {
                      (props.onSubmit as (e: SubmitEvent) => void)(e);
                    }
                    stream.start(params);
                  }}
                />
              );
            }

            return [StreamForm, stream] as const;
          }
        TYPESCRIPT
      end

      # Generate nested interfaces for complex types
      #
      # @param schema [Dry::Types::Type] The schema to generate interfaces for
      # @param interface_name [String] Name of the main interface
      # @return [String] TypeScript interface definitions
      def generate_nested_interfaces(schema, interface_name)
        fields = schema_to_typescript_fields(schema)

        <<~TYPESCRIPT.strip
          export interface #{interface_name} {
          #{fields.map { |f| "  #{f};" }.join("\n")}
          }
        TYPESCRIPT
      end

      # Generate the central route map file
      #
      # @param loaders [Array<Hash>] List of loader metadata
      def generate_route_map(loaders)
        content = build_route_map(loaders)

        begin
          FileSync::AtomicWriter.write(@route_map_path, content)
        rescue SystemCallError => e
          ReactiveView.logger.error "[ReactiveView] Failed to write route map #{@route_map_path}: #{e.message}"
        end
      end

      # Build the central route map TypeScript content
      #
      # @param loaders [Array<Hash>] List of loader metadata
      # @return [String] TypeScript content
      def build_route_map(loaders)
        # Filter to only loaders with load schemas for the map
        loaders_with_load = loaders.select { |l| l[:load_schema] }

        <<~TYPESCRIPT
          // Auto-generated by ReactiveView - DO NOT EDIT
          // Run `rails reactive_view:types:generate` to regenerate

          import "@reactive-view/core";

          #{generate_interfaces(loaders_with_load)}

          declare module "@reactive-view/core" {
            interface LoaderDataMap {
          #{generate_loader_map_entries(loaders_with_load)}
            }
          }
        TYPESCRIPT
      end

      def path_to_interface_name(path)
        segments = path.split('/').map do |segment|
          cleaned = segment
                    .gsub(/\(([^)]+)\)/, '\1')       # Strip route group parentheses: (admin) -> admin
                    .gsub(/\[\.\.\.(.*?)\]/, '\1')   # Catch-all routes: [...slug] -> slug
                    .gsub(/\[\[(.*?)\]\]/, '\1')     # Optional catch-all: [[...slug]] -> slug
                    .gsub(/\[(.*?)\]/, '\1')         # Dynamic params: [id] -> id

          # Sanitize and camelize each segment
          sanitize_js_identifier(cleaned).camelize
        end

        "#{segments.join}LoaderData"
      end

      def generate_interfaces(loaders)
        return '' if loaders.empty?

        loaders.map do |loader|
          fields = schema_to_typescript_fields(loader[:load_schema])

          <<~TYPESCRIPT.strip
            interface #{loader[:interface_name]} {
            #{fields.map { |f| "  #{f};" }.join("\n")}
            }
          TYPESCRIPT
        end.join("\n\n")
      end

      def generate_loader_map_entries(loaders)
        return '    // No loaders with signatures found' if loaders.empty?

        loaders.map do |loader|
          "    \"#{loader[:path]}\": #{loader[:interface_name]};"
        end.join("\n")
      end

      def schema_to_typescript_fields(schema)
        return [] unless schema.respond_to?(:keys)

        schema.keys.map do |key|
          optional = key.type.optional? ? '?' : ''
          ts_type = dry_type_to_typescript(key.type)
          # Use quoted property name if it contains special characters
          prop_name = if valid_js_identifier?(key.name.to_s)
                        key.name.to_s
                      else
                        "\"#{key.name}\""
                      end

          "#{prop_name}#{optional}: #{ts_type}"
        end
      rescue StandardError => e
        ReactiveView.logger.warn "[ReactiveView] Error converting schema to TypeScript: #{e.message}"
        []
      end

      def dry_type_to_typescript(type)
        # Handle optional types
        if type.optional?
          inner = type.respond_to?(:right) ? type.right : type
          return "#{dry_type_to_typescript(inner)} | null"
        end

        # Check for boolean type by name (TrueClass | FalseClass)
        return 'boolean' if type.respond_to?(:name) && type.name == 'TrueClass | FalseClass'

        # Get the primitive type name
        type_name = extract_type_name(type)

        case type_name
        when /String/i
          'string'
        when /Integer/i, /Float/i, /Decimal/i
          'number'
        when /Bool/i, /TrueClass/i, /FalseClass/i
          'boolean'
        when /Array/i
          member_type = extract_array_member_type(type)
          "#{dry_type_to_typescript(member_type)}[]"
        when /Hash/i
          if type.respond_to?(:keys) && type.keys.any?
            fields = schema_to_typescript_fields(type)
            "{ #{fields.join('; ')} }"
          else
            'Record<string, unknown>'
          end
        when /Date/i, /Time/i, /DateTime/i
          'string' # Dates serialize to ISO strings in JSON
        when /Any/i
          'unknown'
        when /Nil/i
          'null'
        else
          'unknown'
        end
      end

      def extract_type_name(type)
        # Try to get the primitive type first (handles Constrained, Nominal, etc.)
        return type.primitive.name.to_s.split('::').last if type.respond_to?(:primitive)

        # Fallback to class name
        type.class.name.to_s.split('::').last
      rescue StandardError
        'Any'
      end

      def extract_array_member_type(type)
        # Navigate through Constrained -> Array -> member
        inner = type

        # Unwrap Constrained types to get to the Array
        inner = inner.type while inner.respond_to?(:type) && !inner.respond_to?(:member)

        # Now try to get the member
        return inner.member if inner.respond_to?(:member)

        Types::Any
      rescue StandardError
        Types::Any
      end

      # Sanitize a string to be a valid JavaScript identifier.
      # Removes invalid characters, ensures it starts with a valid char,
      # and handles reserved words.
      #
      # @param name [String, Symbol] The name to sanitize
      # @param prefix [String] Prefix to add if name starts with invalid char
      # @return [String] A valid JavaScript identifier
      def sanitize_js_identifier(name, prefix: '_')
        str = name.to_s

        # Replace invalid characters with underscores
        sanitized = str.gsub(/[^a-zA-Z0-9_$]/, '_')

        # Ensure it starts with a valid character (letter, $, or _)
        sanitized = "#{prefix}#{sanitized}" if sanitized.match?(/\A[0-9]/)

        # Handle empty string
        sanitized = '_unnamed' if sanitized.empty?

        # Handle reserved words by adding underscore suffix
        sanitized = "#{sanitized}_" if JS_RESERVED_WORDS.include?(sanitized.downcase)

        sanitized
      end

      # Check if a string is a valid JavaScript identifier
      #
      # @param name [String] The name to validate
      # @return [Boolean] true if valid, false otherwise
      def valid_js_identifier?(name)
        return false if name.nil? || name.empty?
        return false if JS_RESERVED_WORDS.include?(name.downcase)

        name.match?(JS_IDENTIFIER_PATTERN)
      end
    end
  end
end
