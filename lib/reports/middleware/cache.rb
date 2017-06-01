module Reports
  module Middleware
    class Cache < Faraday::Middleware
      def initialize(app, storage)
        super(app)
        @app = app
        @storage = storage
      end

      def call(env)
        key = env.url.to_s
        cached_response = @storage.read(key)

        if cached_response
          if !expired?(cached_response)
            return cached_response if !(cached_response.headers['Cache-Control'] == 'no-cache' || cached_response.headers['Cache-Control'] == 'must-revalidate')
          else
            env.request_headers['If-None-Match'] = cached_response.headers['ETag']
          end
        end

        response = @app.call(env)
        response.on_complete do |response_env|
          if cachable_response?(response_env)
            if response.status == 304
              cached_response = @storage.read(key)
              cached_response.headers['Date'] = response.headers['Date']
              @storage.write(key, cached_response)

              response.env.update(cached_response.env)
            else
              @storage.write(key, response)
            end
          end
        end

        response
      end

      private

      def cachable_response?(env)
        env.method == :get && env.response_headers['Cache-Control'] && !env.response_headers['Cache-Control'].include?('no-store')
      end

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
