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

		def initialize
      if Gridium.config.testrail
        @url = ENV['GRIDIUM_TR_URL'].empty? || ENV['GRIDIUM_TR_URL'].nil? ? ENV_ERROR : ENV['GRIDIUM_TR_URL'] + '/index.php?/api/v2/'
        @user = ENV['GRIDIUM_TR_USER'].empty? || ENV['GRIDIUM_TR_USER'].nil? ? ENV_ERROR : ENV['GRIDIUM_TR_USER']
        @password = ENV['GRIDIUM_TR_PW'].empty? || ENV['GRIDIUM_TR_PW'].nil? ? ENV_ERROR : ENV['GRIDIUM_TR_PW']
        @pid = ENV['GRIDIUM_TR_PID'].empty? || ENV['GRIDIUM_TR_PID'].nil? ? ENV_ERROR : ENV['GRIDIUM_TR_PID']
      end
		end

    def add_run(name, desc)
      if Gridium.config.testrail
        Log.debug("[GRIDIUM::TestRail] Creating Test Run: name: #{name} desc: #{desc}")
        if name.nil? || name.empty? then
          raise(ArgumentError, "Empty Run Name - Run name is required")
        end
        r = _send_request('POST', "add_run/#{@pid}", {:name => name, :description => desc, :include_all => false})
        Log.debug("Result: #{r}")
        unless r["id"].nil?
          @runid = r["id"]
        end
      end
    end

    def close_run
      if Gridium.config.testrail
        Log.debug("[GRIDIUM::TestRail] Closing RunID: #{@runid}")
        unless @runid.nil?
          r = _send_request('POST', "close_run/#{@runid}", nil)
        end
      end
    end

    def add_case(rspec_test)
      if Gridium.config.testrail
        Log.debug("[GRIDIUM::TestRail] Adding case: #{rspec_test} for RunID: #{@runid}")
        if rspec_test.nil? then
          raise(ArgumentError, "No test data was passed in.")
        end
        unless @runid.nil?
          r = _send_request('POST', "update_run/#{@runid}", {:case_ids => [rspec_test.metadata[:testrail_id]]})
          if rspec_test.exception
            status = FAILED
            message = rspec_test.exception.message
          else
            status = PASSED
            message = ''
          end
          r = _send_request(
            'POST',
            "add_result_for_case/#{@runid}/#{rspec_test.metadata[:testrail_id]}",
            status_id: status,
            comment: message
          )
        end
      end
    end


    private
		def _send_request(method, uri, data)
			url = URI.parse(@url + uri)
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
				raise APIError.new('TestRail API returned HTTP %s (%s)' %
					[response.code, error])
			end

			result
		end
	end

	class APIError < StandardError
	end
end
