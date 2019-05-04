require 'spec_helper'
require 'page_objects/cookie_page'

describe Driver do
  let(:gridium_config)    { Gridium.config }
  let(:mustadio)          {'http://mustadio:3000'}
  let(:the_internet_url)  {'http://the-internet:5000'}

  let(:test_driver) { Driver }
  let(:driver_manager) { Driver.driver.manage }
  let(:test_page) { Page }
  let(:test_spec_data) { SpecData }
  let(:test_driver_extension) { DriverExtensions }
  let(:logger) { Log }

  before :each do
    $verification_passes = 0
  end

  after :each do
    test_driver.quit
  end

  describe '#quit' do
    it 'cleans up the session and resets driver to nil' do
      test_driver.quit
      expect(test_driver.send(:raw_driver)).to be_nil
    end

    context 'when driver session is borked' do
      before :example do
        expect(test_driver.driver).to receive(:quit).and_raise(Selenium::WebDriver::Error::NoSuchDriverError)
      end

      it 'gracefully handles NoSuchDriverError' do
        expect {test_driver.quit}.not_to raise_error
      end

      it 'sets the driver to nil' do
        test_driver.quit
        expect(test_driver.send(:raw_driver)).to be_nil
      end

      it 'logs the failure' do
        fail_msg = /Failed to shutdown webdriver: Selenium::WebDriver::Error::NoSuchDriverError/
        expect(test_driver.quit).to include fail_msg
      end
    end
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
      expect(gridium_config.browser_source).to eq :remote
      expect(gridium_config.browser).to eq :chrome

      test_driver.driver
    end
  end

  describe '#visit' do
    context 'timeout' do
      let(:original_timeout) {gridium_config.page_load_timeout}
      let(:instant_timeout) {0}
      before :each do
        #have to touch original_timeout in before, or it will be 0 in the after block
        gridium_config.page_load_timeout = original_timeout * instant_timeout
      end

      after :each do
        gridium_config.page_load_timeout = original_timeout
      end

      it 'should raise script timeout error' do
        too_long = 1 + instant_timeout
        slow_url = "#{mustadio}/slow?seconds=#{too_long}"
        #TODO seek a workaround to this issue of 'cannot determine loading status' instakilling the browser
        # this looks like a bug in chrome https://bugs.chromium.org/p/chromedriver/issues/detail?id=402
        # expect {test_driver.send(:visit, slow_url)}.to raise_error error = Selenium::WebDriver::Error::ScriptTimeoutError
        expect {test_driver.send(:visit, slow_url)}.to raise_error
      end
    end

    it 'verifies a browser opening and navigating to a specified url' do
      allow(logger).to receive(:debug).and_return("Navigating to url: (#{mustadio}).")
      allow(logger).to receive(:debug).and_return('Shutting down web driver...')

      test_driver.visit(mustadio)

      expect($verification_passes).to eq(1)
      #expect(logger).to have_received(:debug).at_most(3).times
    end

    it 'raises an exception if url is not valid' do
      test_driver.visit(nil)

      expect($verification_passes).to eq(0)
    end

  end

  describe '#nav' do
    let(:url) { "/fields" }
    it 'visits a specified path via gridum configs' do
      expect(test_driver).to receive(:visit).with(gridium_config.url + url)
      test_driver.nav(url)
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

  describe '#send_keys' do
    let(:test_input_page) { 'http://mustadio:3000/fields' }
    let(:input_elem_1)    { Page.new.find(:css, '[id=input_1]') }
    let(:input_elem_2)    { Page.new.find(:css, '[id=input_2]') }

    before :example do
      test_driver.visit test_input_page
      input_elem_1.clear
      input_elem_2.clear
    end

    it 'sends keys to active element' do
      # activate input by clicking on it
      input_elem_1.click
      Driver.send_keys "42"
      expect(input_elem_1.value).to eq "42"
    end

    it 'sends keys to requested element' do
      Driver.send_keys(input_elem_2.element, "42")
      expect(input_elem_2.value).to eq "42"
    end
  end

  describe '#current_domain' do
    it 'returns the current domain' do
      allow(logger).to receive(:debug)
      test_driver.visit the_internet_url
      test_driver.current_domain

      expect(logger).to have_received(:debug).with('[Gridium::Driver] Current domain is: (the-internet).')
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

      test_driver.visit(mustadio)
      test_driver.verify_url "mustadio:3000"
      expect(logger).to have_received(:debug).with('[Gridium::Driver] Verifying URL...')
      expect(logger).to have_received(:debug).with("[Gridium::Driver] Confirmed. (#{mustadio}/) includes (mustadio:3000).")
      expect($verification_passes).to eq(2)
    end

    it 'rescues and logs an error if the current_url does not match given url' do
      allow(logger).to receive(:error)

      test_driver.visit(mustadio)
      test_driver.verify_url('www.dogewow.com')

      expect(logger).to have_received(:error).with("[Gridium::Driver] (#{mustadio}/) does not include (www.dogewow.com).")
      expect($verification_passes).to eq(1)
    end
  end

  describe '#execute_script' do
    it 'calls execute script on the driver' do
      expect(test_driver.driver).to receive(:execute_script)

      test_driver.execute_script('script;', 'element')
    end
  end

  describe '#execute_script_driver' do
    it 'calls execute script on the driver' do
      expect(test_driver.driver).to receive(:execute_script)

      test_driver.execute_script_driver('script;')
    end
  end

  describe '#evaluate_script' do
    it 'calls execute_script and returns' do
      expect(test_driver.driver).to receive(:execute_script)

      test_driver.evaluate_script('script;')
    end
  end

  describe '#save_screenshot' do
    it 'saves the screenshot and logs it' do
      allow(logger).to receive(:debug)
      allow(logger).to receive(:info)
      allow(logger).to receive(:debug).and_return('Shutting down web driver...')

      local_path = test_driver.save_screenshot

      aggregate_failures 'expectations' do
        expect(logger).to have_received(:debug).with(/Capturing screenshot of browser.../)
        expect(local_path).to include $current_run_dir
        expect(File.exist?(local_path)).to be true
      end
    end
  end

  describe '#list_open_windows' do
    # #window_handles function has not been implemented
    it 'calls returns a list of open windows and logs it' do
      allow(logger).to receive(:debug).with('List of active windows:')
      allow(logger).to receive(:debug).and_return('Shutting down web driver...')

      test_driver.list_open_windows

      #expect(logger).to have_received(:debug).at_most(3).times
    end
  end

  describe '#open_new_window' do
    it 'logs and opens new window' do
      allow(logger).to receive(:debug).with("[Gridium::Driver] Opening new window and loading url (#{mustadio})...")
      expect(test_driver_extension).to receive(:open_new_window).with(mustadio)

      test_driver.open_new_window(mustadio)
    end
  end

  describe '#close_window' do
    it 'logs and closes new window' do
      allow(logger).to receive(:debug).with("Closing window (#{test_driver.driver.title})...")
      allow(logger).to receive(:debug).and_return('Shutting down web driver...')

      expect(test_driver_extension).to receive(:close_window)
      expect(logger).to receive(:debug).twice

      test_driver.close_window
    end
  end

  describe '#switch_to_window' do
    # #window_handles function has not been implemented
    it 'logs and switches to new window' do
      allow(logger).to receive(:debug).with("Current window is: (#{test_driver.driver.title}).")
      allow(logger).to receive(:debug).with('Shutting down web driver...')

      expect(test_driver).to receive(:list_open_windows)
      expect(logger).to receive(:debug).twice

      test_driver.switch_to_window('title')
    end
  end

  describe 'launching a browser' do
    it 'launches a browser and navigates to a url via Gridium config' do
      test_driver.visit mustadio
      test_driver.verify_url("mustadio:3000")

      expect($verification_passes).to eq(2)
    end
  end

  xdescribe 'redirecting to another url' do
    # TODO: mustadio
    # let(:redirected_url) { 'https://goo.gl/H5mLQP' }

    xit 'logs an error when verifying a url for a redirected website' do
      allow(logger).to receive(:error)

      test_driver.visit(redirected_url)

      expect($verification_passes).to eq(1)
      test_driver.verify_url(redirected_url)
      expect(logger).to have_received(:error).with('[Gridium::Driver] (https://github.com/sethuster/gridium) does not include (https://goo.gl/H5mLQP).')
    end
  end

  describe 'creating new page elements' do
    let(:url) { "#{mustadio}/fields"}

    it 'creates and waits with verify for new Gridium Elements' do
      test_driver.visit(url)

      element_one = create_new_element('ele1', :css, '#input_1')
      element_one.send_keys 'sendgrid'

      element_two = create_new_element('ele2', :xpath, "//input[@id='input_2']")
      element_two.verify.visible

      expect($verification_passes).to be < 4
    end

    it 'creates and waits with wait_until for new Gridium Elements' do
      test_driver.visit(url)
      element_one = create_new_element('ele1', :css, '#input_1')
      element_one.send_keys 'sendgrid'

      element_two = create_new_element('ele2', :xpath, "//*[@id='input_2']")
      element_two.wait_until.visible

      expect($verification_passes).to be < 4
    end
  end

  describe 'finding elements on the page' do
    let(:url)     { "#{mustadio}/fields"}
    let(:heading) { "i am jack's form" }

    it 'uses the #has_text method to find elements on the page' do
      allow(test_page).to receive(:has_text?).with(heading).and_return(true)

      test_driver.visit(url)
      test_page.has_text?(heading)

      expect(test_driver.html.include?(heading)).to eq true
      expect(test_page).to have_received(:has_text?).with(heading)
    end
  end

  describe 'stale elements on page' do
    let(:url)             { "#{mustadio}/theStaleMaker" }
    let(:stale_span)      { create_new_element("Stale Span", :css, '#stale') }
    let(:make_stale_btn)  { create_new_element("Make stale button", :css, '#makeStale') }
    let(:make_fresh_btn)  { create_new_element("Make fresh button", :css, '#makeFresh') }

    before :example do
      test_driver.visit(url)
    end

    it 'warns when stale elements are found' do
      sleep 0.5
      expect(test_driver.current_url).to include '/theStaleMaker'
      begin
        stale_span.click
        make_stale_btn.click
        make_fresh_btn.click
        stale_span.wait_until.visible
      rescue
        expect(test_spec_data.execution_warnings.include?("[GRIDIUM::Element] Stale element detected.... 'Plans and Pricing' (By:css => '#home-pricing-cta')")).to eq true
      end
    end

    it 'calls #stale? when checking for elements on the page' do
      allow(make_stale_btn).to receive(:stale?).and_return(false)

      begin
        make_stale_btn.click
      rescue
        expect(make_stale_btn).to have_received(:stale?).at_least(:once)
      end
    end
  end

  describe 'S3 support' do
    before :each do
      Gridium.config.screenshots_to_s3 = true
    end

    it 'should ignore S3 if configuration is false' do
      Gridium.config.screenshots_to_s3 = false
      test_driver.driver
      s3_is_instantiated = !test_driver.s3.nil?
      expect(s3_is_instantiated).to be false
    end

    xit 'should instantiate S3 if configuration is true' do
      test_driver.driver
      s3_is_instantiated = !test_driver.s3.nil?
      expect(s3_is_instantiated).to be true
    end

    context 'with s3 screenshot upload configured' do
      before :example do
        allow(logger).to receive(:debug)
        allow(logger).to receive(:info)

        test_driver.visit the_internet_url
      end

      xit 'should save a screenshot to s3 when configured' do |example|
        test_name   = "#{example.metadata[:description]}".gsub(/[^\w]/i, '_')
        remote_path = test_driver.save_screenshot(test_name)
        file_name = remote_path.split('/').last
        local_path = "#{$current_run_dir}/#{file_name}"

        remote_file = test_driver.s3.create_s3_name(file_name)
        puts("remote_file is #{remote_file} and local_file is #{local_path}")
        expect(test_driver.s3._verify_upload(remote_file, local_path)).to be true
      end

      xit 'returns s3 screenshot url' do |example|
        test_name   = "#{example.metadata[:description]}".gsub(/[^\w]/i, '_')
        remote_path = test_driver.save_screenshot(test_name)

        aggregate_failures 'expectations' do
          expect(remote_path).to include "https://#{ENV['S3_ROOT_BUCKET']}.s3.amazonaws.com"
        end
      end

      xit 'also saves screenshot locally' do |example|
        test_name   = "#{example.metadata[:description]}".gsub(/[^\w]/i, '_')
        remote_path = test_driver.save_screenshot(test_name)
        file_name = remote_path.split('/').last
        local_path = "#{$current_run_dir}/#{file_name}"
        puts("remote_path is #{remote_path} and local_path is #{local_path}")

        expect(File.exist?(local_path)).to be true
      end
    end
  end

  describe 'cookies' do
    let(:cookie_url) {"#{mustadio}#{CookiePage::PAGE_NAME}"}
    let(:cookie_page) {CookiePage.new}
    let(:cookie_name) {"IAmJacksDefaultCookie"}
    let(:cookie_value) {"i_am_jacks_cookie_value"}
    let(:simplified_cookie) {{:name => cookie_name, :value => cookie_value}}

    before :all do
      Gridium.config.element_timeout = 2
    end

    before :each do
      test_driver.visit cookie_url
      cookie_page.refresh
    end

    after :each do
      test_driver.quit
    end

    after :all do
      Gridium.config.element_timeout = 15
    end

    it 'should get all cookies' do
      actual_cookies = cookie_page.get_all_cookies
      expected_cookies = test_driver.all_cookies.map {|x| {:name => x[:name], :value => x[:value]}}
      expect(actual_cookies).to eq expected_cookies
    end

    it 'should get a cookie by name' do
      actual_cookie = cookie_page.get_cookie(cookie_name)
      expected_cookie = test_driver.get_cookie(cookie_name).select {|k, v| [:name, :value].include? k }
      expect(actual_cookie).to eq expected_cookie
    end

    it 'should add a cookie ' do
      new_cookie = {:name => "first_rule",
                         :value => "do_not_talk_about_fight_club",
                         :expires => (Time.now.to_i + 5000),
                         :secure => false}
      expected_cookie = new_cookie.select {|k, v| [:name, :value].include? k }
      test_driver.add_cookie(new_cookie)
      actual_cookie = cookie_page.refresh.get_cookie(expected_cookie[:name])
      expect(actual_cookie).to eq expected_cookie
    end

    it 'should delete a cookie by name' do
      test_driver.delete_cookie("IAmJacksDefaultCookie")
      actual_cookies = cookie_page.refresh.get_all_cookies
      expect(actual_cookies).not_to include simplified_cookie
    end

    it 'should delete all cookies' do
      test_driver.delete_all_cookies
      expected_cookies = test_driver.all_cookies.map {|x| {:name => x[:name], :value => x[:value]}}
      actual_cookies = cookie_page.refresh.get_all_cookies
      expect(actual_cookies). to eq expected_cookies
    end
  end

  describe 'selenium logging' do
    after :each do
      test_driver.quit
    end

    it 'should log nothing when level is OFF' do
      expected_logs = {}
      actual_logs = {}
      gridium_config.selenium_log_level = 'OFF'
      #force browser logging to have a value
      test_driver.visit("http://localhost:8080")
      test_driver.driver.manage.logs.available_types.each do |log_type|
        actual_logs[log_type] = test_driver.driver.manage.logs.get(log_type)
        expected_logs[log_type] = []
      end
      expect(actual_logs).to eq expected_logs
    end

    it 'should log something when level is ALL' do
      expected_logs = {}
      actual_logs = {}
      gridium_config.selenium_log_level = 'ALL'
      #force browser logging to have a value
      test_driver.visit("http://localhost:8080")
      test_driver.driver.manage.logs.available_types.each do |log_type|
        actual_logs[log_type] = test_driver.driver.manage.logs.get(log_type)
        expected_logs[log_type] = []
      end
      expect(actual_logs.values).not_to be_empty
    end
  end

  describe 'alerts' do
    it 'should accept an alert' do
      test_driver.visit("#{mustadio}/alert")
      Element.new("trigger alert button", :id, "alert").click
      sleep 2
      expect {test_driver.driver.switch_to.alert.accept}.not_to raise_error
      sleep 2
    end
  end


  def create_new_element(name, by, locator)
    Element.new(name, by, locator)
  end
end
