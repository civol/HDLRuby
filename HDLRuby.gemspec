# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'HDLRuby/version'

Gem::Specification.new do |spec|
  spec.name          = "HDLRuby"
  spec.version       = HDLRuby::VERSION
  spec.authors       = ["Lovic Gauthier"]
  spec.email         = ["lovic@ariake-nct.ac.jp"]

  spec.summary       = %q{HDLRuby is a library for describing and simulating digital electronic systems.}
  spec.description   = %q{HDLRuby is a library for describing and simulating digital electronic systems. With this library it will possible to describe synthesizable hardware using all the features of the Ruby language, e.g., object orientation, duck typing, closure. This library is also usable through irb for interactive design and simulation.}
  spec.homepage      = "https://github.com/civol/HDLRuby"
  spec.license       = "MIT"

  # if spec.respond_to?(:metadata) then
  #     spec.metadata["source_code_uri"] = "https://github.com/civol/HDLRuby"
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.extra_rdoc_files = ["README.md"]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  # spec.require_paths = ["lib"]
  spec.require_paths = ["lib","lib/HDLRuby"]

  spec.required_ruby_version = '>= 2.0'
  spec.add_development_dependency "bundler", "~> 2.0.1"
  spec.add_development_dependency "rake", "~> 10.0"
  # spec.add_development_dependency "minitest", "~> 5.0"
end
