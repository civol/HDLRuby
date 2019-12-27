# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'HDLRuby/version'

Gem::Specification.new do |spec|
  spec.name          = "HDLRuby"
  spec.version       = HDLRuby::VERSION
  spec.authors       = ["Lovic Gauthier"]
  spec.email         = ["lovic@ariake-nct.ac.jp"]

  spec.summary       = %q{Hardware Ruby is a library for describing and simulating digital electronic systems.}
  spec.description   = %q{Hardware Ruby is a library for describing and simulating digital electronic systems. With this library it will possible to describe synthesizable hardware using all the features of the Ruby language, e.g., object orientation, duck typing, closure. This library is also usable through irb for interactive design and simulation.}
  spec.homepage      = "https://github.com/civol"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0'
  spec.add_development_dependency "bundler", "~> 2.0.1"
  spec.add_development_dependency "rake", "~> 10.0"
  # spec.add_development_dependency "minitest", "~> 5.0"
end
