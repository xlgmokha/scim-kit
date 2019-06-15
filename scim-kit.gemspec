# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'scim/kit/version'

Gem::Specification.new do |spec|
  spec.name          = 'scim-kit'
  spec.version       = Scim::Kit::VERSION
  spec.authors       = ['mo']
  spec.email         = ['mo@mokhan.ca']

  spec.summary       = 'A simple toolkit for working with SCIM 2.0'
  spec.description   = 'A simple toolkit for working with SCIM 2.0'
  spec.homepage      = 'https://www.github.com/mokhan/scim-kit'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |file|
      file.match(%r{^(test|spec|features)/})
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) do |file|
    File.basename(file)
  end
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.5.0'
  spec.metadata['yard.run'] = 'yri'

  spec.add_dependency 'activemodel', '>= 5.2.0'
  spec.add_dependency 'net-hippie', '~> 0.2'
  spec.add_dependency 'parslet', '~> 1.8'
  spec.add_dependency 'tilt', '~> 2.0'
  spec.add_dependency 'tilt-jbuilder', '~> 0.7'
  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'bundler-audit', '~> 0.6'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'ffaker', '~> 2.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.52'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.22'
  spec.add_development_dependency 'webmock', '~> 3.5'
end
