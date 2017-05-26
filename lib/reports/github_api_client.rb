require 'faraday'
require 'json'
require 'logger'

module Reports
  class Error < StandardError; end
  class NonexistentUser < Error; end
  class RequestFailure < Error; end

  VALID_STATUS_CODES = [200, 302, 403, 404, 422]

  User = Struct.new(:name, :location, :public_repos)

  class GitHubAPIClient
    def initialize
      @logger = Logger.new(STDOUT)
      @logger.formatter = proc { |severity, datetime, program, message| message + "\n" }
    end

    def user_info(username)
      url = "https://api.github.com/users/#{username}"

      start_time = Time.now
      response = Faraday.get(url)
      duration = Time.now - start_time

      @logger.debug '-> %s %s %d (%.3f s)' % [url, 'GET', response.status, duration]

      raise RequestFailure, JSON.parse(response.body)['message'] unless VALID_STATUS_CODES.include?(response.status)
      raise NonexistentUser, "'#{username}' does not exist" if response.status == 404

      response_hash = JSON.parse(response.body)
      User.new(response_hash['name'], response_hash['location'], response_hash['public_repos'])
    end
  end

end
