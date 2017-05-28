module Reports
  module Middleware
    class Authentication < Faraday::Middleware
      def initialize(app)
        super(app)
        @token = ENV['GITHUB_TOKEN']
      end

      def call(env)
        env.request_headers['Authorization'] = "token #{@token}"
        @app.call(env).on_complete do |response_env|
          if response_env.status == 401
            raise BadCredentials, "Authentication Failed. Please set the 'GITHUB_TOKEN' environment variable to a valid Github access token."
          end
        end
      end
    end
  end
end
