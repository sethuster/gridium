require 'net/http'
require 'net/https'
require 'uri'
require 'json'

module Gridium
	class TestRail
		ENV_ERROR = "Environment Variable not set!"

    #TestRail Statuses
    PASSED = 1
    BLOCKED = 2
    UNTESTED = 3
    RETEST = 4
    FAILED = 5
		#Retry Start
		RETRY = 5

		def initialize
      if Gridium.config.testrail
        @url = ENV['GRIDIUM_TR_URL'].empty? || ENV['GRIDIUM_TR_URL'].nil? ? ENV_ERROR : ENV['GRIDIUM_TR_URL'] + '/index.php?/api/v2/'
        @user = ENV['GRIDIUM_TR_USER'].empty? || ENV['GRIDIUM_TR_USER'].nil? ? ENV_ERROR : ENV['GRIDIUM_TR_USER']
        @password = ENV['GRIDIUM_TR_PW'].empty? || ENV['GRIDIUM_TR_PW'].nil? ? ENV_ERROR : ENV['GRIDIUM_TR_PW']
        @pid = ENV['GRIDIUM_TR_PID'].empty? || ENV['GRIDIUM_TR_PID'].nil? ? ENV_ERROR : ENV['GRIDIUM_TR_PID']
				@testcase_ids = Array.new
				@testcase_infos = Array.new
				@run_error = false
      end
		end

    def add_run(name, desc)
			id = 0
      if Gridium.config.testrail
        Log.debug("[GRIDIUM::TestRail] Creating Test Run: name: #{name} desc: #{desc}")
        if name.nil? || name.empty? then
          raise(ArgumentError, "Empty Run Name - Run name is required")
        end
        r = _send_request('POST', "#{@url}add_run/#{@pid}", {:name => name, :description => desc, :include_all => false})
        Log.debug("[GRIDIUM::TestRail] Run Added: #{r}")
				if r.key?('error') || r["id"].nil?
					@run_error = true
				else
					@runid = id = r["id"]
				end
      end
			return id
    end

		def add_case(rspec_test)
			added = false
			if Gridium.config.testrail
				Log.debug("[GRIDIUM::TestRail] Adding to list of TestRail Cases...")
				if rspec_test.nil? then
					Log.error("[GRIDIUM::TestRail] No test added to results. Turn of Gridium.config.testrail\n")
				end
				if rspec_test.exception
					status = FAILED
					message = rspec_test.exception.message
				else
					status = PASSED
					message = 'Test Passed.'
				end
				test_info = {:trid => rspec_test.metadata[:testrail_id], :status_id => status, :message => message}
				@testcase_infos.push(test_info) #This list contains the info for each case
				@testcase_ids.push(test_info[:trid]) #using this list to add list of cases to run
				added = true
			end
			return added
		end

		def close_run
			closed = false
			if Gridium.config.testrail && !@run_error
				Log.debug("[GRIDIUM::TestRail] Closing test runid: #{@runid}\n")
				unless @runid.nil?
					r = _send_request('POST', "#{@url}update_run/#{@runid}", {:case_ids => @testcase_ids})
					@testcase_infos.each do |tc|
						r = _send_request(
							'POST',
							"#{@url}add_result_for_case/#{@runid}/#{tc[:trid]}",
							status_id: tc[:status_id],
							comment: tc[:message]
							)
							sleep(0.25)
					end
					r = _send_request('POST', "#{@url}close_run/#{@runid}", nil)
					closed = true
				end
			end
			return closed
		end

    private
		def _send_request(method, uri, data)
			attempts = RETRY
			url = URI.parse(uri)
			Log.debug("[GRIDIUM::TestRail] Method: #{method} URL:#{uri} Data:#{data}")
			if method == 'POST'
				request = Net::HTTP::Post.new(url.path + '?' + url.query)
				request.body = JSON.dump(data)
			else
				request = Net::HTTP::Get.new(url.path + '?' + url.query)
			end
			request.basic_auth(@user, @password)
			request.add_field('Content-Type', 'application/json')

			conn = Net::HTTP.new(url.host, url.port)
			if url.scheme == 'https'
				conn.use_ssl = true
				conn.verify_mode = OpenSSL::SSL::VERIFY_NONE
			end
			begin
				Log.debug("[GRIDIUM::TestRail] Connection Attempt #{(RETRY - attempts) +1 }/#{RETRY}...")
				response = conn.request(request)
				if response.body && !response.body.empty?
					result = JSON.parse(response.body)
				else
					result = {}
				end

				if response.code != '200'
					if result && result.key?('error')
						error = '"' + result['error'] + '"'
					else
						error = 'No additional error message received'
					end
					Log.debug("[GRIDIUM::TestRail] Error with request: #{error}")
				end
			rescue SocketError => error
				Log.error("[GRIDIUM::TestRail] SocketError: #{error}")
				if attempts > 0
					attempts -= 1
					sleep 3
					retry
				end
				result = {error: "SocketError after #{RETRY} attempts.  See Error Log."}
			end

			result
		end
	end

end
