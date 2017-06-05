require 'vcr_helper'
require 'sinatra/base'
require 'webmock/rspec'
require 'reports/github_api_client'

class FakeGitHub < Sinatra::Base
  attr_reader :gists

  def initialize
    super
    @gists = []
  end

  post '/gists' do
    content_type :json
    request_body = JSON.parse(request.body.read)
    if request_body['files'].any? { |name, hash| hash['content'] == '' }
      status 422
      { message: 'Validation Failed!' }.to_json
    else
      status 201
      @gists << request_body
      {html_url: "https://gist.github.com/username/abcdefg12345678"}.to_json
    end
  end
end

module Reports
  RSpec.describe GitHubAPIClient, remote: true do
    describe '#user_info' do
      it 'fetches info for a user' do
        client = GitHubAPIClient.new
        data = client.user_info('octocat')
        expect(data.name).to be_instance_of(String)
        expect(data.location).to be_instance_of(String)
        expect(data.public_repos).to be_instance_of(Fixnum)
      end

      it 'raises an exception when a user does not exist' do
        client = GitHubAPIClient.new
        expect { client.user_info('hufwhfhwonewf') }.to raise_error(NonexistentUser)
      end
    end
  end
end
