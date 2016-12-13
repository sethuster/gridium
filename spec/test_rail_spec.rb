require 'spec_helper'

# RSpec::Testrail::MonkeyPatch.init url: 'https://sendgrid.testrail.com',
#                                     user: 'qe-automation@sendgrid.com',
#                                     password: 'febHLoGyEyVLGHz7B5GX-/Aq0E8Fdcq6Ri6IkQhOe',
#                                     project_id: 69,
#                                     suite_id: 71,
#                                     run_name: `git rev-parse --abbrev-ref HEAD`.strip,
#                                     run_description: `git rev-parse HEAD`.strip,
#                                     debug_mode: true

describe GridiumTestRail do
  let(:gridium_config) {Gridium.config}


  describe 'TestRail Setup' do
    it 'will fail without TR Url' do
      
    end

    it 'will fail without TR user' do

    end

    it 'will fail without TR password' do

    end

    it 'will fail without TR pid' do

    end

    it 'will succeed with required fields' do

    end
  end
end
