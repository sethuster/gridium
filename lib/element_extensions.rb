include Gridium

class Gridium::ElementExtensions
  class << self
    def highlight(element)
      Log.debug("[GRIDIUM::ElementExtensions] Highlighting element...")
      original_border = Driver.execute_script("return arguments[0].style.border", element.element)
      original_background = Driver.execute_script("return arguments[0].style.backgroundColor", element.element)
      Driver.execute_script("arguments[0].style.border='3px solid lime'; return;", element.element)
      Driver.execute_script("arguments[0].style.backgroundColor='lime'; return;", element.element)
      sleep (Gridium.config.highlight_duration)
      Driver.execute_script("arguments[0].style.border='" + original_border + "'; return;", element.element)
      Driver.execute_script("arguments[0].style.backgroundColor='" + original_background + "'; return;", element.element)
    end

    def scroll_to(element)
      Log.debug("[GRIDIUM::ElementExtensions] Scrolling element into view...")
      Driver.execute_script("arguments[0].scrollIntoView(); return;", element.element)
      sleep 1
    end

    def hover_away(element)
      Driver.execute_script("var evObj = document.createEvent('MouseEvents'); evObj.initMouseEvent(\"mouseout\",true, false, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null); arguments[0].dispatchEvent(evObj);", element.element)
      sleep 1
    end

    #
    # Mouse over the requested element at coordinate (Default x:0, y:0)
    # @param [Element] element
    # @param [Integer] x - element x coordinate
    # @param [Integer] y - element y coordinate
    #
    def mouse_over(element, x: 0, y: 0)
      Driver.driver.action.move_to(element.element, x, y).perform
    end

    alias_method :hover_over, :mouse_over

    def trigger_onblur(element)
      Driver.execute_script("arguments[0].focus(); arguments[0].blur(); return true", element.element)
    end

    # Occasionaly selenium is unable to click on elements in the DOM which have some
    # interesting React goodies around the element.
    def jquery_click(element)
      Driver.execute_script("arguments[0].click().change();", element.element)
    end

    #
    # Javascript HTML5 Drag n drop
    # @param [Element] source element (css locator required)
    # @param [Element] target element (css locator required)
    #
    def drag_to(source, target)
      dnd_js = File.read(File.join(File.dirname(__FILE__), "./js/dnd.js"))
      Log.debug("[GRIDIUM::ElementExtensions] dragging '#{source}' to '#{target}'")
      Driver.execute_script_driver(dnd_js + "$('#{source.locator}').simulateDragDrop({ dropTarget: '#{target.locator}'});")
    end

    #
    # Use Javascript to set element attribute value from :id
    # @param [String] selector  - css selector for find element by
    # @param [String] attribute - element attribute to set
    # @param [String] value     - element value to set
    #
    def set_attribute(selector, attr, val)
      Driver.execute_script_driver("document.querySelectorAll('#{selector}')[0].setAttribute('#{attr}', '#{val}')")
    end
  end
end
