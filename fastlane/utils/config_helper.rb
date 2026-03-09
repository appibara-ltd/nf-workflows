# frozen_string_literal: true

module ConfigHelper
  MATCH_TYPE_MAP = {
    "ad-hoc" => "adhoc",
    "app-store" => "appstore"
  }.freeze

  # Fetches a required ENV variable or raises a Fastlane error
  def self.require_env(key)
    ENV.fetch(key) { Fastlane::UI.user_error!("#{key} is missing!") }
  end

  # Fetches an optional ENV variable, logs a warning and returns default if missing
  def self.optional_env(key, default: nil)
    ENV.fetch(key) do
      Fastlane::UI.message("#{key} is missing!") if default.nil?
      default
    end
  end

  def self.app_config(export_method: "app-store")
    workspace_name  = optional_env("WORKSPACE_NAME", default: "nativeflowbase")
    scheme          = optional_env("SCHEME", default: "base")

    app_identifier  = require_env("APP_IDENTIFIER")
    team_id         = require_env("APPLE_DEVELOPER_PORTAL_TEAM_ID")
    itc_team_id     = require_env("APPLE_STORE_CONNECT_TEAM_ID")
    key_base64      = require_env("APPLE_KEY")
    key_id          = require_env("APPLE_KEY_ID")
    issuer_id       = require_env("APPLE_ISSUER_ID")

    match_git_url                 = require_env("MATCH_REPO_URL")
    match_username                = require_env("MATCH_REPO_USERNAME")
    match_password                = require_env("MATCH_PASSWORD")
    match_git_branch              = require_env("MATCH_REPO_BRANCH")
    match_git_private_key_base64  = require_env("MATCH_REPO_PRIVATE_KEY")
    
    slack_url                     = optional_env("SLACK_URL")
    firebase_credentials_base64   = optional_env("FIREBASE_CREDENTIALS")
    googleservice_info_plist_path = optional_env("GOOGLESERVICE_INFO_PLIST_PATH")

    pwd_dir_name = File.dirname(Dir.pwd)

    {
      configuration: "Release",
      export_method: export_method,
      match_type: MATCH_TYPE_MAP[export_method] || export_method,
      in_house: false,
      workspace_name: workspace_name,
      workspace: "#{workspace_name}.xcworkspace",
      project: "#{workspace_name}.xcodeproj",
      scheme: scheme,
      team_id: team_id,
      itc_team_id: itc_team_id,
      app_identifier: app_identifier,
      key_base64: key_base64,
      key_id: key_id,
      issuer_id: issuer_id,
      slack_url: slack_url,
      match_git_url: match_git_url,
      match_username: match_username,
      match_password: match_password,
      match_git_branch: match_git_branch,
      match_git_private_key_base64: match_git_private_key_base64,
      match_git_private_key_path: "#{pwd_dir_name}/fastlane_certs_match_cli_v2",
      firebase_credentials_base64: firebase_credentials_base64,
      firebase_credentials_path: "#{pwd_dir_name}/firebase_credentials.json",
      googleservice_info_plist_path: googleservice_info_plist_path
    }
  end
end
