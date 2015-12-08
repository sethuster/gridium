require 'spec_helper'

describe Gridium do

  describe 'process' do
      test_url = "http://www.google.com"
      test_driver = Driver

      before :each do
        $verification_passes = 0
      end

      after :each do
        Driver.quit
      end
=begin
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
=end
      it 'Test 004 - Page.has_text method' do
        site = test_url
        test_driver.visit(site)
        puts test_driver.html.include?("google")
        puts Page.has_text?("google")
      end
    end
end
