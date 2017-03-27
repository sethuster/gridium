require 'spec_helper'
require 'securerandom'
# require 'pry'

describe Element do
  let(:test_element) { Element }
  let(:logger) { Log }
  let(:test_element_verification) { ElementVerification }
  let(:the_internet_url) {'http://the-internet:5000'}

  before :all do
    Gridium.config.browser_source = :remote
    Gridium.config.target_environment = "http://hub:4444/wd/hub"
    Gridium.config.browser = :chrome
  end

  after :each do
    Driver.quit
  end

  describe '#verify' do
    xit 'verifies new element and logs it' do
      allow(logger).to receive(:debug)

      test_element.verify(nil)

      expect(test_element_verification).to receive(:new)
      expect(logger).to have_received(:debug).with('Verifying new element...')
    end
  end

  describe 'highlighting' do
    let(:test_input_page) { "http://mustadio:3000/fields" }

    it 'should highlight disabled elements' do
      Driver.visit test_input_page
      disabled = Element.new "disabled field", :css, "[id=\"input_disabled\"]"
      expect {ElementExtensions.highlight(disabled)}.not_to raise_error
    end
  end

  describe '#css_value' do
    it 'should return a css value' do
      Driver.visit the_internet_url
      header = Element.new('internet header', :css, "div[id=\"content\"] > h1")
      actual_box_sizing = header.css_value("box-sizing")
      expected_box_sizing = 'border-box'
      expect(actual_box_sizing).to eq expected_box_sizing
    end
  end

  describe '#location_once_scrolled_into_view' do
    let(:long_page_url) {the_internet_url + "/large"}
    it 'should be different than the absolute location' do
      Driver.visit long_page_url
      footer = Element.new('internet footer', :id, 'page-footer')
      absolute_location = footer.location
      scrolled_location = footer.location_once_scrolled_into_view
      expect(scrolled_location).not_to eq absolute_location
    end
  end

  describe 'child elements' do
    it '#find_element should return a gridium element' do
      Driver.visit the_internet_url
      content = Element.new("internet content", :id, "content")
      actual_header_element_class = content.find_element(:tag_name, "h1").class
      expected_header_element_class = content.class
      expect(actual_header_element_class).to eq expected_header_element_class
    end

    it '#find_elements should return a list of gridium elements' do
      Driver.visit the_internet_url
      content = Element.new("internet content", :id, "content")
      nav_links = content.find_elements(:css, "ul > li > a")
      actual_nav_element_classes = (nav_links.map {|_| _.class}).uniq
      expected_nav_element_classes = [content.class]
      expect(actual_nav_element_classes).to match_array(expected_nav_element_classes)
    end
  end

  describe 'text input' do
    let(:test_input_page) { "http://mustadio:3000/fields" }

    after :each do
      Driver.quit
    end

    it 'should continue to work after many attempts' do
      (1..5).each do
        Driver.visit test_input_page
        (1..11).each do |i|
          expected_text = "#{i}_#{SecureRandom.uuid}"
          expected_selector = "[id=\"input_#{i}\"]"
          this_one = Element.new expected_selector, :css, expected_selector
          this_one.send_keys expected_text
        end
        submit = Element.new "submit button", :css, "[id=\"input_submit\"]"
        submit.click
      end
    end

    it 'should raise browser error on disabled inputs' do
      desired_text = "#{SecureRandom.uuid}"
      expected_error = "Browser Error: tried to enter [\"#{desired_text}\"] but the input is disabled"
      Driver.visit test_input_page
      disabled = Element.new "disabled field", :css, "[id=\"input_disabled\"]"
      expect {disabled.send_keys desired_text}.to  raise_error error=RuntimeError, message=expected_error
    end

    it 'send_keys should replace preexisting values' do
      Driver.visit test_input_page
      expected_selector = "[id=\"input_1\"]"
      this_one = Element.new expected_selector, :css, expected_selector
      original_text = this_one.value
      this_one.send_keys "#{SecureRandom.uuid}"
      new_text = this_one.value
      expect(new_text).not_to eq original_text
    end

    it 'should be able to use text= as alias to send_keys' do
      Driver.visit test_input_page
      expected_selector = "[id=\"input_1\"]"
      this_one = Element.new expected_selector, :css, expected_selector
      original_text = this_one.value
      this_one.text= "#{SecureRandom.uuid}"
      new_text = this_one.value
      expect(new_text).not_to eq original_text
    end

    it 'append_keys should add to preexisting values' do
      Driver.visit test_input_page
      expected_selector = "[id=\"input_1\"]"
      this_one = Element.new expected_selector, :css, expected_selector
      original_text = this_one.value
      text_to_append = "#{SecureRandom.uuid}"
      this_one.append_keys text_to_append
      new_text = this_one.value
      expect(new_text).to eq (original_text + text_to_append)
    end

    it 'should be able to send printable symbols for keys' do
      skip "This is officially broken on the Selenium Server 3.1.0: https://github.com/SeleniumHQ/selenium/issues/2704"
      Driver.visit test_input_page
      expected_selector = "[id=\"input_1\"]"
      this_one = Element.new expected_selector, :css, expected_selector
      new_text = "#{SecureRandom.uuid}"
      this_one.send_keys new_text, :space, "1"
      actual_text = this_one.value
      expect(actual_text).to eq (new_text + " " + "1")
    end

    it 'should be able to send return symbol for keys' do
      Driver.visit test_input_page
      expected_selector = "[id=\"input_1\"]"
      this_one = Element.new expected_selector, :css, expected_selector
      initial_text = this_one.value #foo
      this_one.clear
      this_one.send_keys :enter
      new_text = this_one.value #foo again
      expect(new_text).to eq (initial_text)
    end

    it 'should be able to send tab symbol for keys' do
      Driver.visit test_input_page
      first_selector = "[id=\"input_1\"]"
      second_selector = "[id=\"input_2\"]"
      this_one = Element.new first_selector, :css, first_selector
      next_one = Driver.driver.find_element(:css => second_selector)
      new_text = "#{SecureRandom.uuid}"
      this_one.send_keys new_text, :tab
      focused = Driver.driver.switch_to.active_element #might fail
      Log.debug "focused is #{focused} next one is #{next_one}"
      expect(next_one).to eq (focused)
    end

    it 'should be able to accept numbers' do
      Driver.visit test_input_page
      expected_selector = "[id=\"input_1\"]"
      this_one = Element.new expected_selector, :css, expected_selector
      new_text = 1
      this_one.send_keys new_text
      actual_text = this_one.value
      expect(actual_text).to eq ("1")
    end

    it 'send_keys should be able to accept an empty string' do
      Driver.visit test_input_page
      expected_selector = "[id=\"input_1\"]"
      this_one = Element.new expected_selector, :css, expected_selector
      new_text = ""
      this_one.send_keys new_text
      actual_text = this_one.value
      expect(actual_text).to eq (new_text)
    end

    it 'should not clear the field when sending only symbols' do
      Driver.visit test_input_page
      expected_selector = "[id=\"input_1\"]"
      expected_text = "wubbalubbadubdub"
      this_one = Element.new expected_selector, :css, expected_selector
      this_one.send_keys expected_text
      this_one.send_keys :tab
      actual_text = this_one.value
      expect(actual_text).to eq expected_text
    end

    it 'field_empty_afterward? should raise browser error on finding an empty field' do
      desired_text = "#{SecureRandom.uuid}"
      expected_error = "Browser Error: tried to input [\"#{desired_text}\"] but found an empty string afterward: "
      Driver.visit test_input_page
      expected_selector = "[id=\"input_1\"]"
      this_one = Element.new expected_selector, :css, expected_selector
      this_one.append_keys desired_text
      this_one.clear
      expect {this_one.send(:field_empty_afterward?, desired_text)}.to  raise_error error=RuntimeError, message=expected_error
    end

  end
end
