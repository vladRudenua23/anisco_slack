require 'fastlane/action'
require_relative '../helper/anisco_slack_helper'

module Fastlane
  module Actions
    class AniscoSlackMessageAction < Action
      def self.run(params)
        uploader = Helper::AniscoSlackHelper.new(params[:bot_api_token])
        uploader.post_message(
          params[:message],
          channel_ids: params[:channel_ids]
        )
      end

      def self.description
        'Send a text message to Slack channels or direct messages using chat.postMessage'
      end

      def self.authors
        ['vrudenia@asist-lab.com']
      end

      def self.details
        'Accepts a Slack channel id string or a list of Slack channel ids, DM channel ids, or member ids starting with U and sends the given message using Slack chat.postMessage'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :message,
            env_name: 'ANISCO_SLACK_MESSAGE',
            description: 'Text message to send',
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
