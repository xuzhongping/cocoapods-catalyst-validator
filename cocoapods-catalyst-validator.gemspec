# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-catalyst-validator/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-catalyst-validator'
  spec.version       = CocoapodsCatalystValidator::VERSION
  spec.authors       = ['nakahira']
  spec.email         = ['1021057927@qq.com']
  spec.summary       = %q{A cocoapods plugin for detecting whether the binary files in the integrated Pod support catalyst.}
  spec.homepage      = 'https://github.com/EXAMPLE/cocoapods-catalyst-validator'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*']
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.add_runtime_dependency 'cocoapods','~> 1.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
end
