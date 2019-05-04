require_relative 'spec_helper'
# require 'pry'
require 'page_objects/status_codes'
require 'page_objects/internet_home'

describe Page do
  test_driver = Driver
  let(:test_page)             { Page }
  let(:logger)                { Log }
  let(:the_internet_url)      { 'http://the-internet:5000' }
  let(:jquery_menu_url)       { "#{the_internet_url}/jqueryui/menu" }
  let(:dynamic_url)           { "#{the_internet_url}/dynamic_loading/1"}
  let(:dynamic_controls_url)  { "#{the_internet_url}/dynamic_controls"}
  let(:mustadio_url)          { "http://mustadio:3000" }
  let(:not_clickable_url)     { "#{mustadio_url}/notClickable"}

  before :all do
    Gridium.config.browser_source = :remote
    Gridium.config.target_environment = "http://hub:4444/wd/hub"
    Gridium.config.browser = :chrome
  end

  after :all do
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
      Driver.visit dynamic_url
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
    let(:hover_url) { "#{mustadio_url}/hover"}
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
    let(:link_button_txt) { 'Do it!' }
    let(:url)             { "#{mustadio_url}/buttons-links" }

    before :example do
      Driver.visit url
    end

    context 'when page has multiple links with same text' do
      it 'clicks a link' do
        Page.new.click_link(link_button_txt)
        aggregate_failures 'expectations' do
          expect(Page.has_text?("Link 1 clicked...", visible: true, timeout: 1)).to be false
          expect(Page.has_text?("Link 2 clicked...", visible: true, timeout: 1)).to be false
          expect(Page.has_text?("Link 3 clicked...", visible: true, timeout: 1)).to be true
        end
      end

      it 'clicks link index 1' do
        Page.new.click_link(link_button_txt, link_index: 1)
        aggregate_failures 'expectations' do
          expect(Page.has_text?("Link 1 clicked...", visible: true, timeout: 1)).to be true
          expect(Page.has_text?("Link 2 clicked...", visible: true, timeout: 1)).to be false
          expect(Page.has_text?("Link 3 clicked...", visible: true, timeout: 1)).to be false
        end
      end

      it 'clicks link index 2' do
        Page.new.click_link(link_button_txt, link_index: 2)
        aggregate_failures 'expectations' do
          expect(Page.has_text?("Link 1 clicked...", visible: true, timeout: 1)).to be false
          expect(Page.has_text?("Link 2 clicked...", visible: true, timeout: 1)).to be true
          expect(Page.has_text?("Link 3 clicked...", visible: true, timeout: 1)).to be false
        end
      end
    end

    context 'when page has multiple buttons with same text' do
      it 'clicks a button' do
        Page.new.click_button(link_button_txt)
        aggregate_failures 'expectations' do
          expect(Page.has_text?("Button 1 clicked...", visible: true, timeout: 1)).to be false
          expect(Page.has_text?("Button 2 clicked...", visible: true, timeout: 1)).to be false
          expect(Page.has_text?("Button 3 clicked...", visible: true, timeout: 1)).to be true
        end
      end

      it 'clicks button index 1' do
        Page.new.click_button(link_button_txt, button_index: 1)
        aggregate_failures 'expectations' do
          expect(Page.has_text?("Button 1 clicked...", visible: true, timeout: 1)).to be true
          expect(Page.has_text?("Button 2 clicked...", visible: true, timeout: 1)).to be false
          expect(Page.has_text?("Button 3 clicked...", visible: true, timeout: 1)).to be false
        end
      end

      it 'clicks button index 2' do
        Page.new.click_button(link_button_txt, button_index: 2)
        aggregate_failures 'expectations' do
          expect(Page.has_text?("Button 1 clicked...", visible: true, timeout: 1)).to be false
          expect(Page.has_text?("Button 2 clicked...", visible: true, timeout: 1)).to be true
          expect(Page.has_text?("Button 3 clicked...", visible: true, timeout: 1)).to be false
        end
      end
    end

    it 'clicks on element in dom with text' do
      Page.new.click_on "Multi Links"
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

  describe '#has_css?' do
    let(:visible_content) { "#start" }
    let(:hidden_content)  { "#finish" }
    let(:unknown_content) { ".not-here" }

    before do
      test_driver.visit dynamic_url
    end

    it 'finds css' do
      expect(Page.has_css?(hidden_content)).to be true
    end

    it 'fails to find non-existent css' do
      expect(Page.has_css?(unknown_content)).to be false
    end

    context 'with timeout' do
      let(:wait_timeout) { 5 }

      it 'timeouts within requested time in seconds' do
        time = Benchmark.realtime do
          expect(Page.has_css?(unknown_content, timeout: wait_timeout)).to be false
        end

        expect(time).to be_within(2).of(wait_timeout), "Expected #{time} to be within 2 seconds of requested timeout '#{wait_timeout}'"
      end
    end

    context 'with visible' do
      it 'finds only visible css' do
        expect(Page.has_css?(visible_content, visible: true)).to be true
      end

      it 'finds non-visible css' do
        expect(Page.has_css?(hidden_content, visible: false)).to be true
      end

      it 'fails to find non-visible css' do
        expect(Page.has_css?(hidden_content, visible: true, timeout: 2)).to be false
      end
    end
  end

  describe '#has_xpath?' do
    let(:visible_content) { "//*[@id='start']" }
    let(:hidden_content)  { "//*[@id='finish']" }
    let(:unknown_content) { "//*[@class='.not-here']" }

    before do
      test_driver.visit dynamic_url
    end

    it 'finds xpath' do
      expect(Page.has_xpath?(hidden_content)).to be true
    end

    it 'fails to find non-existent xpath' do
      expect(Page.has_xpath?(unknown_content)).to be false
    end

    context 'with timeout' do
      let(:wait_timeout) { 5 }

      it 'timeouts within requested time in seconds' do
        time = Benchmark.realtime do
          expect(Page.has_xpath?(unknown_content, timeout: wait_timeout)).to be false
        end

        expect(time).to be_within(2).of(wait_timeout), "Expected #{time} to be within 2 seconds of requested timeout '#{wait_timeout}'"
      end
    end

    context 'with visible' do
      it 'finds only visible xpath' do
        expect(Page.has_xpath?(visible_content, visible: true)).to be true
      end

      it 'finds non-visible xpath' do
        expect(Page.has_xpath?(hidden_content, visible: false)).to be true
      end

      it 'fails to find non-visible xpath' do
        expect(Page.has_xpath?(hidden_content, visible: true, timeout: 2)).to be false
      end
    end
  end

  describe '#has_link?' do
    before do
      test_driver.visit dynamic_controls_url
    end

    it 'has_link? "Elemental Selenium"' do
      expect(Page.has_link?("Elemental Selenium")).to be true
    end

    context 'with verifying href' do
      it 'fails to verify link text with href not matchine' do
        expect(Page.has_link?("Elemental Selenium", href: "")).to be false
      end

      it 'verifies link text and href' do
        expect(Page.has_link?("Elemental Selenium", href: "http://elementalselenium.com/")).to be true
      end

    end

    it 'does not has_link? "Selenium Elemental"' do
      expect(Page.has_link?("Selenium Elemental")).to be false
    end

    context 'with timeout' do
      let(:wait_timeout) { 1 }

      it 'timeouts within requested time in seconds' do
        time = Benchmark.realtime do
          expect(Page.has_link?("Selemental", timeout: wait_timeout)).to be false
        end

        expect(time).to be_within(1).of(wait_timeout), "Expected #{time} to be within 1 second of requested timeout '#{wait_timeout}'"
      end
    end
  end

  describe '#has_button?' do
    before do
      test_driver.visit dynamic_controls_url
    end

    it 'has_button? "Remove"' do
      expect(Page.has_button?("Remove")).to be true
    end

    it 'does not have button "Add"' do
      expect(Page.has_button?("Add")).to be false
    end

    context 'with timeout' do
      let(:wait_timeout) { 1 }

      it 'timeouts within requested time in seconds' do
        time = Benchmark.realtime do
          expect(Page.has_button?("Selemental", timeout: wait_timeout)).to be false
        end

        expect(time).to be_within(1).of(wait_timeout), "Expected #{time} to be within 1 second of requested timeout '#{wait_timeout}'"
      end
    end
  end

  context 'with \'disabled\' param' do
    before :example do
      test_driver.visit not_clickable_url
    end

    describe '#has_button?' do
      it 'finds the disabled button' do
        expect(Page.has_button?("no click for you", disabled: true)).to be true
      end

      it 'fails to find enabled button that is disabled - default' do
        expect(Page.has_button?("no click for you")).to be false
      end

      it 'fails to find enabled button that is disabled - with param' do
        expect(Page.has_button?("no click for you", disabled: false)).to be false
      end
    end
  end
end
