class CookiePage < Page

  PAGE_NAME = '/cookies'

  def initialize
    @wait = Selenium::WebDriver::Wait.new :timeout => Gridium.config.element_timeout
    Log.debug("[CookiePage] New CookiePage Page at #{Driver.current_url} entitled #{Driver.title}. Now awaiting url to include #{PAGE_NAME}")
    @wait.until {Driver.current_url.include? PAGE_NAME}
  end

  def refresh
    Driver.refresh
    self.class.new
  end

  def get_cookie(cookie_name)
    cookie_value = Element.new("#{cookie_name} cookie row", :css, "tr[id=\"#{cookie_name}\"] [role=\"value\"]").text
    {:name => cookie_name, :value => cookie_value}
  end

  def get_all_cookies
    rows = Driver.driver.find_elements(:tag_name => "tr")
    cookies = rows.map do |x|
      cookie_name = x.find_element(:css => "[role=\"name\"]").text
      cookie_value = x.find_element(:css => "[role=\"value\"]").text
      {:name => cookie_name, :value => cookie_value}
    end
    cookies
  end
end
