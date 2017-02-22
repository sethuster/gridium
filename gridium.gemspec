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
  spec.description   = %q{Gridium makes integrating ruby and Selenium a breeze.  This is not for novice automation engineers.  Novices should checkout Capybara.  However, if you're comfortable with Selenium, and have used Capybara but find it not working well give Gridium a shot.}
  spec.homepage      = "http://github.com/sendgrid/gridium"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~>2.3"
  spec.add_development_dependency "dotenv", "~>2.1"

  spec.add_runtime_dependency "selenium-webdriver", ">= 2.50.0", "< 3"
  spec.add_runtime_dependency "oily_png", "~> 1.2"
  spec.add_runtime_dependency 'aws-sdk', '~> 2'
end
