require_relative 'spec_helper'

describe TestRail do
  let(:gridium_config) { Gridium.config }
  let(:runname) { "Spec Run" }
  let(:rundesc) {"child_of_spec"}
  let(:empty_name) { "" }
  let(:empty_result) { "" }
  let(:tr) { Gridium::TestRail.new }
  let(:logger) { Log }

  before :all do
    @tr = Gridium::TestRail.new
  end

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
    it 'Can add Run' do
      id = @tr.add_run("Gridium Unit Test: #{Time.now.to_i}", "Valid Description")
      expect(id).to be > 0
    end
    it 'Can Add a Success Case to Run', testrail_id: 13313764 do |example|
      r = @tr.add_case(example)
      expect(r).to be true
    end
    it 'Can Close Run' do
      c = @tr.close_run
      expect(c).to be true
    end
  end

  describe 'Bad host name tests' do
    it 'Retries multiple times' do
      expect(logger).to receive(:debug).at_least(5).times

      tr.send(:_send_request, "GET", "http://obviously.fake.fart/index.php?/api/v2/farts", {bad: 'data'})
    end
    it 'Does not attempt to close invalid run' do
      bad_tr = Gridium::TestRail.new
      bad_tr.instance_variable_set(:@url, "http://obviously.fake.fart/index.php?/api/farts")
      id = bad_tr.add_run("This should not display", "Anywhere")
      expect(id).to be 0
      expect(bad_tr.instance_variable_get(:@run_error)).to be true
      r = bad_tr.close_run
      expect(r).to be false
    end
  end

end
