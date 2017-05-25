require_relative 'spec_helper'
# require 'pry'
require 'page_objects/status_codes'
require 'page_objects/internet_home'

describe Page do
  let(:test_driver) { Driver }
  let(:test_page) { Page }
  let(:logger) { Log }
  let(:the_internet_url) { 'http://the-internet:5000' }
  let(:jquery_menu_url) { "#{the_internet_url}/jqueryui/menu" }

  before :all do
    Gridium.config.browser_source = :remote
    Gridium.config.target_environment = "http://hub:4444/wd/hub"
    Gridium.config.browser = :chrome
  end

  after :each do
    test_driver.quit
  end

  describe '#switch_to_frame' do
    it 'it calls out to the driver to switch frames' do
      expect(test_driver.driver.switch_to).to receive(:frame).with('frame')

      test_page.switch_to_frame('frame')
    end
  end

  describe '#switch_to_default' do
    it 'it calls out to the driver to switch to default content' do
      expect(test_driver.driver.switch_to).to receive(:default_content)

      test_page.switch_to_default
    end
  end

  describe '#scroll_to_bottom' do
    it 'it calls out to the driver to execute script command' do
      expect(test_driver).to receive(:execute_script_driver).with('window.scrollTo(0,100000)')

      test_page.scroll_to_bottom
    end
  end

  describe '#scroll_to_top' do
    it 'it calls out to the driver to execute script command' do
      expect(test_driver).to receive(:execute_script_driver).with('window.scrollTo(100000,0)')

      test_page.scroll_to_top
    end
  end

  describe '#execute_script' do
    it 'it calls out to the driver to execute script command' do
      expect(test_driver).to receive(:execute_script_driver).with('window.scrollTo(100000,0)')

      test_page.execute_script('window.scrollTo(100000,0)')
    end
  end

  describe '#wait_for_ajax' do
    it 'waits for jquery to complete on page' do
      $verification_passes = 0
      Driver.visit "https://www.sendgrid.com"
      expect(Page.wait_for_ajax).to be nil
    end
  end

  describe '#all' do
    let(:internet_home) {InternetHome.new}
    it '#all should return a list of gridium elements' do
      test_driver.visit the_internet_url
      nav_links = internet_home.all(:css, "[id=\"content\"] > ul > li > a")
      actual_nav_element_classes = (nav_links.map {|_| _.class}).uniq
      expected_nav_element_classes = [Element]
      expect(actual_nav_element_classes).to match_array(expected_nav_element_classes)
    end
  end

  describe '#assert_selector' do
    it 'it calls out to the driver to switch to default content' do
      allow(logger).to receive(:info)

      test_page.assert_selector('by', 'locator')

      expect(logger).to have_received(:info).with('[GRIDIUM::Page] Asserted Element present with locator locator using by')
    end
  end

  describe '#mouse_over' do
    let(:hover_url) { "http://mustadio:3000/hover"}
    let(:hover_txt) { "I am Jack's hover action" }
    let(:invisible_text) { "I am Jack's smirking div" }

    it 'can mouse_over text' do
      test_driver.visit hover_url
      Page.new.mouse_over hover_txt
      expect(Page.has_text?(invisible_text, visible: true)).to be true
    end

    it 'can hover text' do
      test_driver.visit hover_url
      Page.new.hover hover_txt
      expect(Page.has_text?(invisible_text, visible: true)).to be true
    end
  end

  describe '#click_*' do
    it 'clicks a link' do
      $verification_passes = 0
      Driver.visit "https://www.sendgrid.com"
      page = Page.new
      page.click_link "See Plans and Pricing"
      Driver.verify_url "https://sendgrid.com/pricing"
    end

    xit 'clicks a button' do
      # no buttons to click
    end

    it 'clicks link index 1' do
      $verification_passes = 0
      Driver.visit "https://www.sendgrid.com"
      page = Page.new

      page.click_link "Contact Us", link_index: 1
      Driver.verify_url "https://sendgrid.com/contact"
    end

    it 'clicks link index 2' do
      $verification_passes = 0
      Driver.visit "https://www.sendgrid.com"
      page = Page.new

      page.click_link "Contact Us", link_index: 2
      Driver.verify_url "https://sendgrid.com/contact"
    end

    it 'clicks on any element in dom' do
      $verification_passes = 0
      Driver.visit "https://www.sendgrid.com"
      page = Page.new

      page.click_link "Contact Us", link_index: 2
      Driver.verify_url "https://sendgrid.com/login"
    end
  end

  describe 'refresh' do
    let(:internet_status_url) {'the-internet:9000/status_codes'}
    it 'should return new subclass object' do
      Driver.visit internet_status_url
      status_code_page = StatusCodes.new
      new_page_object = status_code_page.refresh
      expect(new_page_object.class).to eq StatusCodes
    end
  end

  describe '#has_text?' do
    before do
      test_driver.visit the_internet_url
    end

    it 'finds text in all page source' do
      expect(Page.has_text?("Elemental Selenium")).to be true
    end

    it 'fails to find text in all page source' do
      test_driver.visit jquery_menu_url
      expect(Page.has_text?("Non-elemental Selenium", timeout: 2)).to be false
    end

    context 'with visible' do
      it 'finds only visible text' do
        expect(Page.has_text?("Elemental Selenium", visible: true)).to be true
      end

      it 'finds non-visible text in all page source' do
        test_driver.visit jquery_menu_url
        expect(Page.has_text?("Back to JQuery UI", visible: false)).to be true
      end

      it 'fails to find non-visible text' do
        test_driver.visit jquery_menu_url
        expect(Page.has_text?("Back to JQuery UI", visible: true, timeout: 5)).to be false
      end
    end
  end
end
