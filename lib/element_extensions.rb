include Gridium

class Gridium::ElementExtensions
  def self.highlight(element)
    Log.debug("Highlighting element...")
    original_border = Gridium::Selenium::Driver.execute_script("return arguments[0].style.border", element.element)
    original_background = Gridium::Selenium::Driver.execute_script("return arguments[0].style.backgroundColor", element.element)
    Gridium::Selenium::Driver.execute_script("arguments[0].style.border='3px solid lime'; return;", element.element)
    Gridium::Selenium::Driver.execute_script("arguments[0].style.backgroundColor='lime'; return;", element.element)
    sleep (Gridium.config.highlight_duration)
    Gridium::Selenium::Driver.execute_script("arguments[0].style.border='" + original_border + "'; return;", element.element)
    Gridium::Selenium::Driver.execute_script("arguments[0].style.backgroundColor='" + original_background + "'; return;", element.element)
  end

  def self.scroll_to(element)
    Log.debug("Scrolling element into view...")
    Gridium::Selenium::Driver.execute_script("arguments[0].scrollIntoView(); return;", element.element)
    sleep 1
  end

  def self.hover_over(element)
    Gridium::Selenium::Driver.execute_script("var evObj = document.createEvent('MouseEvents'); evObj.initMouseEvent(\"mouseover\",true, false, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null); arguments[0].dispatchEvent(evObj);", element.element)
    sleep 2
  end

  def self.hover_away(element)
    Gridium::Selenium::Driver.execute_script("var evObj = document.createEvent('MouseEvents'); evObj.initMouseEvent(\"mouseout\",true, false, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null); arguments[0].dispatchEvent(evObj);", element.element)
    sleep 1
  end
end