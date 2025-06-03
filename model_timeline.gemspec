# frozen_string_literal: true

require_relative 'lib/model_timeline/version'

Gem::Specification.new do |spec|
  spec.name          = 'model_timeline'
  spec.version       = ModelTimeline::VERSION
  spec.authors       = ['Alexandre Stapenhorst']
  spec.email         = ['eng.alexandreh@gmail.com']

  spec.summary       = 'Flexible audit logging for Rails models with PostgreSQL'
  spec.description   = 'Track changes to your Rails models with multiple configurable loggers using PostgreSQL'
  spec.homepage      = 'https://github.com/alexandreh92/model_timeline'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.6.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['{lib}/**/*', 'LICENSE', 'README.md']

  spec.add_dependency 'pg', '>= 1.1.0'
  spec.add_dependency 'rails', '>= 5.2.0'
end
