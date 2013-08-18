# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cursed/version'

Gem::Specification.new do |spec|
  spec.name          = "cursed"
  spec.version       = Cursed::VERSION
  spec.authors       = ["Alex Skryl"]
  spec.email         = ["rut216@gmail.com"]
  spec.description   = %q{A curses based window manager for displaying large amounts of tabular data.}
  spec.summary       = %q{A curses based window manager.}
  spec.homepage      = "http://github.com/skryl/cursed"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
