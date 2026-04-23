require 'json'
require 'net/http'
require 'uri'
require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?(:UI)

  module Helper
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
        SlackValidator.validate_file(file_path)
        normalized_channel_ids = normalize_channel_ids(channel_ids)
        filename = File.basename(file_path)
        file_size = File.size(file_path)
        upload_data = get_upload_url(filename: filename, length: file_size)

        upload_binary(
          upload_url: upload_data['upload_url'],
          file_path: file_path
        )

        normalized_channel_ids.each do |channel_id|
          complete_upload(
            file_id: upload_data['file_id'],
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
        return channel_id unless channel_id.start_with?('U')

        open_direct_message(channel_id)
      end

      def open_direct_message(member_id)
        uri = URI("#{SLACK_API_URL}/conversations.open")
        request = Net::HTTP::Post.new(uri)
        request['Authorization'] = "Bearer #{@bot_api_token}"
        request['Content-Type'] = 'application/json; charset=utf-8'
        request.body = JSON.generate(
          {
            'users' => member_id
          }
        )

        response = perform_request(uri, request)
        UI.user_error!('Slack returned empty response') if response.nil?
        body = parse_json(response.body)
        UI.user_error!("Slack conversations.open failed: #{body['error']}") unless body['ok']

        body.dig('channel', 'id') || UI.user_error!('Slack did not return channel id')
      end

      def get_upload_url(filename:, length:)
        uri = URI("#{SLACK_API_URL}/files.getUploadURLExternal")
        request = Net::HTTP::Post.new(uri)
        request['Authorization'] = "Bearer #{@bot_api_token}"
        request.set_form_data(
          'filename' => filename,
          'length' => length
        )

        response = perform_request(uri, request)
        UI.user_error!('Slack returned empty response') if response.nil?
        body = parse_json(response.body)
        UI.user_error!("Slack getUploadURLExternal failed: #{body['error']}") unless body['ok']

        body
      end

      def upload_binary(upload_url:, file_path:)
        uri = URI(upload_url)
        file_name = File.basename(file_path)
        file_data = File.binread(file_path)
        boundary = "----RubySlackUpload#{rand(1_000_000)}"

        body = []
        body << "--#{boundary}\r\n"
        body << "Content-Disposition: form-data; name=\"filename\"; filename=\"#{file_name}\"\r\n"
        body << "Content-Type: application/octet-stream\r\n\r\n"
        body << file_data
        body << "\r\n--#{boundary}--\r\n"

        request = Net::HTTP::Post.new(uri)
        request['Content-Type'] = "multipart/form-data; boundary=#{boundary}"
        request.body = body.join

        response = perform_request(uri, request)
        UI.user_error!('Slack binary upload failed') unless response.is_a?(Net::HTTPSuccess)
      end

      def complete_upload(file_id:, filename:, channel_id:, initial_comment:)
        uri = URI("#{SLACK_API_URL}/files.completeUploadExternal")
        request = Net::HTTP::Post.new(uri)
        request['Authorization'] = "Bearer #{@bot_api_token}"
        request['Content-Type'] = 'application/json; charset=utf-8'
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

        response = perform_request(uri, request)
        UI.user_error!('Slack returned empty response') if response.nil?
        body = parse_json(response.body)
        UI.user_error!("Slack completeUploadExternal failed: #{body['error']}") unless body['ok']

        body
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
