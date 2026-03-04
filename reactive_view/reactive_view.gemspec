# frozen_string_literal: true

require_relative 'lib/reactive_view/version'

Gem::Specification.new do |spec|
  spec.name = 'reactive_view'
  spec.version = ReactiveView::VERSION
  spec.authors = ['ReactiveView Contributors']
  spec.email = ['hello@reactiveview.dev']

  spec.summary = 'Modern reactive frontends for Ruby on Rails using SolidJS'
  spec.description = 'ReactiveView is a Rails view framework gem for creating modern reactive frontends. ' \
                     'Build your frontend with TSX components (TypeScript + SolidJS), with all data, auth, ' \
                     'and business logic still handled by Rails.'
  spec.homepage = 'https://github.com/reactiveview/reactive_view'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    Dir[
      '{app,config,lib,template,npm/bin,npm/dist}/**/*',
      'MIT-LICENSE',
      'Rakefile',
      'README.md',
      'npm/package.json'
    ]
  end

  spec.require_paths = ['lib']

  # Rails dependency
  spec.add_dependency 'rails', '>= 7.0.0'

  # Type system
  spec.add_dependency 'dry-struct', '~> 1.6'
  spec.add_dependency 'dry-types', '~> 1.7'

  # HTTP client for SolidStart communication
  spec.add_dependency 'faraday', '~> 2.0'

  # File watching in development
  spec.add_dependency 'listen', '~> 3.8'

  # Development dependencies
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec-rails', '~> 6.0'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'rubocop-rails', '~> 2.19'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.22'
  spec.add_development_dependency 'webmock', '~> 3.18'
end
