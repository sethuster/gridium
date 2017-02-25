require_relative 'spec_helper'

describe TestRail do
  let(:gridium_config) { Gridium.config }
  let(:runname) { "Spec Run" }
  let(:rundesc) {"child_of_spec"}
  let(:empty_name) { "" }
  let(:empty_result) { "" }
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

  # describe 'TestRail Endpoint Tests' do
  #   it 'Can add Run' do
  #     tr.add_run("Valid Name", "Valid Description")
  #   end
  #   it 'Fail to add case without Name' do
  #     empty_string_call = lambda {tr.add_run empty_name}
  #     expect(&empty_string_call).to raise_error(ArgumentError)
  #   end
  #   it 'Can Close Run' do
  #     tr.close_run
  #   end
  #   it 'Can Add Case to Run' do |example|
  #     tr.add_case(example)
  #   end
  #   xit 'Fail to add result with empty set' do
  #     empty_result_call = lambda {tr.add_case nil}
  #     expect(&empty_result_call).to raise_error(ArgumentError)
  #   end
  # end

  describe 'Bad host name tests' do
    it 'Retries multiple times' do
      expect(logger).to receive(:debug).at_least(5).times
      tr.send(:_send_request, "GET", "farts/get", {bad: 'data'})

    end
    it 'does raise exception after failure' do

    end
  end

end
