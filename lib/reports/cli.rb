require 'rubygems'
require 'bundler/setup'
require 'thor'

require 'reports/github_api_client'
require 'reports/table_printer'

module Reports

  class CLI < Thor

    desc "console", "Open an RB session with all dependencies loaded and API defined."
    def console
      require 'irb'
      ARGV.clear
      IRB.start
    end

    desc 'user_info USERNAME', 'Get information for a user...'
    def user_info(username)
      puts "Getting info for #{username}"

      client = GitHubAPIClient.new
      user = client.user_info(username)
      puts "name: #{user['name']}"
      puts "location: #{user['location']}"
      puts "public repos: #{user['public_repos']}"
    rescue Error => e
      puts "ERROR #{e.message}"
      exit 1
    end

    private

    def client
      @client ||= GitHubAPIClient.new
    end

  end

end
