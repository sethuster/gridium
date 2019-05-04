require_relative 'spec_helper'
# require 'pry'

describe Gridium do
  describe 'Gridium' do
    let(:gridium_version) { Gridium::VERSION }
    let(:gridium_configuration) { Gridium.config }

    it 'sets a version number for the gem' do
      expect(gridium_version).not_to be nil
    end

    context 'loading configs at initialization' do
      it 'assigns default configs' do
        expect(gridium_configuration.report_dir).to eq "./test_results"
        expect(gridium_configuration.browser_source).to eq(:remote)
        expect(gridium_configuration.target_environment).to eq('http://hub:4444/wd/hub')
        expect(gridium_configuration.browser).to eq(:chrome)
        expect(gridium_configuration.page_load_timeout).to eq(15)
        expect(gridium_configuration.page_load_retries).to eq(0)
        expect(gridium_configuration.element_timeout).to eq(15)
        expect(gridium_configuration.visible_elements_only).to be(true)
        expect(gridium_configuration.log_level).to eq(:error)
        expect(gridium_configuration.highlight_verifications).to be(true)
        expect(gridium_configuration.highlight_duration).to eq(0.1)
        expect(gridium_configuration.screenshot_on_failure).to be(false)
      end
    end
  end
end
