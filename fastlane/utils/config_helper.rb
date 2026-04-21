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
    result = ENV.fetch(key) { default }
    
    # Treat empty strings as missing and return default
    if result.nil? || (result.is_a?(String) && result.strip.empty?)
      Fastlane::UI.message("#{key} is missing!") if default.nil?
      return default
    end
    
    # Safely convert string values "true" and "false" into actual Ruby booleans
    if result.is_a?(String)
      return true if result.strip.downcase == "true"
      return false if result.strip.downcase == "false"
    end
    
    result
  end

  # Walks up from a given directory to find the nearest .tool-versions,
  # returns the directory containing it (project root).
  def self.find_project_root(start_dir)
    dir = File.expand_path(start_dir)
    loop do
      return dir if File.exist?(File.join(dir, ".tool-versions"))

      parent = File.dirname(dir)
      Fastlane::UI.user_error!("Could not find .tool-versions in any parent directory of #{start_dir}") if parent == dir
      dir = parent
    end
  end

  def self.ios_config(export_method: "app-store", platform: :ios, is_ci: true)
    root_dir_name   = optional_env("GITHUB_WORKSPACE", default: find_project_root(File.dirname(__FILE__)))
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
    match_readonly                = optional_env("MATCH_READONLY", default: is_ci)
    match_git_branch              = require_env("MATCH_REPO_BRANCH")
    match_git_private_key_base64  = require_env("MATCH_REPO_PRIVATE_KEY")
    
    slack_url                     = optional_env("SLACK_URL")
    firebase_app_id               = require_env("FIREBASE_IOS_APP_ID")
    firebase_credentials_base64   = optional_env("FIREBASE_CREDENTIALS")
    firebase_tester_group         = optional_env("FIREBASE_TESTER_GROUP", default: "internal")
    silent                        = optional_env("SILENT", default: false)
    send_changelog_to_testflight  = optional_env("SEND_CHANGELOG_TO_TESTFLIGHT", default: false)
    output_path                   = "lane_outputs"
    derived_data_path             = "derived_data"

    {
      configuration: "Release",
      export_method: export_method,
      match_type: MATCH_TYPE_MAP[export_method] || export_method,
      in_house: false,
      workspace_name: workspace_name,
      workspace: "#{root_dir_name}/ios/#{workspace_name}.xcworkspace",
      project: "#{root_dir_name}/ios/#{workspace_name}.xcodeproj",
      lane_output_directory: "#{root_dir_name}/#{output_path}/#{platform}",
      xcarchive_path: "#{root_dir_name}/#{output_path}/#{platform}/archive/Archive.xcarchive",
      ipa_output_directory: "#{root_dir_name}/#{output_path}/#{platform}/output/",
      zip_asset_path: "#{root_dir_name}/#{output_path}/tmp/#{platform}/#{scheme}.zip",
      derived_data_path: "#{root_dir_name}/#{derived_data_path}",
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
      match_readonly: match_readonly,
      match_password: match_password,
      match_git_branch: match_git_branch,
      match_git_private_key_base64: match_git_private_key_base64,
      firebase_app_id: firebase_app_id,
      firebase_tester_group: firebase_tester_group,
      firebase_credentials_base64: firebase_credentials_base64,
      firebase_credentials_path: "#{root_dir_name}/firebase_credentials.json",
      silent: silent,
      send_changelog_to_testflight: send_changelog_to_testflight
    }
  end

  def self.android_config(export_method: "apk", platform: :android)
    root_dir_name   = optional_env("GITHUB_WORKSPACE", default: find_project_root(File.dirname(__FILE__)))
    app_identifier  = require_env("APP_IDENTIFIER")

    key_store_base64              = require_env("ANDROID_KEYSTORE")
    key_store_password            = require_env("ANDROID_KEYSTORE_PASSWORD")
    key_alias                     = require_env("ANDROID_KEY_ALIAS")
    key_password                  = require_env("ANDROID_KEY_PASSWORD")
    slack_url                     = optional_env("SLACK_URL")
    firebase_app_id               = require_env("FIREBASE_ANDROID_APP_ID")
    firebase_credentials_base64   = optional_env("FIREBASE_CREDENTIALS")
    firebase_tester_group         = optional_env("FIREBASE_TESTER_GROUP", default: "internal")
    play_store_credentials_base64 = optional_env("PLAY_STORE_CREDENTIALS")

    output_path                   = "lane_outputs"

    {
      slack_url: slack_url,
      app_identifier: app_identifier,
      export_method: export_method,
      platform: platform,
      task: export_method == "apk" ? "assemble" : "bundle",
      build_type: "Release",
      project_dir: "#{root_dir_name}/android",
      gradle_path: "#{root_dir_name}/android/gradlew",
      app_gradle_file_path: "#{root_dir_name}/android/app/build.gradle",
      key_store_base64: key_store_base64,
      key_store_path: "#{root_dir_name}/key.keystore",
      key_store_password: key_store_password,
      key_alias: key_alias,
      key_password: key_password,
      firebase_app_id:firebase_app_id,
      firebase_tester_group: firebase_tester_group,
      firebase_credentials_base64: firebase_credentials_base64,
      firebase_credentials_path: "#{root_dir_name}/firebase_credentials.json",
      play_store_credentials_base64: play_store_credentials_base64,
      play_store_credentials_path: "#{root_dir_name}/play_store_credentials.json",
      zip_asset_path: "#{root_dir_name}/#{output_path}/tmp/#{platform}/#{export_method}.zip",
    }
  end
end