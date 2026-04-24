require 'json'
require 'faraday'
require 'faraday/multipart'
require 'net/http'
require 'uri'
require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?(:UI)

  module Helper
    module Api
      class Response
        attr_reader :ok, :data

        def initialize(ok:, data:)
          raise ArgumentError, 'wrong argument type' unless self.class.validate(ok)
          raise ArgumentError, 'data cannot be nil' if data.nil?

          @ok = ok
          @data = data
        end

        def self.from_hash(hash)
          raise ArgumentError, 'hash cannot be nil' if hash.nil?

          ok = hash['ok']
          data = yield(ok, hash)

          new(ok: ok, data: data)
        end

        def self.validate(value)
          [true, false].include?(value)
        end
      end

      class Error
        attr_reader :error

        def initialize(error:)
          raise ArgumentError, 'error cannot be nil' if error.nil?

          @error = error
        end

        def self.from_hash(hash)
          raise ArgumentError, 'hash cannot be nil' if hash.nil?

          new(error: hash['error'])
        end
      end

      class UploadUrl
        attr_reader :upload_url, :file_id

        def initialize(upload_url:, file_id:)
          raise ArgumentError, 'upload_url cannot be nil' if upload_url.nil?
          raise ArgumentError, 'file_id cannot be nil' if file_id.nil?

          @upload_url = upload_url
          @file_id = file_id
        end

        def self.from_hash(hash)
          raise ArgumentError, 'hash cannot be nil' if hash.nil?

          new(
            upload_url: hash['upload_url'],
            file_id: hash['file_id']
          )
        end
      end

      class Conversation
        attr_reader :id

        def initialize(id:)
          raise ArgumentError, 'id cannot be nil' if id.nil?

          @id = id
        end

        def self.from_hash(hash)
          raise ArgumentError, 'hash cannot be nil' if hash.nil?

          new(id: hash.dig('channel', 'id'))
        end
      end
    end

    class SlackValidator
      def self.validate_file(file_path)
        UI.user_error!("Unsupported file type: #{file_path}") unless file_path.match?(/\.(apk|ipa|aab)\z/i)
        UI.user_error!("File not found: #{file_path}") unless File.exist?(file_path)
      end

      def self.validate_token(token)
        UI.user_error!('Token is empty') if token.to_s.empty?
        UI.user_error!("token must have xoxb") unless token.match?(/xoxb-/)
      end
    end

    class AniscoSlackHelper
      SLACK_API_URL = 'https://slack.com/api'.freeze

      def initialize(bot_api_token)
        token = bot_api_token || ENV['SLACK_API_TOKEN']
        SlackValidator.validate_token(token)
        @bot_api_token = token
      end

      def upload_file(file_path, channel_ids:, initial_comment: nil)
        # channel id's
        normalized_channel_ids = normalize_channel_ids(channel_ids)
        # file
        SlackValidator.validate_file(file_path)
        filename = File.basename(file_path)
        file_size = File.size(file_path)

        upload_response = get_upload_url(filename: filename, length: file_size)
        upload_data = upload_response.data
        #
        upload_binary(
          upload_url: upload_data.upload_url,
          file_path: file_path
        )

        normalized_channel_ids.each do |channel_id|
          complete_upload(
            file_id: upload_data.file_id,
            filename: filename,
            channel_id: resolve_channel_id(channel_id),
            initial_comment: initial_comment
          )
        end
      end

      private

      def normalize_channel_ids(channel_ids)
        UI.user_error!('channel_ids is empty') if channel_ids.nil?

        if channel_ids.is_a?(String)
          normalized_channel_id = channel_ids.strip
          UI.user_error!('channel_ids is empty') if normalized_channel_id.empty?
          UI.user_error!('channel_ids string must contain exactly one channel id') if normalized_channel_id.match?(/[,\s;]/)

          return [normalized_channel_id]
        end

        normalized_channel_ids = Array(channel_ids)
          .map(&:to_s)
          .map(&:strip)
          .reject(&:empty?)
        UI.user_error!('channel_ids is empty') if normalized_channel_ids.empty?

        normalized_channel_ids
      end

      def resolve_channel_id(channel_id)
        UI.user_error!('channel_id is empty') if channel_id.to_s.empty?
        return channel_id if direct_message_channel_id?(channel_id)
        return open_direct_message(channel_id) if user_id?(channel_id)
        return channel_id if slack_channel_id?(channel_id)

        UI.user_error!("Unsupported channel_id format: #{channel_id}")
      end

      def direct_message_channel_id?(channel_id)
        channel_id.start_with?('D')
      end

      def user_id?(channel_id)
        channel_id.start_with?('U')
      end

      def slack_channel_id?(channel_id)
        channel_id.start_with?('C', 'G')
      end

      def open_direct_message(member_id)
        response = slack_api_connection.post('conversations.open') do |request|
          request.headers['Content-Type'] = 'application/json; charset=utf-8'
          request.body = JSON.generate(
            {
              'users' => member_id
            }
          )
        end

        UI.user_error!('Slack returned empty response') if response.nil?
        body = parse_json(response.body)

        api_response = Api::Response.from_hash(body) do |ok, data|
          ok ? Api::Conversation.from_hash(data) : Api::Error.from_hash(data)
        end

        UI.user_error!("Slack conversations.open failed: #{api_response.data.error}") unless api_response.ok

        api_response.data.id
      end

      def get_upload_url(filename:, length:)
        response = slack_api_connection.post('files.getUploadURLExternal') do |request|
          request.headers['Content-Type'] = 'application/x-www-form-urlencoded'
          request.body = URI.encode_www_form(
            {
              'filename' => filename,
              'length' => length
            }
          )
        end

        UI.user_error!('Slack returned empty response') if response.nil?
        body = parse_json(response.body)

        api_response = Api::Response.from_hash(body) do |ok, data|
          ok ? Api::UploadUrl.from_hash(data) : Api::Error.from_hash(data)
        end

        UI.user_error!("Slack getUploadURLExternal failed: #{api_response.data.error}") unless api_response.ok

        api_response
      end

      def upload_binary(upload_url:, file_path:)
        file_name = File.basename(file_path)
        payload = {
          'filename' => Faraday::UploadIO.new(
            file_path,
            'application/octet-stream',
            file_name
          )
        }

        response = Faraday.new do |builder|
          builder.request :multipart
          builder.adapter Faraday.default_adapter
        end.post(upload_url) do |request|
          request.body = payload
        end

        UI.user_error!('Slack binary upload failed') unless response.success?
      end

      def complete_upload(file_id:, filename:, channel_id:, initial_comment:)
        response = slack_api_connection.post('files.completeUploadExternal') do |request|
          request.headers['Content-Type'] = 'application/json; charset=utf-8'
          request.body = JSON.generate(
            {
              'files' => [
                {
                  'id' => file_id,
                  'title' => filename
                }
              ],
              'channel_id' => channel_id,
              'initial_comment' => initial_comment
            }.compact
          )
        end

        UI.user_error!('Slack returned empty response') if response.nil?
        body = parse_json(response.body)

        api_response = Api::Response.from_hash(body) do |ok, data|
          ok ? body : Api::Error.from_hash(data)
        end

        UI.user_error!("Slack completeUploadExternal failed: #{api_response.data.error}") unless api_response.ok

        api_response
      end

      def slack_api_connection
        @slack_api_connection ||= Faraday.new(url: SLACK_API_URL) do |builder|
          builder.request :authorization, 'Bearer', @bot_api_token
          builder.adapter Faraday.default_adapter
        end
      end

      def parse_json(body)
        JSON.parse(body)
      rescue JSON::ParserError => e
        UI.user_error!("Slack returned invalid JSON: #{e.message}")
      end

      def perform_request(uri, request)
        Net::HTTP.start(
          uri.host,
          uri.port,
          use_ssl: uri.scheme == 'https'
        ) do |http|
          http.request(request)
        end
      end
    end
  end
end
