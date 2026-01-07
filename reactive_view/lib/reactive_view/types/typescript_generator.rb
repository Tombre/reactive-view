# frozen_string_literal: true

module ReactiveView
  module Types
    # Generates TypeScript type definitions from loader signatures.
    #
    # This generator creates two types of output:
    #
    # 1. Per-route loader files in `.reactive_view/types/loaders/`
    #    These provide auto-typed `useLoaderData()` hooks for each route.
    #
    # 2. Central route map in `.reactive_view/types/loader-data.d.ts`
    #    This enables cross-route loading with `useLoaderData("route/path", params)`.
    #
    # @example Per-route loader file
    #   // .reactive_view/types/loaders/users/index.ts
    #   import { useLoaderData as _useLoaderData } from "@reactive-view/core";
    #   import type { Resource } from "solid-js";
    #
    #   export interface LoaderData {
    #     users: { id: number; name: string }[];
    #     total: number;
    #   }
    #
    #   export function useLoaderData(): Resource<LoaderData> {
    #     return _useLoaderData<LoaderData>();
    #   }
    #
    # @example Central route map
    #   // .reactive_view/types/loader-data.d.ts
    #   declare module "@reactive-view/core" {
    #     interface LoaderDataMap {
    #       "users/index": UsersIndexLoaderData;
    #       "users/[id]": UsersIdLoaderData;
    #     }
    #   }
    #
    class TypescriptGenerator
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

      def collect_loaders
        LoaderRegistry.all_loader_paths.filter_map do |path|
          loader_class = LoaderRegistry.class_for_path(path)

          next unless loader_class._loader_sig

          {
            path: path,
            class_name: LoaderRegistry.path_to_class_name(path),
            interface_name: path_to_interface_name(path),
            schema: loader_class._loader_sig
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

        loaders.map do |loader|
          file_path = @loaders_dir.join("#{loader[:path]}.ts")
          content = build_loader_file(loader)

          FileUtils.mkdir_p(file_path.dirname)
          File.write(file_path, content)

          file_path.to_s
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

        Templates.render('types/loader_file.ts.template',
                         loader_path: loader[:path],
                         interface_definition: generate_nested_interfaces(loader[:schema], 'LoaderData'),
                         param_names_comment: param_names_comment)
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

        FileUtils.mkdir_p(@route_map_path.dirname)
        File.write(@route_map_path, content)
      end

      # Build the central route map TypeScript content
      #
      # @param loaders [Array<Hash>] List of loader metadata
      # @return [String] TypeScript content
      def build_route_map(loaders)
        <<~TYPESCRIPT
          // Auto-generated by ReactiveView - DO NOT EDIT
          // Run `rails reactive_view:types:generate` to regenerate

          import "@reactive-view/core";

          #{generate_interfaces(loaders)}

          declare module "@reactive-view/core" {
            interface LoaderDataMap {
          #{generate_loader_map_entries(loaders)}
            }
          }
        TYPESCRIPT
      end

      def path_to_interface_name(path)
        segments = path.split('/').map do |segment|
          segment
            .gsub(/\[\.\.\.(.*?)\]/, '\1')
            .gsub(/\[\[(.*?)\]\]/, '\1')
            .gsub(/\[(.*?)\]/, '\1')
            .camelize
        end

        "#{segments.join}LoaderData"
      end

      def generate_interfaces(loaders)
        return '' if loaders.empty?

        loaders.map do |loader|
          fields = schema_to_typescript_fields(loader[:schema])

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

          "#{key.name}#{optional}: #{ts_type}"
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

        # Get the primitive type name
        type_name = extract_type_name(type)

        case type_name
        when /String/i
          'string'
        when /Integer/i, /Float/i, /Decimal/i
          'number'
        when /Bool/i
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
    end
  end
end
