require "faraday"
require "time"
require "reports/middleware/cache"

module Reports::Middleware
  RSpec.describe Cache do
    let(:stubs) { Faraday::Adapter::Test::Stubs.new }

    let(:conn) do
      Faraday.new do |builder|
        builder.use Cache
        builder.adapter :test, stubs
      end
    end

    let(:response_array) do
      headers = {"Cache-Control" => "max-age=300", "Date" => Time.new.httpdate}
      [200, headers, "hello"]
    end

    it "returns a previously cached response" do
      stubs.get("http://example.test") { [200, { 'Cache-Control' => 'public max-age=60', 'Date' => Time.now.httpdate }, "hello"] }
      conn.get("http://example.test")
      stubs.get("http://example.test") { [404, {}, "not found"] }

      response = conn.get "http://example.test"
      expect(response.status).to eql(200)
    end

    %w{post patch put}.each do |http_method|
      it "does not cache #{http_method} requests" do
        stubs.send(http_method, "http://example.test") { [200, {'Cache-Control' => 'public'}, "hello"] }
        conn.send(http_method, "http://example.test")
        stubs.send(http_method, "http://example.test") { [404, {}, "not found"] }

        response = conn.send(http_method, "http://example.test")
        expect(response.status).to eql(404)
      end
    end

    it "does not cache when the response doesn't have Cache-Controll header" do
      stubs.get("http://example.test") { [200, {}, "hello"] }
      conn.get("http://example.test")
      stubs.get("http://example.test") { [404, {}, "not found"] }

      response = conn.get "http://example.test"
      expect(response.status).to eql(404)
    end

    it "does not cache when the response Cache-Controll header has no-store value" do
      stubs.get("http://example.test") { [200, {'Cache-Control' => 'no-store'}, "hello"] }
      conn.get("http://example.test")
      stubs.get("http://example.test") { [404, {}, "not found"] }

      response = conn.get "http://example.test"
      expect(response.status).to eql(404)
    end

    it "does not use cached response when the response Cache-Controll header has no-cache value" do
      stubs.get("http://example.test") { [200, {'Cache-Control' => 'no-store'}, "hello"] }
      conn.get("http://example.test")
      stubs.get("http://example.test") { [404, {}, "not found"] }

      response = conn.get "http://example.test"
      expect(response.status).to eql(404)
    end

    it "does not use cached response when the response Cache-Controll header has must-revalidate value" do
      stubs.get("http://example.test") { [200, {'Cache-Control' => 'must-revalidate'}, "hello"] }
      conn.get("http://example.test")
      stubs.get("http://example.test") { [404, {}, "not found"] }

      response = conn.get "http://example.test"
      expect(response.status).to eql(404)
    end

    it "uses cached response when it doesn't exceeds max age" do
      stubs.get("http://example.test") { [200, { 'Cache-Control' => 'max-age=60', 'Date' => Time.now.httpdate}, "hello"] }
      conn.get("http://example.test")
      stubs.get("http://example.test") { [404, {}, "not found"] }

      response = conn.get "http://example.test"
      expect(response.status).to eql(200)
    end

    it "does not use cached response when it does exceeds max age" do
      stubs.get("http://example.test") { [200, { 'Cache-Control' => 'max-age=60', 'Date' => (Time.now - 2 * 60).httpdate }, "hello"] }

      conn.get("http://example.test")
      stubs.get("http://example.test") { [404, {}, "not found"] }

      response = conn.get "http://example.test"
      expect(response.status).to eql(404)
    end
  end
end
