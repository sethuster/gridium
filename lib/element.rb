require 'selenium-webdriver'
require 'oily_png'
require 'spec_data'

class Element
  attr_reader :name, :by, :locator


  def initialize(name, by, locator)
    @name = name
    @by = by
    @locator = locator
    @element_screenshot = nil #used to store the path of element screenshots for comparison

    # wrapped driver
    @driver = Driver.driver

    # selenium web element
    @element = nil

    #how long to wait between clearing an input and sending keys to it
    @text_padding_time = 0.15
  end

  def to_s
    "'#{@name}' (By:#{@by} => '#{@locator}')"
  end

  def element
    if stale?
      wait = Selenium::WebDriver::Wait.new :timeout => Gridium.config.element_timeout, :interval => 1
      if Gridium.config.visible_elements_only
        wait.until { @element = displayed_element }
      else
        wait.until { @element = @driver.find_element(@by, @locator); Log.debug("Finding element #{self}..."); @element.enabled? }
      end

    end
    @element
  end

  def element=(e)
    @element = e
  end

  def displayed_element
    found_element = nil
    #Found an issue where the element would go stale after it's found
    begin
      elements = @driver.find_elements(@by, @locator)
      elements.each do |element|
        if element.displayed? #removed check for element.enabled
          found_element = element; #this will always return the last displayed element
        end
      end
    rescue StandardError
      if found_element
        Log.warn("An element was found, but it was not displayed on the page. Gridium.config.visible_elements_only set to: #{Gridium.config.visible_elements_only} Element: #{self.to_s}")
      else
        Log.warn("Could not find Element: #{self.to_s}")
      end
    end

    found_element
  end

  # ================ #
  # Element Commands #
  # ================ #

  # soft failure, will not kill test immediately
  def verify(timeout: nil)
    Log.debug('Verifying new element...')
    timeout = Gridium.config.element_timeout if timeout.nil?
    ElementVerification.new(self, timeout)
  end

  # hard failure, will kill test immediately
  def wait_until(timeout: nil)
    Log.debug('Waiting for new element...')
    timeout = Gridium.config.element_timeout if timeout.nil?
    ElementVerification.new(self, timeout, fail_test: true)
  end

  def attribute(name)
    element.attribute(name)
  end

  def present?
    return element.enabled?
  rescue StandardError
    return false
  end

  def displayed?
    return element.displayed?
  rescue StandardError
    return false
  end

  def enabled?
    element.enabled?
  end

  def clear
    element.clear
    sleep @text_padding_time
  end

  def value
    element.attribute "value"
  end

  def click
    Log.debug("Clicking on #{self}")
    if element.enabled?
      ElementExtensions.highlight(self) if Gridium.config.highlight_verifications
      $verification_passes += 1
      element.click
    else
      Log.error('Cannot click on element.  Element is not present.')
    end
  end

  #
  # add to what's already in the text field
  # for cases when you don't want to stomp what's already in the text field
  #

  def append_keys(*args)
    ElementExtensions.highlight(self) if Gridium.config.highlight_verifications
    $verification_passes += 1
    unless element.enabled?
      raise "Browser Error: tried to enter #{args} but the input is disabled"
    end
    element.send_keys(*args)
    sleep @text_padding_time
    # when it's possible to validate for more than non-empty outcomes, do that here
  end

  #
  # overwrite to what's already in the text field
  # and validate afterward
  #

  def send_keys(*args)
    ElementExtensions.highlight(self) if Gridium.config.highlight_verifications
    $verification_passes += 1
    unless element.enabled?
      raise "Browser Error: tried to enter #{args} but the input is disabled"
    end
    if only_symbols? *args
      append_keys *args
    else
      _stomp_input_text *args
      field_empty_afterward? *args
    end
  end
  alias_method :text=, :send_keys



  def location
    element.location
  end

  def hover_over
    Log.debug("Hovering over element (#{self.to_s})...")
    # @driver.mouse.move_to(element)            # Note: Doesn't work with Selenium 2.42 bindings for Firefox v31
    # @driver.action.move_to(element).perform
    # @driver.mouse_over(@locator)
    if element.enabled?
      $verification_passes += 1
      ElementExtensions.hover_over(self) # Javascript workaround to above issue
    else
      Log.error('Cannot hover over element.  Element is not present.')
    end
  end

  def hover_away
    Log.debug("Hovering away from element (#{self.to_s})...")
    if element.enabled?
      $verification_passes += 1
      ElementExtensions.hover_away(self) # Javascript workaround to above issue
    else
      Log.error('Cannot hover away from element.  Element is not present.')
    end
  end

  # Raw webdriver mouse over
  def mouse_over
    Log.debug("Triggering mouse over for (#{self.to_s})...")
    if element.enabled?
      $verification_passes += 1
      ElementExtensions.mouse_over(self)
    else
      Log.error('Cannot mouse over.  Element is not present.')
    end
  end

  def scroll_into_view
    if element.enabled?
      $verification_passes += 1
      ElementExtensions.scroll_to(self)
    else
      Log.error('Cannot scroll element into view.  Element is not present.')
    end
  end

  def trigger_onblur
    Log.debug("Triggering onblur for (#{self.to_s})...")
    if element.enabled?
      $verification_passes += 1
      ElementExtensions.trigger_onblur(self)
    else
      Log.error('Cannot trigger onblur.  Element is not present.')
    end
  end

  def size
    element.size
  end

  def selected?
    element.selected?
  end

  def tag_name
    element.tag_name
  end

  def submit
    element.submit
  end

  def text
    #this is used for text based elements
    element.text
  end

  #
  # Search for an element within this element
  #
  # @param [Symbol] by  (:css or :xpath)
  # @param [String] locator
  #
  # @return [Element] element
  #
  def find_element(by, locator)
    Log.debug('Finding element...')
    element.find_element(by, locator)
  end

  #
  # Search for an elements within this element
  #
  # @param [Symbol] by  (:css or :xpath)
  # @param [String] locator
  #
  # @return [Array] elements
  #
  def find_elements(by, locator)
    element.find_elements(by, locator)
  end

  def save_element_screenshot
    Log.debug ("Capturing screenshot of element...")
    self.scroll_into_view

    timestamp = Time.now.strftime("%Y_%m_%d__%H_%M_%S")
    name = self.name.gsub(' ', '_')
    screenshot_path = File.join($current_run_dir, "#{name}__#{timestamp}.png")
    @driver.save_screenshot(screenshot_path)

    location_x = self.location.x
    location_y = self.location.y
    element_width = self.size.width
    element_height = self.size.height

    # ChunkyPNG commands tap into oily_png (performance-enhanced version of chunky_png)
    image = ChunkyPNG::Image.from_file(screenshot_path.to_s)
    image1 = image.crop(location_x, location_y, element_width, element_height)
    image2 = image1.to_image
    element_screenshot_path = File.join($current_run_dir, "#{name}__#{timestamp}.png")
    image2.save(element_screenshot_path)
    @element_screenshot = element_screenshot_path
    SpecData.screenshots_captured.push("#{name}__#{timestamp}.png")
  end

  def compare_element_screenshot(base_image_path)
    #Returns TRUE if there are no differences, FALSE if there are
    begin
      Log.debug("Loading Images for Comparison...")
      images = [
          ChunkyPNG::Image.from_file(base_image_path),
          ChunkyPNG::Image.from_file(@element_screenshot)
      ]
      #used to store image x,y diff
      diff = []
      Log.debug("Comparing Images...")
      images.first.height.times do |y|
        images.first.row(y).each_with_index do |pixel, x|
          diff << [x,y] unless pixel == images.last[x,y]
        end
      end

      Log.debug("Pixels total:    #{images.first.pixels.length}")
      Log.debug("Pixels changed:  #{diff.length}")
      Log.debug("Pixels changed:  #{(diff.length.to_f / images.first.pixels.length) * 100}%")

      x, y = diff.map{|xy| xy[0]}, diff.map{|xy| xy[1]}

      if x.any? && y.any?
        Log.debug("Differences Detected! Writing Diff Image...")
        name = self.name.gsub(' ', '_')
        #timestamp = Time.now.strftime("%Y_%m_%d__%H_%M_%S")
        element_screenshot_path = File.join($current_run_dir, "#{name}__diff_.png")
        images.last.rect(x.min, y.min, x.max, y.max, ChunkyPNG::Color(0,255,0))
        images.last.save(element_screenshot_path)
        return false
      else
        return true
      end
    rescue Exception => e
      Log.error("There was a problem comparing element images. #{e.to_s}")
    end
  end

  def method_missing(method_sym, *arguments, &block)
    Log.debug("called #{method_sym} on element #{@locator} by #{@by_type}")
    if @element.respond_to?(method_sym)
      @element.method(method_sym).call(*arguments, &block)
    else
      super
    end
  end

  private

  def stale?
    return true if @element.nil?
    @element.disabled?
  rescue StandardError
    Log.warn("Stale element detected.... #{self.to_s}")
    return true
  end

  #
  # helper to clear input and put new text in
  #

  def _stomp_input_text(*args)
    Log.debug("Clearing \"#{value}\" from element: (#{self})")
    element.clear
    sleep @text_padding_time
    Log.debug("Typing: #{args} into element: (#{self}).")
    element.send_keys(*args)
    sleep @text_padding_time
  end

  #
  # raise error if the field is empty after we sent it values
  # TODO: verify if text correct afterward, but need to be able to handle cases
  # of symbols like :space and :enter correctly
  #

  def field_empty_afterward?(*args)
    Log.debug("Checking the field after sending #{args}, to see if it's empty")
    check_again = (has_characters? *args and no_symbols? *args)
    field_is_empty_but_should_not_be = (check_again and field_empty?)
    if field_is_empty_but_should_not_be
      raise "Browser Error: tried to input #{args} but found an empty string afterward: #{value}"
    end
  end

  def field_empty?
    value.empty?
  end

  #
  # helper to check if *args to send_keys has any symbols
  # if so, don't bother trying to validate the text afterward
  #

  def no_symbols?(*args)
    symbols = args.select { |_| _.is_a? Symbol }
    if symbols.length > 0
      return false
    end
    true
  end

  #
  # helper to check if *args to send_keys has only symbols
  # if so, don't bother clearing the field first
  #

  def only_symbols?(*args)
    symbols = args.select { |_| _.is_a? Symbol }
    if symbols.length == args.length
      return true
    end
    false
  end

  #
  # helper to check if *args is not empty but contains only empty string(s)/symbol(s)
  # if so, don't bother trying to validate the text afterward
  #

  def has_characters?(*args)
    characters = args.select { |_| not _.is_a? Symbol }.join('')
    if characters.empty?
      return false
    end
    true
  end

end
