require "net/http"

class GithubIssues
  Error = Class.new(StandardError)

  API_VERSION = "2022-11-28"

  class << self
    def configured?
      token.present? && repo.present?
    end

    def create(title:, body:, labels: [])
      uri = URI("https://api.github.com/repos/#{repo}/issues")

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["Accept"] = "application/vnd.github+json"
      request["X-GitHub-Api-Version"] = API_VERSION
      request["Content-Type"] = "application/json"
      request.body = { title: title, body: body, labels: labels }.to_json

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }

      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "GitHub Issues API returned #{response.code}: #{response.body}"
      end

      response
    end

    private

    def token
      ENV["GITHUB_ISSUES_TOKEN"]
    end

    def repo
      ENV["GITHUB_ISSUES_REPO"]
    end
  end
end
