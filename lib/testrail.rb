require 'net/http'
require 'net/https'
require 'uri'
require 'json'
require 'dotenv'

module Gridium
	class TRClient
    Dotenv.load '~/shells/gridrail.env'
		URL = ENV['GRIDIUM_TR_URL']
		USER = ENV['GRIDIUM_TR_USER']
		PASS = ENV['GRIDIUM_TR_PW']
    PID = ENV['GRIDIUM_TR_PID']

		attr_accessor :user, :password, :pid

		def initialize
      @url = URL + '/index.php?/api/v2/'
      @user = USER
      @password = PASS
      @pid = PID

      puts @url
		end

    def add_run(name, desc)
      url = "add_run/#{@pid}"
      r = _send_request('POST', url, {:name => name, :description => desc})
      @runid = r["id"]
    end

    def close_run
      if @runid
        r = _send_request('POST', "close_run/#{@runid}", nil)
      end
    end



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
