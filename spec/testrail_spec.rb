require 'spec_helper'
require 'tmpdir'

describe GridiumTR do
  let(:gridium_config) { Gridium.config }
  let(:runname) { "Spec Run" }
  let(:rundesc) {"child_of_spec"}
  let(:empty_name) { "" }
  let(:empty_desc) { "" } #tab, carriage return, newline, space
  let(:tr) { Gridium::TestRail.new }
  let(:logger) { Log }

  describe 'Testrail configuration' do

      let(:url) {ENV['GRIDIUM_TR_URL']}
      let(:user) {ENV['GRIDIUM_TR_USER']}
      let(:pw) {ENV['GRIDIUM_TR_PW']}
      let(:pid) {ENV['GRIDIUM_TR_PID']}

    it 'Requires that GRIDIUM_TR_URL must exist' do
        expect(url).not_to be_nil
    end

    it 'Requires that GRIDIUM_TR_USER must exist' do
        expect(user).not_to be_nil
    end
    it 'Requires that GRIDIUM_TR_PW must exist' do
        expect(pw).not_to be_nil
    end
    it 'Requires that GRIDIUM_TR_PID must exist' do
        expect(pid).not_to be_nil
    end
  end

  describe 'TestRail Endpoint Tests' do

  end

end
