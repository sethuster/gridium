require 'gridium/version'
require 'log'
require 'spec_data'
require 'driver'
require 'driver_extensions'
require 'element'
require 'element_extensions'
require 'element_verification'
require 'page'
require 'logger_extensions'
require 'gridium_logger'

module Gridium
  class << self
    attr_accessor :config
  end

  def self.configure
    self.config ||= Config.new
    yield config
  end

  class Config
    attr_accessor :report_dir, :browser_source, :target_environment, :browser, :url, :page_load_timeout, :element_timeout, :visible_elements_only, :log_level
    attr_accessor :highlight_verifications, :highlight_duration, :screenshot_on_failure

    def initialize
      @report_dir = Dir.home
      @browser_source = :local  #if browser source is set to remote, target environment needs to be set properly
      @target_environment = "localhost"
      @browser = :firefox
      @url = "about:blank"
      @page_load_timeout = 15
      @element_timeout = 15  #This needs to be changed to only look for an element after a page is done loading
      @visible_elements_only = true
      @log_level = :fatal
      @highlight_verifications = false
      @highlight_duration = 0.100
      @screenshot_on_failure = false
    end
  end
end
