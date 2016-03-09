# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ec2_bootstrap/version'

Gem::Specification.new do |spec|
  spec.name          = "ec2_bootstrap"
  spec.version       = Ec2Bootstrap::VERSION
  spec.authors       = ["Rachel King"]
  spec.email         = ["rachel@cozy.co"]
  spec.summary       = %q{Bootstrap EC2 instances with custom config.}
  spec.description   = %q{Bootstrap EC2 instances with custom config.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency "chef", "~> 12.5"
  spec.add_dependency "knife-ec2", "~> 0.12"
end
