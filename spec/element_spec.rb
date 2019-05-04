require 'spec_helper'
require 'securerandom'
# require 'pry'

describe Element do
  let(:test_element) { Element }
  let(:test_driver) { Driver }
  let(:logger) { Log }
  let(:test_element_verification) { ElementVerification }
  let(:the_internet_url) {'http://the-internet:5000'}

  before :all do
    Gridium.config.browser_source = :remote
    Gridium.config.target_environment = "http://hub:4444/wd/hub"
    Gridium.config.browser = :chrome
  end

  after :example do
    Driver.quit
  end

  describe '#to_s' do
    context 'with :css' do
      it 'returns element metadata' do
        expect(Element.new("Graph Container", :css, ".whoo-hah").to_s).to eq "'Graph Container' (By:css => '.whoo-hah')"
      end
    end

    context 'with :xpath' do
      it 'returns element metadata' do
        expect(Element.new("Graph Container", :xpath, "//*[@class='gotcha-all-in-check']").to_s).to eq "'Graph Container' (By:xpath => '//*[@class='gotcha-all-in-check']')"
      end
    end
  end

  context 'when element does not exist' do
    context 'with default element timeout' do
      let(:timeout_msg) { "timed out after #{Gridium.config.element_timeout} seconds" }

      it 'raises TimeOutError' do
        expect { Element.new("Unknown element", :css, ".invalid-css").click }.to \
          raise_error(Selenium::WebDriver::Error::TimeOutError, /#{timeout_msg}/)
      end

      it 'raises and adds Element metadata to error msg' do
        dne_elem = Element.new("Unknown element", :css, ".invalid-css")
        expect { dne_elem.click }.to \
          raise_error(Selenium::WebDriver::Error::TimeOutError, /\(By:css => '\.invalid-css'\)/)
      end
    end

    context 'with timeout' do
      let(:wait_timeout) { 5 }

      it 'timeouts within requested time in seconds' do
        msg = /timed out after #{wait_timeout} seconds/

        time = Benchmark.realtime do
          expect { Element.new("Unknown element", :css, ".invalid-css", timeout: wait_timeout).click }.to \
          raise_error(Selenium::WebDriver::Error::TimeOutError, msg)
        end

        expect(time).to be_within(3).of(wait_timeout), "Expected #{time} to be within 3 seconds of requested timeout '#{wait_timeout}'"
      end

      it 'raises and adds Element metadata to error msg' do
        dne_elem = Element.new("Unknown element", :css, ".invalid-css", timeout: wait_timeout)
        expect { dne_elem.click }.to \
          raise_error(Selenium::WebDriver::Error::TimeOutError, /\(By:css => '\.invalid-css'\)/)
      end
    end
  end

  describe '#verify' do
    xit 'verifies new element and logs it' do
      allow(logger).to receive(:debug)

      test_element.verify(nil)

      expect(test_element_verification).to receive(:new)
      expect(logger).to have_received(:debug).with('Verifying new element...')
    end
  end

  describe '#wait_until' do
    let(:page_countdown) {3}
    let(:wait_timeout) {4}
    let(:element_to_appear_id) {"will-appear"}
    let(:element_to_vanish_id) {"will-vanish"}
    before :each do
      test_driver.visit "http://mustadio:3000/wait?seconds=#{page_countdown}"
    end

    after :each do
      test_driver.quit
    end

    it 'quickly determines an element is visible' do
      appearing_div = Element.new("I am jack's appearing div", :id, element_to_appear_id)
      appearing_div.wait_until(timeout: wait_timeout).visible
    end

    it 'quickly determines an element is not visible' do
      skip("skip until wait_until.not.visible works")
      vanishing_div = Element.new("I am jack's disappearing div", :id, element_to_vanish_id)
      vanishing_div.wait_until(timeout: wait_timeout).not.visible
    end

    context 'when element does not exist' do
      context 'with explicit wait timeout' do
        it 'raises TimeOutError' do
          msg = /timed out after #{wait_timeout} seconds/
          expect { Element.new("Unknown element", :css, ".invalid-css").wait_until(timeout: wait_timeout).visible.click }.to \
            raise_error(Selenium::WebDriver::Error::TimeOutError, msg)
        end

        it 'timeouts within requested time in seconds' do
          time = Benchmark.realtime do
            msg = /timed out after #{wait_timeout} seconds/
            expect { Element.new("Unknown element", :css, ".invalid-css").wait_until(timeout: wait_timeout).visible.click }.to \
            raise_error(Selenium::WebDriver::Error::TimeOutError, msg)
          end

          expect(time).to be_within(3).of(wait_timeout), "Expected #{time} to be within 3 seconds of explicit wait timeout '#{wait_timeout}'"
        end
      end
    end

    context 'when element exists' do
      context 'with explicit wait timeout' do
        it 'raises TimeOutError on waiting to NOT be visible' do
          msg = /timed out after #{wait_timeout} seconds/
          expect { Element.new("Known element", :id, element_to_appear_id).wait_until(timeout: wait_timeout).not.visible }.to \
            raise_error(Selenium::WebDriver::Error::TimeOutError, msg)
        end

        it 'timeouts within requested time in seconds' do
          time = Benchmark.realtime do
            msg = /timed out after #{wait_timeout} seconds/
            expect { Element.new("Known element", :id, element_to_appear_id).wait_until(timeout: wait_timeout).not.visible }.to \
            raise_error(Selenium::WebDriver::Error::TimeOutError, msg)
          end

          expect(time).to be_within(3).of(wait_timeout), "Expected #{time} to be within 3 seconds of explicit wait timeout '#{wait_timeout}'"
        end
      end
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

  describe '#mouse_over / #hover_over' do
    let(:hover_url) { "http://mustadio:3000/hover"}
    let(:invisible_text) { "I am Jack's smirking div" }

    it 'can mouse_over' do
      test_driver.visit hover_url
      Page.new.find(:id, "hover-target").mouse_over
      expect(Page.has_text?(invisible_text, visible: true)).to be true
    end

    it 'can hover_over' do
      test_driver.visit hover_url
      Page.new.find(:id, "hover-target").hover_over
      expect(Page.has_text?(invisible_text, visible: true)).to be true
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
      expect {disabled.send_keys desired_text}.to  raise_error RuntimeError, expected_error
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
      expect {this_one.send(:field_empty_afterward?, desired_text)}.to  raise_error RuntimeError, expected_error
    end
  end

  describe '#displayed?' do
    let(:gridium_config) { Gridium.config }
    let(:wait) {Selenium::WebDriver::Wait.new :timeout => wait_timeout}
    let(:element_to_appear_id) {"will-appear"}
    let(:element_to_vanish_id) {"will-vanish"}
    let(:moment) {2}
    let(:page_countdown) {30}

    before :each do
      test_driver.visit "http://mustadio:3000/wait?seconds=#{page_countdown}"
      #small element_timeout so .displayed? doesn't take longer than the wait invoking it
      gridium_config.element_timeout = (moment / 2)
    end

    after :each do
      gridium_config.element_timeout = 15
      test_driver.quit
    end

    it 'should return true when the element is displayed' do
      visible_at_first = Element.new("I am jack's disappearing div", :id, element_to_vanish_id)
      expect(visible_at_first.displayed?).to eq true
    end

    it 'should return false when the element is not displayed' do
      visible_later = Element.new("I am jack's appearing div", :id, element_to_appear_id)
      expect(visible_later.displayed?).to eq false
    end

    context 'when awaiting the possible' do
      let(:page_countdown) {moment}
      let(:wait_timeout) {moment * 3}

      it 'wait until not #displayed? quickly determines an element is not visible' do
        vanishing_div = Element.new("I am jack's disappearing div", :id, element_to_vanish_id)
        await_disappearance = lambda { wait.until {!vanishing_div.displayed?(:timeout => moment)} }
        expect(await_disappearance).not_to raise_exception
      end

      it 'wait until #displayed? quickly determines an element is visible' do
        appearing_div = Element.new("I am jack's appearing div", :id, element_to_appear_id)
        await_appearance = lambda {wait.until {appearing_div.displayed?}}
        expect(await_appearance).not_to raise_exception
      end
    end

    context 'when awaiting the impossible' do
      let(:page_countdown) {moment * 3}
      let(:wait_timeout) {moment}

      it 'wait until not #displayed? eventually raises TimeOutError if an element remains visible' do
        vanishing_div = Element.new("I am jack's disappearing div", :id, element_to_vanish_id)
        await_disappearance = lambda { wait.until {!vanishing_div.displayed?(:timeout => moment)} }
        expect(await_disappearance).to raise_error(Selenium::WebDriver::Error::TimeOutError)
      end

      it 'wait until #displayed? eventually eventually raises TimeOutError if an element remains not visible' do
        appearing_div = Element.new("I am jack's appearing div", :id, element_to_appear_id)
        await_appearance = lambda {wait.until {appearing_div.displayed?}}
        expect(await_appearance).to raise_error(Selenium::WebDriver::Error::TimeOutError)
      end

    end
  end

  describe '#click' do
    let(:test_input_page)   { "http://mustadio:3000/fields" }
    let(:input_elem)        { Element.new("some input", :css, "[id=input_1]") }

    before :example do
      Driver.visit test_input_page
      input_elem.wait_until.visible

      allow(input_elem).to receive(:displayed?).and_return(true)
      allow(input_elem).to receive(:stale?).and_return(false)
      allow(input_elem.element).to receive(:enabled?).and_return(true)
      allow(input_elem.element).to receive(:click).and_raise(Selenium::WebDriver::Error::UnknownError, 'unknown error: unable to click element at point (blah, blah)')
      allow(Log).to receive(:error)
      allow(Log).to receive(:warn)
    end

    it 'should retry on click exception' do
      aggregate_failures 'expectations' do
        expect {input_elem.click}.to raise_error(Selenium::WebDriver::Error::UnknownError, /unknown error: unable to click element at point/)
        expect(Log).to have_received(:error).with(/\[GRIDIUM::Element\] Click Exception unknown error: unable to click element at point/)
        expect(Log).to have_received(:warn).with(/Click Exception retrying/).at_least(3).times
      end
    end
  end

  describe '#drag_to' do
    let(:url)           { "#{the_internet_url}/drag_and_drop" }
    let(:source)        { Element.new('Source', :css, '#column-a') }
    let(:target)        { Element.new('Target', :css, '#column-b') }
    let(:xpath_elem_a)  { Element.new('xpath elem a', :xpath, "//*[@id='column-a']")}
    let(:xpath_elem_b)  { Element.new('xpath elem b', :xpath, "//*[@id='column-b']")}

    before :example do
      allow(Log).to receive(:debug)
      allow(Log).to receive(:error)

      Driver.visit url

      aggregate_failures 'pre drag' do
        expect(source.text).to eq('A')
        expect(target.text).to eq('B')
      end
    end

    it 'drags source element to target' do
      source.wait_until.visible.drag_to(target)

      aggregate_failures 'post drag' do
        expect(source.text).to eq('B')
        expect(target.text).to eq('A')
        expect(Log).to have_received(:debug).with(/\[GRIDIUM::Element\] Dragging/)
      end
    end

    it 'raises error when dragging from source xpath locator' do
      aggregate_failures 'expectations' do
        expect {xpath_elem_a.wait_until.visible.drag_to(target)}.to raise_error(Gridium::InvalidTypeError, /source element selector must be ':css'/)
      end
    end

    it 'raises error when dragging to target xpath locator' do
      aggregate_failures 'expectations' do
        expect {source.wait_until.visible.drag_to(xpath_elem_b)}.to raise_error(Gridium::InvalidTypeError, /target element selector must be ':css'/)
      end
    end
  end

  context 'with attributes' do
    let(:url)                   { "#{the_internet_url}/drag_and_drop" }
    let(:css_elem_a)            { Element.new('css elem a', :css, '#column-a') }
    let(:xpath_elem_a)          { Element.new('xpath elem a', :xpath, "//*[@id='column-a']")}
    let(:class_value)           { 'column' }
    let(:new_class_value)       { 'something-something-dark-side' }

    before :example do
      allow(Log).to receive(:warn)
      allow(Log).to receive(:debug)

      Driver.visit url
    end

    describe '#attribute' do
      it 'retrieves \'class\' attribute from an element found with css' do
        expect(css_elem_a.attribute('class')).to eq class_value
      end

      it 'retrieves \'class\' attribute from an element found with xpath' do
        expect(xpath_elem_a.attribute('class')).to eq class_value
      end
    end

    describe '#set_attribute' do
      context 'with element having an #id attribute' do
        it 'sets new \'class\' attribute via JScript, on element found with css' do
          css_elem_a.set_attribute('class', new_class_value)

          aggregate_failures 'expectations' do
            expect(css_elem_a.attribute('class')).to eq new_class_value
            expect(Log).to have_received(:debug).with(/\[GRIDIUM::Element\] setting element attribute 'class' to '#{new_class_value}'/)
          end
        end

        it 'sets new \'class\' attribute via JScript, on element found with xpath' do
          xpath_elem_a.set_attribute('class', new_class_value)

          aggregate_failures 'expectations' do
            expect(xpath_elem_a.attribute('class')).to eq new_class_value
            expect(Log).to have_received(:debug).with(/\[GRIDIUM::Element\] setting element attribute 'class' to '#{new_class_value}'/)
          end
        end
      end

      context 'with element not having an #id attribute' do
        it 'silently fails and logs a message' do
          Page.new.find(:xpath, "//a[contains(@href,'elementalselenium')]").set_attribute('class', new_class_value)
          expect(Log).to have_received(:warn).with(/does not have an 'id'/)
        end
      end
    end
  end
end
