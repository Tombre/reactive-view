# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/base'

module ReactiveView
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc 'Install ReactiveView into your Rails application'

      def create_pages_directory
        empty_directory 'app/pages'
        say 'Created app/pages directory for your ReactiveView pages', :green
      end

      def create_initializer
        template 'initializer.rb', 'config/initializers/reactive_view.rb'
        say 'Created ReactiveView initializer', :green
      end

      def create_frontend_config
        template 'reactive_view.config.ts.tt', 'reactive_view.config.ts'
        say 'Created reactive_view.config.ts for frontend configuration', :green
      end

      def create_example_page
        template 'index.tsx.erb', 'app/pages/index.tsx'
        say 'Created example index page', :green
      end

      def setup_working_directory
        say 'Setting up SolidStart working directory...', :yellow

        # Copy template files
        directory gem_template_path, '.reactive_view'

        say 'Created .reactive_view directory', :green
      end

      def create_typescript_config
        say 'Setting up TypeScript configuration...', :yellow

        # Create tsconfig.json at project root for editor support
        template 'tsconfig.json.tt', 'tsconfig.json'
        say 'Created tsconfig.json for TypeScript/editor support', :green
      end

      def add_to_gitignore
        gitignore_path = Rails.root.join('.gitignore')

        return unless gitignore_path.exist?

        gitignore_entries = [
          '',
          '# ReactiveView',
          '.reactive_view/src/pages/',
          '.reactive_view/src/routes/',
          '.reactive_view/types/',
          '.reactive_view/.vinxi/',
          '.reactive_view/.output/',
          '.reactive_view/daemon.log',
          ''
        ]

        append_to_file '.gitignore', gitignore_entries.join("\n")
        say 'Updated .gitignore', :green
      end

      def create_procfile
        template 'Procfile.dev', 'Procfile.dev' unless File.exist?('Procfile.dev')
        say 'Created Procfile.dev for development', :green
      end

      def create_bin_dev
        template 'bin_dev', 'bin/dev'
        chmod 'bin/dev', 0o755
        say 'Created bin/dev script', :green
      end

      def show_next_steps
        say ''
        say '=' * 60, :cyan
        say 'ReactiveView installed successfully!', :green
        say '=' * 60, :cyan
        say ''
        say 'Next steps:', :yellow
        say ''
        say '1. Start your development server:'
        say '   bin/dev'
        say ''
        say '2. Create pages in app/pages/:'
        say '   - app/pages/index.tsx         -> /'
        say '   - app/pages/about.tsx         -> /about'
        say '   - app/pages/users/[id].tsx    -> /users/:id'
        say ''
        say '3. Create loaders for data (optional):'
        say '   - app/pages/users/[id].loader.rb'
        say ''
        say '4. Generate TypeScript types:'
        say '   rails reactive_view:types:generate'
        say ''
        say 'TypeScript Support:', :yellow
        say '  Your editor should now recognize TypeScript types in app/pages/.'
        say '  Import from @reactive-view/core:'
        say '  import { useLoaderData } from "@reactive-view/core";'
        say ''
        say 'Documentation: https://github.com/reactiveview/reactive_view'
        say ''
      end

      private

      def gem_template_path
        File.expand_path('../../../../template', __dir__)
      end
    end
  end
end
