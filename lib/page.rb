module Gridium
  class Page

    def self.switch_to_frame(frame)
      Driver.driver.switch_to.frame(frame)
    end

    def self.switch_to_default
      Driver.driver.switch_to.default_content
    end

    def self.assert_selector(by, locator)
      asserted_element = Element.new("Asserted Element", by, locator)
      if asserted_element.eql? nil
        fail("Could not find element on page with locator #{locator} using #{by}")
      else
        Log.info("[GRIDIUM::Page] Asserted Element present with locator #{locator} using #{by}")
      end
    end

    def self.has_css?(css, opts = {})
      timeout = opts[:timeout] || 5
      wait = Selenium::WebDriver::Wait.new(:timeout => timeout)
      begin
        if opts[:visible]
          wait.until {Driver.driver.find_element(:css, css).displayed?}
        else
          wait.until {Driver.driver.find_element(:css, css).enabled?}
        end
      rescue Exception => exception
        Log.debug("[GRIDIUM::Page] has_css? is false because this exception was rescued: #{exception}")
        return false
      end
    end

    def self.has_xpath?(xpath, opts = {})
      timeout = opts[:timeout] || 5
      wait = Selenium::WebDriver::Wait.new(:timeout => timeout)
      begin
        if opts[:visible]
          wait.until {Driver.driver.find_element(:xpath, xpath).displayed?}
        else
          wait.until {Driver.driver.find_element(:xpath, xpath).enabled?}
        end
      rescue Exception => exception
        Log.debug("[GRIDIUM::Page] has_xpath? is false because this exception was rescued: #{exception}")
        return false
      end
    end

    def self.has_link?(linktext, opts = {})
      timeout = opts[:timeout] || 5
      wait = Selenium::WebDriver::Wait.new(:timeout => timeout)

      begin
        elem = nil
        wait.until do
          elem = Driver.driver.find_element(:link_text, linktext)
          elem.enabled?
        end

        if opts[:href]
          href = elem.attribute 'href'
          raise "Failed to verify link href='#{opts[:href]}': #{href} != #{opts[:href]}" unless href == opts[:href]
        end

        return true
      rescue Exception => exception
        Log.debug("[GRIDIUM::Page] has_link? is false because this exception was rescued: #{exception}")
        return false
      end
    end

    def self.has_button?(button_text, opts = {})
      timeout = opts[:timeout] || 5
      wait = Selenium::WebDriver::Wait.new(:timeout => timeout)

      begin
        elem = Element.new("#{button_text} button", :xpath, "//button[contains(., \"#{button_text}\")]", timeout: timeout)

        if opts[:disabled]
          wait.until {elem.disabled?}
        else
          wait.until {elem.enabled?}
        end
      rescue Exception => exception
        Log.debug("[GRIDIUM::Page] has_button? is false because this exception was rescued: #{exception}")
        return false
      end
    end

    def self.has_text?(text, opts = {})
      has_flash?(text, opts)
    end

    def self.has_flash?(text, opts = {})
      timeout = opts[:timeout] || 5
      wait = Selenium::WebDriver::Wait.new(:timeout => timeout)
      begin
        if opts[:visible]
          element = wait.until { Element.new("Finding text '#{text}'", :xpath, "//*[text()=\"#{text}\"]", timeout: timeout).displayed? }
        else
          element = wait.until { Driver.html.include? text }
        end
      rescue Exception => exception
        Log.debug("[GRIDIUM::Page] exception was rescued: #{exception}")
        Log.warn("[GRIDIUM::Page] Could not find the text '#{text}'!")
      end

      if element
        return true
      else
        return false
      end
    end

    def self.scroll_to_bottom
      Driver.execute_script_driver('window.scrollTo(0,100000)')
    end

    def self.scroll_to_top
      #TODO Verify this
      Driver.execute_script_driver('window.scrollTo(100000,0)')
    end

    def self.execute_script(script)
      Driver.execute_script_driver(script)
    end

    def self.evaluate_script(script)
      Driver.evaluate_script script
    end

    def self.wait_for_ajax
      Timeout.timeout(Gridium.config.page_load_timeout) do
        loop until jquery_loaded?
      end
    rescue Timeout::Error => e
      Log.warn("[GRIDIUM::Page] Timed-out waiting for ajax")
    end

    def self.jquery_loaded?
      self.evaluate_script("jQuery.active").zero?
    end

    #
    # JQuery click
    # @param [String] CSS selector
    #
    # Occasionaly selenium is unable to click on elements in the DOM which have some
    # interesting React goodies around the element.
    #
    def self.jquery_click(selector)
      Driver.evaluate_script("$(\"#{selector}\").click().change();")
    end

    def all(by, locator)
      root = Element.new("root", :tag_name, "html")
      root.find_elements(by, locator)
    end

    def find(by, locator, opts = {})
      Element.new("Page Find Element", by, locator, opts)
    end

    def first(by, locator)
      all(by, locator).first
    end

    #
    # mouse/hover over request 'text' at options coordinates and optional index
    # @param [String] text
    # @param [Integer] x - optional x coordinate
    # @param [Integer] y - optional y coordinate
    # @param [Integer] index - optional index, if multiple instances of 'text' are found
    #
    def mouse_over(text, x: 0, y: 0, index: 1)
      Element.new("Clicking #{text}", :xpath, "(//*[text()=\"#{text}\"])[#{index}]").mouse_over(x: x, y: y)
    end

    alias_method :hover, :mouse_over

    def click_on(text)
      Element.new("Clicking #{text}", :xpath, "//*[text()=\"#{text}\"]").click
    end

    # Click the link on the page
    # @param [String] link_text - Text of the link to click
    # @param [Integer] link_index (optional) - With multiple links on the page with the same name, click on the specified link index
    def click_link(link_text, link_index: nil)
      if link_index
        Element.new("Clicking #{link_text} Link (#{link_index})", :xpath, "(//a[contains(., \"#{link_text}\")])[#{link_index}]").click
      else
        Element.new("Clicking #{link_text} Link", :xpath, "//a[contains(., \"#{link_text}\")]").click
      end
    end

    # Click the button on the page
    # @param [String] link_text - Text of the link to click
    # @param [Integer] link_index - With multiple links on the page with the same name, click on the specified link index (Defaults to first link found)
    def click_button(button_name, button_index: nil)
      #The button maybe a link that looks like a button - we want to handle both
      if button_index
        button = Element.new("Clicking #{button_name} button (#{button_index})", :xpath, "(//button[contains(., \"#{button_name}\")])[#{button_index}]")
      else
        button = Element.new("Clicking #{button_name} button", :xpath, "//button[contains(., \"#{button_name}\")]")
      end
      begin
        button.click
      rescue Exception => exception
        Log.debug("[GRIDIUM::Page] Button not found and this exception was rescued: #{exception} Attempting Link - speed up test by using click_link method if this works...")
        click_link button_name, link_index: button_index
      end
    end

    def check(id) #checks a checkbox
      Element.new("Checkbox", :id, id).click
    end
  end

  def refresh
    Driver.refresh
    self.class.new
  end
end
