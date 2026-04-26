require 'fastlane/action'
require 'fastlane_core'
require_relative '../utils/config_helper'

module Fastlane
  module Actions
    class CleanupAction < Action
      def self.run(params)
        commons = ConfigHelper.common_config()

        paths_to_delete = commons[:cleanup_paths]
        deleted_files = []

        paths_to_delete.each do |path|
          if File.exist?(path)
            UI.message("🗑️  Deleting generated file: #{path}...")
            File.delete(path)
            deleted_files << path
          end
        end
        
        if deleted_files.any?
          UI.success("✅  Cleanup completed. #{deleted_files.size}/#{paths_to_delete.size} base64 generated file(s) removed.")
        else
          UI.message("✅  Cleanup completed. No base64 generated files found to remove.")
        end
      end

      def self.description
        "Deletes files created from base64 values during the setup phase"
      end

      def self.available_options
        []
      end

      def self.is_supported?(platform)
        [:ios, :android].include?(platform)
      end
    end
  end
end
