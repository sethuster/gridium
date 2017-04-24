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

    def self.has_css?(css, options={})
      wait = Selenium::WebDriver::Wait.new(:timeout => 5)
      begin
        wait.until {Driver.driver.find_element(:css, css).enabled?}
      rescue Exception => exception
        Log.debug("[GRIDIUM::Page] has_css? is false because this exception was rescued: #{exception}")
        return false
      end
    end

    def self.has_xpath?(xpath, options={})
      wait = Selenium::WebDriver::Wait.new(:timeout => 5)
      begin
        wait.until {Driver.driver.find_element(:xpath, xpath).enabled?}
      rescue Exception => exception
        Log.debug("[GRIDIUM::Page] has_xpath? is false because this exception was rescued: #{exception}")
        return false
      end
    end

    def self.has_link?(linktext)
      wait = Selenium::WebDriver::Wait.new(:timeout => 5)
      begin
        wait.until {Driver.driver.find_element(:link_text, linktext).enabled?}
      rescue Exception => exception
        Log.debug("[GRIDIUM::Page] has_link? is false because this exception was rescued: #{exception}")
        return false
      end
    end

    def self.has_text?(text)
      has_flash?(text)
    end

    def self.has_flash?(text)
      wait = Selenium::WebDriver::Wait.new(:timeout => 5) #5 seconds every 500ms
      begin
        element = wait.until {Driver.html.include? text}
      rescue Exception => exception
        Log.debug("[GRIDIUM::Page] has_flash? exception was rescued: #{exception}")
        Log.warn("[GRIDIUM::Page] Could not find the flash message!")
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

    def find(by, locator)
      Element.new("Page Find Element", by, locator)
    end

    def first(by, locator)
      all(by, locator).first
    end

    def click_on(text)
      Element.new("Clicking #{text}", :xpath, "//*[text()='#{text}')]").click
    end

    # Click the link on the page
    # @param [String] link_text - Text of the link to click
    # @param [Integer] link_index (optional) - With multiple links on the page with the same name, click on the specified link index
    def click_link(link_text, link_index: nil)
      if link_index
        Element.new("Clicking #{link_text} Link (#{link_index})", :xpath, "(//a[contains(., '#{link_text}')])[#{link_index}]").click
      else
        Element.new("Clicking #{link_text} Link", :xpath, "//a[contains(., '#{link_text}')]").click
      end
    end

    # Click the button on the page
    # @param [String] link_text - Text of the link to click
    # @param [Integer] link_index - With multiple links on the page with the same name, click on the specified link index (Defaults to first link found)
    def click_button(button_name, button_index: nil)
      #The button maybe a link that looks like a button - we want to handle both
      if button_index
        button = Element.new("Clicking #{button_name} button (#{button_index})", :xpath, "(//button[contains(., '#{button_name}')])[#{button_index}]")
      else
        button = Element.new("Clicking #{button_name} button", :xpath, "//button[contains(., '#{button_name}')]")
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
