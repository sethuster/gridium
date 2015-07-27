# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gridium/version'

Gem::Specification.new do |spec|
  spec.name          = "gridium"
  spec.version       = Gridium::VERSION
  spec.authors       = ["Seth Urban"]
  spec.email         = ["sethuster@gmail.com"]

  spec.summary       = %q{This Gem is used to make building Selenium Tests without Capybara Easier.}
  spec.description   = %q{Capybara is a great tool to start making automated tests for your web application.  However, many automation engineers find it difficult to use effectively for UI tests.  Capybara works better when webkit, and not so well with mozilla.  This makes Selenium integration difficult, this gem remedies that.}
  spec.homepage      = "http://github.com/sethuster/gridium"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"

  spec.add_runtime_dependency "selenium-webdriver", ">=2.45.0"
  spec.add_runtime_dependency "oily_png"

end
