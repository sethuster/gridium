require 'spec_helper'
require 'pry'

describe Driver do
  let(:gridium_config) { Gridium.config }

  let(:test_url) { 'www.google.com' }
  let(:redirected_url) { 'https://goo.gl/H5mLQP' }

  let(:test_driver) { Driver }
  let(:driver_manager) { Driver.driver.manage }
  let(:test_page) { Page }
  let(:test_spec_data) { SpecData }
  let(:logger) { Log }

  before :each do
    $verification_passes = 0
  end

  after :each do
    test_driver.quit
  end

  describe '#reset' do
    it 'resets all settings' do
      expect(driver_manager).to receive(:delete_all_cookies)
      expect(gridium_config.page_load_timeout).to eq 15
      expect(gridium_config.element_timeout).to eq 15

      test_driver.reset
    end
  end

  describe '#driver' do
    it 'sets browser configuration' do
      expect(gridium_config.browser_source).to eq :local
      expect(gridium_config.browser).to eq :firefox

      test_driver.driver
    end

    xit 'throws an exception if browser cannot load' do
      binding.pry
      test_driver.driver
    end
  end

  describe '#visit' do
    it 'verifies a browser opening and navigating to a specified url' do
      allow(logger).to receive(:debug).and_return("Navigating to url: (#{test_url}).")
      allow(logger).to receive(:debug).and_return('Shutting down web driver...')

      test_driver.visit(test_url)

      expect($verification_passes).to eq(1)
      expect(logger).to have_received(:debug).twice
    end

    it 'raises an exception if url is not valid' do
      test_driver.visit(nil)

      expect($verification_passes).to eq(0)
    end
  end

  describe '#nav' do
    it 'visits a specified path via gridum configs' do
      expect(test_driver).to receive(:visit).with(gridium_config.url + test_url)

      test_driver.nav(test_url)
    end
  end

  describe '#go_back' do
    it 'navigates back to previous position in browser' do
      expect(test_driver.driver.navigate).to receive(:back)

      test_driver.go_back
    end
  end

  describe '#go_forward' do
    it 'navigates forwards in browser' do
      expect(test_driver.driver.navigate).to receive(:forward)

      test_driver.go_forward
    end
  end

  describe '#html' do
    it 'finds the page source' do
      expect(test_driver.driver).to receive(:page_source)

      test_driver.html
    end
  end

  describe '#title' do
    it 'finds the page title' do
      expect(test_driver.driver).to receive(:title)

      test_driver.title
    end
  end

  describe '#current_url' do
    it 'finds the current_url' do
      expect(test_driver.driver).to receive(:current_url)

      test_driver.current_url
    end
  end

  describe '#refresh' do
    it 'refreshes the page' do
      expect(test_driver.driver.navigate).to receive(:refresh)

      test_driver.refresh
    end
  end

  describe '#current_domain' do
    it 'returns the current domain' do
      allow(logger).to receive(:debug)

      test_driver.current_domain

      expect(logger).to have_received(:debug).with('Current domain is: (www.mozilla.org).')
    end

    xit 'returns an error if host is nil' do
      allow(logger).to receive(:error)
      allow_any_instance_of(URI).to receive(:parse).and_return(nil)

      test_driver.current_domain

      expect(logger).to have_received(:error).with('Unable to parse URL.')
    end
  end

  describe '#verify_url' do
    it 'verifies the given url' do
      allow(logger).to receive(:debug)

      test_driver.visit(test_url)
      test_driver.verify_url(test_url)

      expect(logger).to have_received(:debug).with('Verifying URL...')
      expect(logger).to have_received(:debug).with('Confirmed. (https://www.google.com/?gws_rd=ssl) includes (www.google.com).')
      expect($verification_passes).to eq(2)
    end

    it 'returns an error if the current_url does not match given url' do
      allow(logger).to receive(:error)

      test_driver.visit(test_url)
      test_driver.verify_url('www.dogewow.com')

      expect(logger).to have_received(:error).with('(https://www.google.com/?gws_rd=ssl) does not include (www.dogewow.com).')
      expect($verification_passes).to eq(1)
    end
  end

  describe 'launching a browser' do
    it 'launches a browser and navigates to a url via Gridium config' do
      test_driver.visit(gridium_config.url)
      test_driver.verify_url("sendgrid.com")

      expect($verification_passes).to eq(2)
    end
  end

  describe 'redirecting to another url' do
    it 'raises an error when visiting a redirected website' do
      test_driver.visit(redirected_url)

      expect($verification_passes).to eq(1)
      expect{test_driver.verify_url(redirected_url)}.to raise_error
    end
  end

  describe 'creating new page elements' do
    it 'creates new Gridium Elements' do
      test_driver.visit(test_url)
      element_one = create_new_element('ele1', :css, '#lst-ib')
      element_one.send_keys 'sendgrid'

      element_two = create_new_element('ele2', :xpath, "//div[@id='search']//b[contains(.,'sendgrid')]")
      element_two.verify.present

      expect($verification_passes).to eq(3)
    end
  end

  describe 'finding elements on the page' do
    it 'uses the #has_text method to find elements on the page' do
      allow(test_page).to receive(:has_text?).with('google').and_return(true)

      test_driver.visit(test_url)
      test_page.has_text?("google")

      expect(test_driver.html.include?("google")).to eq true
      expect(test_page).to have_received(:has_text?).with('google')
    end
  end

  describe 'stale elements on page' do
    it 'warns when stale elements are found' do
      test_driver.visit("http://www.sendgrid.com")
      get_started_btn = create_new_element("Get Started Button", :css, '.billboard .btn-primary')
      get_started_btn.click
      begin
        get_started_btn.click
      rescue
        expect(test_spec_data.execution_warnings.include?("Stale element detected.... 'Get Started Button' (By:css => '.billboard .btn-primary')")).to eq true
      end
    end

    it 'calls #is_stale? when checking for elements on the page' do
      page_element = create_new_element("Get Started Button", :css, '.billboard .btn-primary')
      allow(page_element).to receive(:is_stale?).and_return(false)

      test_driver.visit("http://www.sendgrid.com")
      page_element.click
      begin
        page_element.click
      rescue
        expect(page_element).to have_received(:is_stale?).at_least(:once)
      end
    end
  end

  def create_new_element(name, by, locator)
    Element.new(name, by, locator)
  end
end