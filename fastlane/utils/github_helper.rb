# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module GithubHelper
  GITHUB_API_BASE = "https://api.github.com"
  REPO_PATTERN    = %r{github\.com[:/](.+?)(\.git)?$}

  def self.current_branch
    ENV['GITHUB_SHA'] ||
      ENV['GITHUB_HEAD_REF'] ||
      ENV['GITHUB_REF_NAME'] ||
      Fastlane::Actions.sh("git rev-parse --abbrev-ref HEAD").strip
  end

  def self.current_repo
    return ENV['GITHUB_REPOSITORY'] if ENV['GITHUB_REPOSITORY']

    url = Fastlane::Actions.sh("git config --get remote.origin.url").strip
    return Regexp.last_match(1) if url =~ REPO_PATTERN

    Fastlane::UI.user_error!("Repository name could not be determined")
  end

  def self.release_notes(target_repo: current_repo, base_branch: current_branch, per_page: 1000)
    params = {
      state: "closed",
      base: base_branch,
      sort: "updated",
      direction: "desc",
      per_page: per_page
    }

    data = github_get("/repos/#{target_repo}/pulls", params)

    data.map { |pr| "\n#{pr['title']} - ##{pr['number']} - @#{pr['user']['login']}" }.join
  end

  def self.create_release(platform: :ios, version: '0.0.1', build_number: 0, release_notes: '', upload_assets: [])
    tag_name = "#{platform == :ios ? '🍏' : '🤖'}-v#{version}_#{build_number}"
    
    # set_github_release does not throw an error if it fails (e.g. tag already exists)
    # It just prints to the log and returns nil.
    release_result = Fastlane::Actions::SetGithubReleaseAction.run(
      server_url: GITHUB_API_BASE,
      repository_name: current_repo,
      api_bearer: ENV["GITHUB_TOKEN"],
      name: "#{platform == :ios ? '🍏' : '🤖'} v#{version} (#{build_number})",
      tag_name: tag_name,
      description: release_notes,
      commitish: current_branch,
      upload_assets: upload_assets,
      is_draft: false,
      is_prerelease: false,
      is_generate_release_notes: false,
    )

    if release_result
      # Release created successfully
      return release_result
    end

    # If it reached here, release_result is nil (meaning it already existed or failed silently)
    Fastlane::UI.important("Could not create GitHub release (it might already exist). Fetching existing release: #{tag_name}...")
    download_release_assets(tag_name: tag_name, platform: platform)
  end

  # Fetches an existing release by tag and downloads its assets
  def self.download_release_assets(tag_name:, platform:)
    begin
      encoded_tag_name = URI.encode_www_form_component(tag_name)
      existing_release = github_get("/repos/#{current_repo}/releases/tags/#{encoded_tag_name}")
      
      # Download assets from the existing release
      download_dir = File.expand_path("../../lane_outputs/tmp/#{platform}/release_assets", __dir__)
      FileUtils.mkdir_p(download_dir)
      
      existing_release['assets']&.each do |asset|
        download_path = File.join(download_dir, asset['name'])
        Fastlane::UI.message("Downloading existing asset #{asset['name']} to #{download_path}")
        
        # We use curl with the token to download the asset
        Fastlane::Actions.sh(
          "curl -H 'Authorization: Bearer #{ENV['GITHUB_TOKEN']}' " \
          "-H 'Accept: application/octet-stream' " \
          "-L -o '#{download_path}' '#{asset['url']}'"
        )
      end
      
      # Return the parsed existing release so the lane can continue
      return existing_release
    rescue => fetch_ex
      Fastlane::UI.user_error!("Failed to fetch existing release or download its assets: #{fetch_ex.message}")
    end
  end

  # Performs authenticated GET request to GitHub API
  def self.github_get(path, params = {})
    uri       = URI("#{GITHUB_API_BASE}#{path}")
    uri.query = URI.encode_www_form(params) unless params.empty?
    token     = ENV['GITHUB_TOKEN']

    request = Net::HTTP::Get.new(uri)
    request["Accept"]        = "application/vnd.github+json"
    request["User-Agent"]    = "fastlane"
    request["Authorization"] = "Bearer #{token}" if token && !token.empty?

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }

    unless response.code.to_i == 200
      Fastlane::UI.user_error!("GitHub API error #{response.code}: #{response.body}")
    end

    JSON.parse(response.body)
  end

  private_class_method :github_get
end