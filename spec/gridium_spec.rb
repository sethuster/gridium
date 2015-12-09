require 'spec_helper'

describe Gridium do

  describe 'Basic Tests' do
    test_url = "http://www.google.com"
    test_driver = Driver

    before :each do
      $verification_passes = 0
    end

    after :each do
      Driver.quit
    end

    it 'Test 000 has a version number' do
      expect(Gridium::VERSION).not_to be nil
    end

    it 'Test 001 should launch browser and url (specified by spec config)' do
      site = test_url #pulls from test config (above)
      test_driver.visit(site) #Driver pulls from test config (above)
      test_driver.verify_url("google.com")
      test_driver.visit('http://www.google.com')
      $verification_passes.should eql(3)
    end

    it 'Test 002 should launch browser and url (specified by config class)' do
      site = Gridium.config.url #pulls from framework config
      Driver.visit(site) #Driver pulls from framework config
      Driver.verify_url("sendgrid.com")
      $verification_passes.should eql(2)
    end

    it 'Test 003 should raise an error when visiting a redirected website' do
      site = "https://goo.gl/H5mLQP" #redirects to gridium repo
      Driver.visit(site)
      Log.info('The following error is anticipated.')
      $verification_passes.should eql(1)
      expect{Driver.verify_url(site)}.to raise_error
    end

    it 'Test 004 should instantiate new Gridium Elements' do
      Driver.visit('http://www.google.com')
      ele1 = Element.new('ele1', :css, '#lst-ib')
      ele1.send_keys 'sendgrid'
      ele2 = Element.new('ele2', :xpath, "//div[@id='search']//b[contains(.,'sendgrid')]")
      ele2.verify.present
      $verification_passes.should eql(3)
    end

    it 'Test 005 - Page.has_text method' do
      test_driver.visit(test_url)
      expect(test_driver.html.include?("google")).to eq true
      expect(Page.has_text?("google")).to eq true
    end

    it 'Test 006 - Stale Elements are fetched again' do
      #test to make sure old elements and fetched again and not spitting endless errors. QEA-6
      test_driver.visit("http://www.sendgrid.com")
      get_started_btn = Element.new("Get Started Button", :css, '.billboard .btn-primary')
      get_started_btn.click
      #we're now on a different page - the get_started_btn should be stale
      begin
        get_started_btn.click
      rescue
        expect(SpecData.execution_warnings.include?("Stale element detected.... 'Get Started Button' (By:css => '.billboard .btn-primary')")).to eq true
      end
    end


    end #End Basic Tests
end #End Gridium Tests
