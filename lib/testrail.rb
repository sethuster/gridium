require 'net/http'
require 'net/https'
require 'uri'
require 'json'

module Gridium
	class TestRail
		ENV_ERROR = "Environment Variable not set!"

		def initialize
      if Gridium.config.testrail
        @url = ENV['GRIDIUM_TR_URL'].empty? || ENV['GRIDIUM_TR_URL'].nil? ? ENV_ERROR : ENV['GRIDIUM_TR_URL'] + '/index.php?/api/v2/'
        @user = ENV['GRIDIUM_TR_USER'].empty? || ENV['GRIDIUM_TR_USER'].nil? ? ENV_ERROR : ENV['GRIDIUM_TR_USER']
        @password = ENV['GRIDIUM_TR_PW'].empty? || ENV['GRIDIUM_TR_PW'].nil? ? ENV_ERROR : ENV['GRIDIUM_TR_PW']
        @pid = ENV['GRIDIUM_TR_PID'].empty? || ENV['GRIDIUM_TR_PID'].nil? ? ENV_ERROR : ENV['GRIDIUM_TR_PID']
				@config = {:pass => 1, :blocked => 2, :untested => 3, :retest => 4, :fail => 5}
				@retry_attempts = 5
				@time_between_retries = 3
				@tc_results = Array.new
				@tc_ids = Array.new
				@run_info = {:id => 0 ,:error => false, :include_all => false}
      end
		end

		# Creates a new test Run in your TestRail instance.
		#
		# @param name [String] the name of the test run. Error text will be added if an error occurs
		# @param desc [String] a description of the run being added. Error text will be added if an error occurs
		# @return [int] The run ID of the created run or zero if no run created.
    def add_run(name, desc)
      if Gridium.config.testrail
        Log.debug("[GRIDIUM::TestRail] Creating Test Run: name: #{name} desc: #{desc}")
        if name.nil? || name.empty? then
          @run_info[:error] = true
				else
					@run_info[:name] = name
					@run_info[:desc] = desc
        end
        r = _send_request('POST', "#{@url}add_run/#{@pid}", @run_info)
				if r.key?('error') || r["id"].nil?
					@run_info[:error] = true
				else
					@run_info[:id] = r["id"]
					Log.debug("[GRIDIUM::TestRail] Run Added: #{r}")
				end
      end
			return @run_info[:id]
    end

		# Adds determines what the result of the test is and adds information to various arrays for processing during closing.
		#
		# @param rspec_test [RSpec::Example] the example provided by RSpec
		# @return [bool] determine if case was added or not
		def add_case(rspec_test)
			added = false
			if Gridium.config.testrail
				Log.debug("[GRIDIUM::TestRail] Adding to list of TestRail Cases...")
				if rspec_test.nil? then
					Log.error("[GRIDIUM::TestRail] No test added to results. Turn of Gridium.config.testrail\n")
				end
				if rspec_test.exception
					status = @config[:fail]
					message = rspec_test.exception.message
				else
					status = @config[:pass]
					message = 'Test Passed.'
				end
				test_info = {:case_id => rspec_test.metadata[:testrail_id], :status_id => status, :comment => message}
				@tc_results.push(test_info)
				@tc_ids.push(test_info[:case_id])
				added = true
			end
			return added
		end

		# Updates the existing test run with test cases and results.  Adds error text for missing test cases if needed. Closes the run as long as it exists.
		#
		# @return [bool] if the run was closed or not
		def close_run
			closed = false
			if Gridium.config.testrail && !@run_info[:error]
				Log.debug("[GRIDIUM::TestRail] Closing test runid: #{@run_info[:id]}\n")
				r = _send_request('POST', "#{@url}update_run/#{@run_info[:id]}", {:case_ids => @tc_ids})
				Log.debug("[GRIDIUM::TestRail] UPDATE RUN: #{r}")
				sleep 0.25
				r = _send_request('POST', "#{@url}add_results_for_cases/#{@run_info[:id]}", {results: @tc_results})
				Log.debug("[GRIDIUM::TestRail] ADD RESULTS: #{r}")
				sleep 0.25
				Log.debug("#{r.class}")
				if r.is_a?(Hash)
					r = _send_request('POST', "#{@url}update_run/#{@run_info[:id]}", {:name => "ER:#{@run_info[:name]}", :description => "#{@run_info[:desc]}\nThe following was returned when adding cases: #{r}"})
					Log.warn("[GRIDIUM::TestRail] ERROR: #{r}")
					sleep 0.25
				end
				r = _send_request('POST', "#{@url}close_run/#{@run_info[:id]}", nil)
				Log.debug("[GRIDIUM::TestRail] CLOSE RUN: #{r}")
				closed = true
			end
			return closed
		end

    private
		def _send_request(method, uri, data)
			attempts = @retry_attempts
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
					Log.error("[GRIDIUM::TestRail] #{response.code} - Error with request: #{error}")
				end
			rescue SocketError => error
				Log.warn("[GRIDIUM::TestRail] SocketError - Retrying....")
				if attempts > 0
					attempts -= 1
					sleep @time_between_retries
					retry
				end
				Log.error("[GRIDIUM::TestRail] Socket Error after numerous attempts. Error: #{error}")
				result = {error: "SocketError after #{@retry_attempts} attempts.  See Error Log."}
			end

			result
		end
	end

end
