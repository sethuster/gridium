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
  end
end
