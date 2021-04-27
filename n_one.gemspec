# frozen_string_literal: true

require_relative 'lib/n_one/version'

Gem::Specification.new do |spec|
  spec.name          = 'n_one'
  spec.version       = NOne::VERSION
  spec.authors       = ['Sergey Prikhodko']
  spec.email         = ['prikha@gmail.com']

  spec.summary       = 'N+1 auto-detection for ActiveRecord and PostgreSQL'
  spec.description   = 'N+1 auto-detection for ActiveRecord and PostgreSQL'
  spec.homepage      = 'https://github.com/prikha/n_one'
  spec.license       = 'Apache-2.0'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/prikha/n_one'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'pg_query'

  spec.add_development_dependency 'activerecord'
  spec.add_development_dependency 'factory_bot'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-minitest'
  spec.add_development_dependency 'rubocop-rake'
  spec.add_development_dependency 'sqlite3'
end
