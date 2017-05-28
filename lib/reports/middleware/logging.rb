require 'logger'

module Reports
  module Middleware
    class Logging < Faraday::Middleware
      def initialize(app)
        super(app)
        @logger = Logger.new(STDOUT)
        @logger.formatter = proc { |severity, datetime, program, message| message + "\n" }
      end

      def call(env)
        start_time = Time.new
        @app.call(env).on_complete do
          duration = Time.new - start_time
          url, method, status = env.url.to_s, env.method, env.status
          @logger.debug '-> %s %s %d (%.3f s)' % [url, method.to_s.upcase, status, duration]
        end
      end
    end
  end
end
