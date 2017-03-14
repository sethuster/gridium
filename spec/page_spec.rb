require_relative 'spec_helper'
# require 'pry'
require 'page_objects/status_codes'

describe Page do
  let(:test_driver) { Driver }
  let(:test_page) { Page }
  let(:logger) { Log }

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
    it 'it finds all elements' do
      page = Page.new
      expect(test_driver.driver).to receive(:find_elements).with(:css, '.btn-primary')

      page.all(:css, '.btn-primary')
    end
  end

  describe '#assert_selector' do
    it 'it calls out to the driver to switch to default content' do
      allow(logger).to receive(:info)

      test_page.assert_selector('by', 'locator')

      expect(logger).to have_received(:info).with('Asserted Element present with locator locator using by')
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
end
