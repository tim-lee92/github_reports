module Reports
  module Middleware
    class Cache < Faraday::Middleware
      def initialize(app)
        super(app)
        @app = app
        @storage = {}
      end

      def call(env)
        key = env.url.to_s
        cached_response = @storage[key]

        if cached_response && !(cached_response.headers['Cache-Control'].include?('no-cache') || cached_response.headers['Cache-Control'].include?('must-revalidate')) && !expired?(cached_response)
          return cached_response
        end

        response = @app.call(env)
        return response unless env.method == :get

        response.on_complete do |response_env|
          cache_control_header = response_env.response_headers['Cache-Control']
          if cache_control_header && !cache_control_header.include?('no-store')
            @storage[key] = response
          end
        end

        response
      end

      private

      def response_age(cached_response)
        date = cached_response.env['response_headers']['Date']
        time = Time.httpdate(date) if date
        Time.now - time if time
      end

      def expired?(cached_response)
        age = response_age(cached_response)
        max_age_match = cached_response.env.response_headers['Cache-Control'].match(/max\-age\=(\d+)/)
        max_age = max_age_match[1].to_i if max_age_match

        if age && max_age
          age >= max_age
        end
      end
    end
  end
end
