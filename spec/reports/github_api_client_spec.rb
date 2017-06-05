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
  RSpec.describe GitHubAPIClient do
    describe '#user_info', vcr: true do
      it 'fetches info for a user' do
        client = GitHubAPIClient.new
        data = client.user_info('octocat')
        expect(data.name).to eq('The Octocat')
        expect(data.location).to eq('San Francisco')
        expect(data.public_repos).to eq(7)
      end

      it 'raises an exception when a user does not exist', vcr: true do
        client = GitHubAPIClient.new
        expect { client.user_info('hufwhfhwonewf') }.to raise_error(NonexistentUser)
      end
    end

    describe '#gist' do
      let(:fake_server) { FakeGitHub.new! }

      before(:each) do
        stub_request(:any, /api.github.com/).to_rack(fake_server)
      end

      it 'creates a private gist' do
        client = GitHubAPIClient.new
        url = client.gist('a quick gist', 'hello.rb', 'puts \'hello\'')

        expect(url).to eq('https://gist.github.com/username/abcdefg12345678')
        expect(fake_server.gists.first).to eq({
          'description' => 'a quick gist',
          'public' => false,
          'files' => {
            'hello.rb' => {
              'content' => 'puts \'hello\''
            }
          }
        })
      end

      it "raises an exception when gist creation fails" do
        client = GitHubAPIClient.new
        expect(->{
          client.gist("a quick gist", "hello.rb", "")
        }).to raise_error(GistCreationFailure)
      end
    end
  end
end
