$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rspec'
require 'gridium'
require 'page_objects/google_home'

RSpec::Expectations.configuration.warn_about_potential_false_positives = false

# Setup any custom configuration for the Corundum framework
Gridium.configure do |config|
  config.report_dir = Dir.home.to_s + "/desktop"
  config.browser_source = :local
  config.target_environment = "localhost"
  config.browser = :firefox
  config.url = "http://www.sendgrid.com"
  config.page_load_timeout = 15
  config.element_timeout = 15
  config.log_level = :info
  config.highlight_verifications = true
  config.highlight_duration = 0.100
  config.screenshot_on_failure = false
end
