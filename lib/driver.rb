require 'selenium-webdriver'
require 'uri'
require 'spec_data'

class Driver
  @@driver = nil

  def self.reset
    Log.debug("[Gridium::Driver] Driver.reset: #{@@driver}")
    driver.manage.delete_all_cookies
    driver.manage.timeouts.page_load = Gridium.config.page_load_timeout
    driver.manage.timeouts.implicit_wait = 0 # always use explicit waits!

    # Ensure the browser is maximized to maximize visibility of element
    # Currently doesn't work with chromedriver, but the following workaround does:
    if @browser_type.eql?(:chrome)
      width = driver.execute_script("return screen.width;")
      height = driver.execute_script("return screen.height;")
      driver.manage.window.move_to(0, 0)
      driver.manage.window.resize_to(width, height)
    else
      driver.manage.window.maximize
    end
  end

  def self.driver
    unless @@driver
      Log.debug("[Gridium::Driver]  Driver.driver: instantiating new driver")
      @browser_type = Gridium.config.browser
      ##Adding support for remote browsers
      if Gridium.config.browser_source == :remote
        @@driver = Selenium::WebDriver.for(:remote, url: Gridium.config.target_environment, desired_capabilities: _set_capabilities)
        Log.debug("[Gridium::Driver] Remote Browser Requested: #{@@driver}")

        #this file detector is only used for remote drivers and is needed to upload files from test_host through Grid to browser
        @@driver.file_detector = lambda do |args|
          str = args.first.to_s
          str if File.exist?(str)
        end
      else
        @@driver = Selenium::WebDriver.for(Gridium.config.browser, desired_capabilities: _set_capabilities)
      end
      if Gridium.config.screenshots_to_s3
        #do stuff
        s3_project_folder = Gridium.config.project_name_for_s3
        s3_subfolder = Gridium.config.subdirectory_name_for_s3
        Log.debug("[Gridium::Driver] configuring s3 to save files to this directory: #{s3_project_folder} in addition to being saved locally")
        @s3 = Gridium::GridiumS3.new(s3_project_folder, s3_subfolder)
        Log.debug("[Gridium::Driver] s3 is #{@s3}")
      else
        Log.debug("[Gridium::Driver] s3 screenshots not enabled in spec_helper; they will be only be saved locally")
        @s3 = nil
      end
      reset
    end
    _log_shart #push out logs before doing something with selenium
    @@driver
  rescue StandardError => e
    Log.debug("[Gridium::Driver] #{e.backtrace.inspect}")
    Log.info("[Gridium::Driver] Driver did not load within (#{Gridium.config.page_load_timeout}) seconds.  [#{e.message}]")
    $fail_test_instantly = true
    Kernel.fail(e.message)
  end

  def self._log_shart
    #squeeze out the logs between each selenium call
    unless Gridium.config.selenium_log_level == 'OFF'
    @@driver.manage.logs.available_types.each {|log_type|
      @@driver.manage.logs.get(log_type).each {|log_statement|
        Log.debug("[SELENIUM::LOGS::#{log_type.upcase}] #{log_statement}")
      }
    }
    end
  end

  def self._set_capabilities()
    log_level = Gridium.config.selenium_log_level
    Selenium::WebDriver::Remote::Capabilities.new(
      browser_name: Gridium.config.browser,
      # log all the things
      loggingPrefs: {
        :browser => log_level,
        :client => log_level,
        :driver => log_level,
        :server => log_level
      },
      chrome_options: {
        args: ['--start-maximized', '--privileged', '--disable-web-security'],
        prefs: {
          # Need configurable download directory. Currently not supported on Selenium Grid
          download: {
            prompt_for_download: false,
            directory_upgrade: true,
            default_directory: Dir.pwd,
            extensions_to_open: ""
          },
          save_file: {
            default_directory: Dir.pwd
          },
          credentials_enable_service: false
        }
      }
    )
  end

  def self.s3
    #TODO figure out why I can't just use attr_reader :s3
    @s3
  end

  def self.driver= driver
    @@driver.quit if @@driver
    @@driver = driver
  end

  # =============== #
  # Driver Commands #
  # =============== #

  def self.visit(path)
    Log.debug("[Gridium::Driver]  Driver.Visit: #{@@driver}")
    retries = Gridium.config.page_load_retries

    begin
      if path
        Log.debug("[Gridium::Driver] Navigating to url: (#{path}).")
        driver
        time_start = Time.now
        driver.navigate.to(path)
        time_end = Time.new
        page_load = (time_end - time_start)
        Log.debug("[Gridium::Driver] Page loaded in (#{page_load}) seconds.")
        $verification_passes += 1
      end
    rescue StandardError => e
      Log.debug("[Gridium::Driver] #{e.backtrace.inspect}")
      Log.error("[Gridium::Driver] Timed out attempting to load #{path} for #{Gridium.config.page_load_timeout} seconds:\n#{e.message}\n - Also be sure to check the url formatting.  http:// is required for proper test execution (www is optional).")
      if retries > 0
        Log.info("[Gridium::Driver] Retrying page load of #{path}")
        retries -= 1
        retry
      end

      raise e
    end
  end

  def self.nav(path)
    Log.debug("[Gridium::Driver] Driver.nav: #{@@driver}")
    visit(Gridium.config.url + path)
  end

  def self.quit
    if @@driver
      begin
        _log_shart #push out the last logs
        Log.debug('[Gridium::Driver] Shutting down web driver...')
        @@driver.quit
      rescue Selenium::WebDriver::Error::NoSuchDriverError => e
        Log.debug("[Gridium::Driver] #{e.backtrace.inspect}")
        Log.error("[Gridium::Driver] Failed to shutdown webdriver: #{e.message}")
      ensure
        @@driver = nil
      end
    end
  end

  def self.go_back
    driver.navigate.back
  end

  def self.go_forward
    driver.navigate.forward
  end

  def self.html
    driver.page_source
  end

  def self.title
    driver.title
  end

  def self.current_url
    driver.current_url
  end

  def self.refresh
    driver.navigate.refresh
  end


  def self.current_domain
    site_url = driver.current_url.to_s
    # domain = site_url.match(/(https?:\/\/)?(\S*\.)?([\w\d]*\.\w+)\/?/i)[3]
    domain = URI.parse(site_url)
    host = domain.host
    if (!host.nil?)
      Log.debug("[Gridium::Driver] Current domain is: (#{host}).")
      return host
    else
      Log.error("[Gridium::Driver] Unable to parse URL.")
    end
  end

  def self.verify_url(given_url)
    Log.debug('[Gridium::Driver] Verifying URL...')
    current_url = self.current_url.to_s
    current_domain = self.current_domain.to_s
    if current_url.include?(given_url)
      Log.debug("[Gridium::Driver] Confirmed. (#{current_url}) includes (#{given_url}).")
      $verification_passes += 1
    else
      Log.error("[Gridium::Driver] (#{current_url}) does not include (#{given_url}).")
    end
  end

  #
  # Execute Javascript on the element
  #
  # @param [String] script - Javascript source to execute
  # @param [Element] element
  #
  # @return The value returned from the script
  #
  def self.execute_script(script, element)
    if element.is_a?(Element)
      #we dont care if Gridium.config.visible_elements_only is set to true or not
      ele = driver.find_element(element.by, element.locator)
      driver.execute_script(script, ele)
    else
      driver.execute_script(script, element)
    end
  end

  #
  # Execute Javascript on the page
  #
  # @param [String] script - Javascript source to execute
  #
  # @return The value returned from the script
  #
  def self.execute_script_driver(script)
    driver.execute_script(script)
  end

  def self.evaluate_script(script)
    driver.execute_script "return #{script}"
  end

  def self.save_screenshot(type = 'saved')
    Log.debug ("[Gridium::Driver] Capturing screenshot of browser...")
    timestamp = Time.now.strftime("%Y_%m_%d__%H_%M_%S")
    screenshot_path = File.join($current_run_dir, "screenshot__#{timestamp}__#{type}.png")
    driver.save_screenshot(screenshot_path)
    _save_to_s3_if_configured(screenshot_path)
    SpecData.screenshots_captured.push("screenshot__#{timestamp}__#{type}.png")   # used by custom_formatter.rb for embedding in report
    screenshot_path
  end

  def self._save_to_s3_if_configured(screenshot_path)
    if Gridium.config.screenshots_to_s3
      url = @s3.save_file(screenshot_path)
      Log.info("[Gridium::Driver] #{screenshot_path} saved to #{url}")
    end
  end


  def self.list_open_windows
    handles = driver.window_handles
    Log.debug("[Gridium::Driver] List of active windows:")
    handles.each do |handle|
      driver.switch_to.window(handle)
      Log.debug("[Gridium::Driver]  Window with title: (#{driver.title}) and handle: #{handle} is currently open.")
    end
    driver.switch_to.window(driver.window_handles.first)
  end

  def self.open_new_window(url)
    Log.debug("[Gridium::Driver] Opening new window and loading url (#{url})...")
    DriverExtensions.open_new_window(url)
  end

  def self.close_window
    Log.debug("[Gridium::Driver] Closing window (#{driver.title})...")
    DriverExtensions.close_window
  end

  def self.switch_to_window(title)
    current_title = driver.title
    Log.debug("[Gridium::Driver] Current window is: (#{current_title}).  Switching to next window (#{title})...")
    handles = driver.window_handles
    driver.switch_to.window(handles.first)
    handles.each do |handle|
      driver.switch_to.window(handle)
      if driver.title == title
        Log.debug("[Gridium::Driver] Window (#{driver.title}) is now the active window.")
        return
      end
    end
    list_open_windows
    Log.error("[Gridium::Driver] Unable to switch to window with title (#{title}).")
  end

  def self.switch_to_next_window
    current_title = driver.title
    Log.debug("[Gridium::Driver] Current window is: (#{current_title}).  Switching to next window...")
    driver.switch_to.window(driver.window_handles.last)
    Log.debug("[Gridium::Driver] Window (#{driver.title}) is now the active window.")
  end

  def self.switch_to_main_window
    current_title = driver.title
    Log.debug("[Gridium::Driver] Current window is: (#{current_title}).  Switching to main window...")
    driver.switch_to.window(driver.window_handles.first)
    Log.debug("[Gridium::Driver] Window (#{driver.title}) is now the active window.")
  end

  def self.switch_to_frame(by, locator)
    Log.debug("[Gridium::Driver] Attempting to switch to Frame at: #{locator}")
    driver.switch_to.frame(driver.find_element(by, locator))
    Log.debug("[Gridium::Driver] Frame at: #{locator} is now active frame!")
  end

  def self.switch_to_parent_frame
    Log.debug("[Gridium::Driver] Switching back to main parent frame")
    driver.switch_to.parent_frame
    Log.debug("[Gridium::Driver] Now back to Parent Frame")
  end

  def self.add_cookie(cookie)
    Log.debug("[Gridium::Driver] Adding cookie named #{cookie[:name]}")
    Driver.driver.manage.add_cookie(cookie)
  end

  def self.delete_cookie(cookie_name)
    Log.debug("[Gridium::Driver] Deleting cookie named #{cookie_name}")
    Driver.driver.manage.delete_cookie(cookie_name)
  end

  def self.get_cookie(cookie_name)
    Log.debug("[Gridium::Driver] Getting cookie named #{cookie_name}")
    Driver.driver.manage.cookie_named(cookie_name)
  end

  def self.all_cookies
    Log.debug("[Gridium::Driver] Getting all cookies")
    Driver.driver.manage.all_cookies
  end

  def self.delete_all_cookies
    Log.debug("[Gridium::Driver] Deleting all cookies")
    Driver.driver.manage.delete_all_cookies
  end

  # Raw driver send_keys to element, or to current active element
  # @param [Array] args
  # first arg may be an optional element, otherwise send the requested keys
  def self.send_keys(*args)
    Driver.driver.action.send_keys(*args).perform
  end

  private

  def self.raw_driver
    @@driver
  end

end
