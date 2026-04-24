describe Fastlane::Actions::AniscoSlackUploadAction do
  describe '#run' do
    it 'passes channel_ids to uploader' do
      uploader = instance_double(Fastlane::Helper::AniscoSlackHelper)
      params = {
        file_path: './build/app.apk',
        channel_ids: ['U06GPN3P36C', 'C06ABCDEF12'],
        initial_comment: 'New APK build',
        bot_api_token: 'xoxb-test'
      }

      allow(Fastlane::Helper::AniscoSlackHelper)
        .to receive(:new)
        .with('xoxb-test')
        .and_return(uploader)

      expect(uploader).to receive(:upload_file).with(
        './build/app.apk',
        channel_ids: ['U06GPN3P36C', 'C06ABCDEF12'],
        initial_comment: 'New APK build'
      )

      Fastlane::Actions::AniscoSlackUploadAction.run(params)
    end
  end
end

describe Fastlane::Actions::AniscoSlackMessageAction do
  describe '#run' do
    it 'passes message and channel_ids to uploader' do
      uploader = instance_double(Fastlane::Helper::AniscoSlackHelper)
      params = {
        message: 'Build is ready',
        channel_ids: ['U06GPN3P36C', 'C06ABCDEF12'],
        bot_api_token: 'xoxb-test'
      }

      allow(Fastlane::Helper::AniscoSlackHelper)
        .to receive(:new)
        .with('xoxb-test')
        .and_return(uploader)

      expect(uploader).to receive(:post_message).with(
        'Build is ready',
        channel_ids: ['U06GPN3P36C', 'C06ABCDEF12']
      )

      Fastlane::Actions::AniscoSlackMessageAction.run(params)
    end
  end
end
