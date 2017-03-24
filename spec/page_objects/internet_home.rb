require 'gridium'
class InternetHome < Page

  PAGE_NAME = '/'

  def initialize
    @wait = Selenium::WebDriver::Wait.new :timeout => Gridium.config.element_timeout
    Log.debug("[InternetHome] New Internet Home Page at #{Driver.current_url} entitled #{Driver.title}. Now awaiting url to include #{PAGE_NAME}")
    @wait.until {Driver.current_url.include? PAGE_NAME}
  end
end
