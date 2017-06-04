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
    option :forks, type: :boolean, desc: 'Include forks in stats', default: false

    def repositories(username)
      puts "Fetching repository statistics for #{username}..."

      client = GitHubAPIClient.new
      repos = client.repositories(username, forks: options[:forks])
      puts "#{username} has #{repos.count} public repos.\n\n"
      table_printer = TablePrinter.new(STDOUT)

      repos.each do |repo|
        table_printer.print(repo.languages, title: repo.full_name, humanize: true)
        # puts "#{repo.full_name}: #{repo.languages.join(', ')}"
        puts
      end

      stats = Hash.new(0)
        repos.each do |repo|
          repo.languages.each_pair do |language, bytes|
            stats[language] += bytes
          end
        end

      table_printer.print(stats, title: "Language Summary", humanize: true, total: true)
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

    desc 'gist DESCRIPTION FILENAME CONTENTS', 'Create a private Gist on GitHub'
    def gist(description, filename, contents)
      puts 'Creating a private Gist...'

      client = GitHubAPIClient.new
      gist_url = client.gist(description, filename, contents)

      puts "Your Gist is available at #{gist_url}."
    rescue Error => e
      puts "ERROR #{e.message}"
      exit 1
    end

    desc 'star_repo FULL_REPO_NAME', 'Star a repository'
    def star_repo(repo_name)
      puts "Starring #{repo_name}"
      client = GitHubAPIClient.new

      if client.repo_starred?(repo_name)
        puts "You have already starred #{repo_name}."
      else
        client.star_repo(repo_name)
        puts "You have starred #{repo_name}."
      end
    rescue Error => e
      puts "ERROR #{e.message}"
      exit 1
    end

    desc "unstar_repo FULL_REPO_NAME", "Unstar a repository"
    def unstar_repo(repo_name)
      puts "Unstarring #{repo_name}..."

      client = GitHubAPIClient.new

      if client.repo_starred?(repo_name)
        client.unstar_repo(repo_name)
        puts "You have unstarred #{repo_name}."
      else
        puts "You have not starred #{repo_name}."
      end
    rescue Error => error
      puts "ERROR #{error.message}"
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
