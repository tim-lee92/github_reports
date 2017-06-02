require 'rubygems'
require 'bundler/setup'
require 'thor'
require 'dotenv'

require 'reports/github_api_client'
require 'reports/table_printer'

Dotenv.load

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

    desc 'repositories USERNAME', 'Get a list of public repositories for a user'
    def repositories(username)
      puts "Fetching repository statistics for #{username}..."

      client = GitHubAPIClient.new
      repos = client.repositories(username)
      puts "#{username} has #{repos.count} public repos. \n\n"
      repos.each do |repo|
        puts "#{repo.full_name} - #{repo.url}"
      end
    rescue Error => e
      puts "ERROR #{e.message}"
    end

    desc 'activity USERNAME', 'Get a list of activities for a user'
    def activity(username)
      puts "Fetching activity summary for #{username}"
      client = GitHubAPIClient.new

      activities = client.activity(username)
      puts "Fetched #{activities.size} events.\n\n"
      print_activity_report(activities)
      # activities.each do |activity|
      #   puts "#{activity.type} - #{activity.repo_name}"
      # end
    rescue Error => e
      puts "ERROR #{e.message}"
      exit 1
    end

    private

    def print_activity_report(activities)
      table_printer = TablePrinter.new(STDOUT)
      activity_type_map = activities.each_with_object(Hash.new(0)) do |activity, counts|
        counts[activity.type] += 1
      end

      table_printer.print(activity_type_map, title: 'Activity Summary', total: true)
      push_activities = activities.select { |activity| activity.type == 'PushEvent' }
      push_activities_map = push_activities.each_with_object(Hash.new(0)) do |activity, counts|
        counts[activity.repo_name] += 1
      end

      puts
      table_printer.print(push_activities_map, title: 'Project Push Summary', total: true)
    end

    def client
      @client ||= GitHubAPIClient.new
    end

  end

end
