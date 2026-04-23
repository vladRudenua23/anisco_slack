require 'fastlane/action'
require_relative '../helper/anisco_slack_helper'

module Fastlane
  module Actions
    class AniscoSlackUploadAction < Action
      def self.run(params)
        uploader = Helper::AniscoSlackHelper.new(params[:bot_api_token])
        uploader.upload_file(
          params[:file_path],
          channel_ids: params[:channel_ids],
          initial_comment: params[:initial_comment]
        )
      end

      def self.description
        'Upload APK, AAB, and IPA files to Slack channels or direct messages using Slack external upload API'
      end

      def self.authors
        ['vrudenia']
      end

      def self.details
        'Accepts a Slack channel id string or a list of Slack channel ids, DM channel ids, or member ids starting with U and uploads the given build artifact using Slack external upload API'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :file_path,
            env_name: 'ANISCO_SLACK_FILE_PATH',
            description: 'Path to file for upload',
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :channel_ids,
            env_name: 'ANISCO_SLACK_CHANNEL_IDS',
            description: 'Slack channel id string or array of Slack channel ids, DM channel ids, or member ids starting with U',
            optional: false,
            skip_type_validation: true,
            verify_block: proc do |value|
              next if value.is_a?(String) || value.is_a?(Array)

              UI.user_error!('channel_ids must be a String or Array')
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :initial_comment,
            env_name: 'ANISCO_SLACK_INITIAL_COMMENT',
            description: 'Comment attached to uploaded file',
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :bot_api_token,
            env_name: 'SLACK_API_TOKEN',
            description: 'Slack bot token',
            optional: true,
            type: String
          )
        ]
      end

      def self.is_supported?(_platform)
        true
      end
    end
  end
end
