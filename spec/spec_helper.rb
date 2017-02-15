$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rspec'
require 'gridium'
require 'page_objects/google_home'
#TODO: uncomment before making PR
# require 'webmock/rspec'
require 'dotenv'
#RSpec::Expectations.configuration.warn_about_potential_false_positives = false

# Setup any custom configuration for the Corundum framework
Gridium.configure do |config|
  # config.report_dir = File.expand_path File.dirname(__FILE__)
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
  config.screenshots_to_s3 = false
  config.project_name_for_s3 = 'gridium'
  config.subdirectory_name_for_s3 = DateTime.now.strftime("%m_%d_%Y__%H_%M_%S")
  config.testrail = true
end

RSpec.configure do |config|
  include Gridium
    config.before :all do
      Dotenv.load './spec/fake_tr.env'
      # Create the test report root directory and then the spec_report directory
      Dir.mkdir(Gridium.config.report_dir) if not File.exist?(Gridium.config.report_dir)
      report_root_dir = File.expand_path(File.join(Gridium.config.report_dir, 'spec_reports'))
      Dir.mkdir(report_root_dir) if not File.exist?(report_root_dir)

      # Create the sub-directory for the test suite run
      current_run_report_dir = File.join(report_root_dir, "spec_results__" + DateTime.now.strftime("%m_%d_%Y__%H_%M_%S"))
      $current_run_dir = current_run_report_dir
      Dir.mkdir(current_run_report_dir)
      puts "logging to:  #{current_run_report_dir}"

      # Add the output log file for the rspec test run to the logger
      Log.add_device(File.open(File.join(current_run_report_dir, "spec_logging_output.log"), File::WRONLY | File::APPEND | File::CREAT))

      # Reset Suite statistics
      $verifications_total = 0
      $warnings_total = 0
      $errors_total = 0

      #Setup Gridium Spec Data
      SpecData.load_suite_state
      SpecData.load_spec_state
    end #end before:all

    #TODO: uncomment before making PR
    # config.before :each do
    #   stub_request(:post, /fake.faketr.fake/).
    #   with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
    #   to_return(status: 200, body: '{"id":1153, "suite_id":560}', headers: {})
    # end
end #end Rspec.config
