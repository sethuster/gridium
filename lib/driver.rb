require 'selenium-webdriver'
require 'uri'
require 'spec_data'


class Driver
  @@driver = nil

  def self.reset
    driver.manage.delete_all_cookies
    driver.manage.timeouts.page_load = Gridium.config.page_load_timeout
    driver.manage.timeouts.implicit_wait = Gridium.config.element_timeout

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
    begin
      unless @@driver
        @browser_type = Gridium.config.browser
        ##Adding support for remote browsers
        if Gridium.config.browser_source == :remote
          @@driver = Selenium::WebDriver.for(:remote, url: Gridium.config.target_environment, desired_capabilities: Gridium.config.browser)
          #this file detector is only used for remote drivers and is needed to upload files from test_host through Grid to browser
          @@driver.file_detector = lambda do |args|
            str = args.first.to_s
            str if File.exist?(str)
          end
          @@driver = Selenium::WebDriver.for(Gridium.config.browser)
        end
        reset
      end
      @@driver
    rescue Exception => e
      Log.debug(e.backtrace.inspect)
      Log.info("Driver did not load within (#{Gridium.config.page_load_timeout}) seconds.  [#{e.message}]")
      $fail_test_instantly = true
      Kernel.fail(e.message)
    end
  end

  def self.driver= driver
    @@driver.quit if @@driver
    @@driver = driver
  end

  # =============== #
  # Driver Commands #
  # =============== #

  def self.visit(path)
    begin
      Log.debug("Navigating to url: (#{path}).")
      driver
      time_start = Time.now
      driver.navigate.to(path)
      time_end = Time.new
      page_load = (time_end - time_start)
      Log.debug("Page loaded in (#{page_load}) seconds.")
      $verification_passes += 1
    rescue Exception => e
      Log.debug(e.backtrace.inspect)
      Log.error("#{e.message} - Also be sure to check the url formatting.  http:// is required for proper test execution (www is optional).")
    end
  end

  def self.nav(path)
    visit(Gridium.config.url + path)
  end

  def self.quit
    if @@driver
      Log.debug('Shutting down web driver...')
      @@driver.quit
      @@driver = nil
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
      Log.debug("Current domain is: (#{host}).")
      return host
    else
      Log.error("Unable to parse URL.")
    end
  end

  def self.verify_url(given_url)
    Log.debug('Verifying URL...')
    current_url = self.current_url.to_s
    current_domain = self.current_domain.to_s
    if current_domain.include?(given_url)
      Log.debug("Confirmed. (#{current_url}) includes (#{given_url}).")
      $verification_passes += 1
    else
      Log.error("(#{current_url}) does not include (#{given_url}).")
      Kernel.fail
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
    driver.execute_script(script, element)
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
    Log.debug ("Capturing screenshot of browser...")
    timestamp = Time.now.strftime("%Y_%m_%d__%H_%M_%S")
    screenshot_path = File.join($current_run_dir, "screenshot__#{timestamp}__#{type}.png")
    driver.save_screenshot(screenshot_path)
    SpecData.screenshots_captured.push("screenshot__#{timestamp}__#{type}.png")   # used by custom_formatter.rb for embedding in report
  end

  def self.list_open_windows
    handles = driver.window_handles
    Log.debug("List of active windows:")
    handles.each do |handle|
      driver.switch_to.window(handle)
      Log.debug("|  Window with title: (#{driver.title}) and handle: #{handle} is currently open.")
    end
    driver.switch_to.window(driver.window_handles.first)
  end

  def self.open_new_window(url)
    Log.debug("Opening new window and loading url (#{url})...")
    DriverExtensions.open_new_window(url)
  end

  def self.close_window
    Log.debug("Closing window (#{driver.title})...")
    DriverExtensions.close_window
  end

  def self.switch_to_window(title)
    current_title = driver.title
    Log.debug("Current window is: (#{current_title}).  Switching to next window (#{title})...")
    handles = driver.window_handles
    driver.switch_to.window(handles.first)
    handles.each do |handle|
      driver.switch_to.window(handle)
      if driver.title == title
        Log.debug("Window (#{driver.title}) is now the active window.")
        return
      end
    end
    list_open_windows
    Log.error("Unable to switch to window with title (#{title}).")
  end

  def self.switch_to_next_window
    current_title = driver.title
    Log.debug("Current window is: (#{current_title}).  Switching to next window...")
    driver.switch_to.window(driver.window_handles.last)
    Log.debug("Window (#{driver.title}) is now the active window.")
  end

  def self.switch_to_main_window
    current_title = driver.title
    Log.debug("Current window is: (#{current_title}).  Switching to main window...")
    driver.switch_to.window(driver.window_handles.first)
    Log.debug("Window (#{driver.title}) is now the active window.")
  end

end