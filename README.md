# anisco_slack plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-anisco_slack)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin.
To add `fastlane-plugin-anisco_slack` to your project, run:

```bash
fastlane add_plugin anisco_slack
```

## About anisco_slack

`anisco_slack` provides two actions:

- `anisco_slack_upload`
- `anisco_slack_message`

The plugin uses a Slack bot token and supports these recipient ids:

- channel ids such as `C...`
- private channel or MPIM ids such as `G...`
- direct message ids such as `D...`
- user ids such as `U...`

Recommended usage:

- for posting a message to a user, prefer passing `U...`
- for posting to a channel, pass `C...` or `G...`
- `D...` can be used when you already have the bot's DM conversation id

Set your token in the environment:

```bash
export SLACK_API_TOKEN='xoxb-...'
```

The bot token should have the scopes required by the Slack methods you use:

- `files:write` for file uploads
- `chat:write` for sending messages

## Action: anisco_slack_upload

Uploads one APK, AAB, or IPA file to Slack using the external upload API.

Parameters:

- `file_path` required, path to `.apk`, `.aab`, or `.ipa`
- `channel_ids` required, a single id string or an array of ids
- `initial_comment` optional, comment attached to the uploaded file
- `bot_api_token` optional, defaults to `ENV['SLACK_API_TOKEN']`

Example:

```ruby
lane :send_apk_to_slack do
  anisco_slack_upload(
    file_path: './build/app/outputs/flutter-apk/app-release.apk',
    channel_ids: ['U06GPN3P36C', 'C06ABCDEF12'],
    initial_comment: 'New APK build'
  )
end
```

You can also upload to a single target:

```ruby
anisco_slack_upload(
  file_path: './build/app/outputs/flutter-apk/app-release.apk',
  channel_ids: 'C06ABCDEF12',
  initial_comment: 'New APK build'
)
```

## Action: anisco_slack_message

Sends a plain text message using `chat.postMessage`.

Parameters:

- `message` required, text to send
- `channel_ids` required, a single id string or an array of ids
- `bot_api_token` optional, defaults to `ENV['SLACK_API_TOKEN']`

Important Slack behavior:

- `chat.postMessage` sends to one `channel` per API call
- when you pass an array, the action sends the message once per id
- when you pass a user id `U...`, Slack can open a 1:1 DM with the bot automatically
- a random `D...` direct message id is not always writable by a bot; use `U...` for user-targeted bot messages when possible

Example:

```ruby
lane :notify_testers do
  anisco_slack_message(
    message: 'Build is ready',
    channel_ids: ['U064ZSKUQNB', 'U06GPN3P36C']
  )
end
```

Send to a channel:

```ruby
anisco_slack_message(
  message: 'Android build finished successfully',
  channel_ids: 'C06ABCDEF12'
)
```

## Fastfile Example

```ruby
platform :android do
  lane :send_to_slack do |options|
    version = anisco_flutter_version()
    flavor = options[:flavor] || 'flvr_targeteam'

    anisco_slack_upload(
      file_path: build_file_path_for(flavor),
      channel_ids: ['C06ABCDEF12'],
      initial_comment: "Version #{version}, #{flavor}"
    )

    anisco_slack_message(
      message: "Uploaded version #{version}, #{flavor}",
      channel_ids: ['U064ZSKUQNB', 'C06ABCDEF12']
    )
  end
end
```

## Validation Notes

- `channel_ids` must be a `String` or `Array`
- a string `channel_ids` value is treated as exactly one id
- empty `channel_ids` are rejected
- empty `message` is rejected
- upload supports only `.apk`, `.aab`, and `.ipa`

## Advanced Notes

Upload flow for `anisco_slack_upload`:

1. Calls `files.getUploadURLExternal`
2. Uploads the binary once
3. Calls `files.completeUploadExternal` once with `channels`

Message flow for `anisco_slack_message`:

1. Calls `chat.postMessage`
2. Sends one request per provided recipient id

## Local Development

Install dependencies:

```bash
bundle install
```

Run tests:

```bash
bundle exec rspec spec/anisco_slack_action_spec.rb spec/anisco_slack_helper_spec.rb
```

Run the full plugin checks:

```bash
rake
```

Auto-fix some style issues:

```bash
rubocop -a
```

## Troubleshooting

If uploads fail:

- verify `SLACK_API_TOKEN`
- verify the bot has `files:write`
- verify the file path exists and has a supported extension

If messages fail:

- verify the bot has `chat:write`
- prefer `U...` ids for user-targeted bot DMs
- verify the bot is allowed to post to the given channel or conversation

If you have trouble using fastlane plugins, see the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## About fastlane

[_fastlane_](https://fastlane.tools) is a tool for automating mobile build and release workflows.
