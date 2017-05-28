require 'json'

module Reports
  module Middleware
    class JSONParsing < Faraday::Middleware
      def call(env)
        @app.call(env).on_complete do |env|
          if env[:response_headers]['Content-Type'] =~ /application\/json/
            parse_json(env)
          end
        end
      end

      def parse_json(env)
        env[:raw_body] = env[:body]
        env[:body] = JSON.parse(env[:body]) if env[:body].size > 0
      end
    end
  end
end
