require 'faraday'
require 'json'
require 'logger'

module Reports
  class Error < StandardError; end
  class NonexistentUser < Error; end
  class RequestFailure < Error; end
  class BadCredentials < Error; end

  VALID_STATUS_CODES = [200, 302, 401, 403, 404, 422]

  User = Struct.new(:name, :location, :public_repos)
  Repo = Struct.new(:full_name, :url)

  class GitHubAPIClient
    def initialize(token)
      @token = token
      @logger = Logger.new(STDOUT)
      @logger.formatter = proc { |severity, datetime, program, message| message + "\n" }
    end

    def user_info(username)
      headers = { Authorization: "token #{@token}" }
      url = "https://api.github.com/users/#{username}"

      start_time = Time.now
      response = Faraday.get(url, nil, headers)
      duration = Time.now - start_time

      @logger.debug '-> %s %s %d (%.3f s)' % [url, 'GET', response.status, duration]

      check_errors(JSON.parse(response.body)['message'], response.status, username)

      response_hash = JSON.parse(response.body)
      User.new(response_hash['name'], response_hash['location'], response_hash['public_repos'])
    end

    def repositories(username)
      headers = { Authorization: "token #{@token}" }
      url = "https://api.github.com/users/#{username}/repos"

      start_time = Time.now
      response = Faraday.get(url, nil, headers)
      duration = Time.now - start_time

      @logger.debug '-> %s %s %d (%.4f s)' % [url, 'GET', response.status, duration]

      response_array = JSON.parse(response.body)
      response_array.map! do |response_hash|
        Repo.new(response_hash['full_name'], response_hash['url'])
      end
    end

    private

    def check_errors(message, status, username=nil)
      raise RequestFailure, message unless VALID_STATUS_CODES.include?(status)
      raise NonexistentUser, "'#{username}' does not exist" if status == 404
      raise BadCredentials, message if status == 401
    end
  end
end
