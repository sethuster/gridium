require 'gridium'

class GoogleHome
  attr_reader :plus_you, :gmail_option, :images_option, :apps_option, :signin_button, :google_logo, :search_box, :search_button, :lucky_button

  def initialize
    @plus_you = Element.new('+You option', :xpath, "//a[@class='gb_d gb_f' and @data-pid='119']")
    @gmail_option = Element.new('Gmail option', :xpath, "//a[@class='gb_d' and @data-pid='23']")
    @images_option = Element.new('Images option', :xpath, "//a[@class='gb_d' and @data-pid='2']")
    @apps_option = Element.new('Apps option', :xpath, "//a[@title='Apps']")
    @signin_button = Element.new('Sign in option', :xpath, "//a[@id='gb_70']")
    @google_logo = Element.new('Google logo', :xpath, "//*[@id='hplogo']")
    @search_box = Element.new('Search box', :css, 'input.gbqfif')
    @search_button = Element.new('Search button', :css, '#gbqfba')
    @lucky_button = Element.new('Lucky button', :css, '#gbqfbb')
  end

  def search(text)
    Log.info("Searching for #{text} using Google search field...")
    @search_box.send_keys(text)
  end

end
