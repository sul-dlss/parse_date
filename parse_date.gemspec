# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'parse_date/version'

Gem::Specification.new do |spec|
  spec.name          = 'parse_date'
  spec.version       = ParseDate::VERSION
  spec.authors       = ['Naomi Dushay']
  spec.email         = ['ndushay@stanford.edu']

  spec.summary       = 'parse date values out of strings and normalize them'
  spec.description   = 'Get normalized date values for searching, faceting and display (e.g. in Solr search engine)'
  spec.homepage      = 'https://github.com/sul-dlss/parse_date'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org/'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/sul-dlss/parse_date'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'zeitwerk', '~> 2.1'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.74.0'
  spec.add_development_dependency 'simplecov', '~> 0.17.0' # CodeClimate cannot use SimpleCov >= 0.18.0 for generating test coverage
end
