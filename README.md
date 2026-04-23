# anisco_slack plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-anisco_slack)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-anisco_slack`, add it to your project by running:

```bash
fastlane add_plugin anisco_slack
```

## About anisco_slack

Fastlane plugin for uploading APK, AAB, and IPA files to Slack channels or direct messages using Slack external upload API.

The plugin accepts arrays of:
- Slack channel ids such as `C...`
- DM channel ids such as `D...`
- member ids such as `U...`

When a member id is passed, the plugin resolves the DM channel
automatically via `conversations.open`.

The upload flow is:
- request one upload URL via `files.getUploadURLExternal`
- upload the binary once
- iterate through `channel_ids`
- resolve each id through `resolve_channel_id`
- call `files.completeUploadExternal` for each resolved channel

## Example

Set `SLACK_API_TOKEN` in your environment:

```bash
export SLACK_API_TOKEN='xoxb-...'
```

Use the action in your `Fastfile`:

```ruby
lane :send_apk_to_slack do
  anisco_slack_upload(
    file_path: './build/app/outputs/flutter-apk/app-release.apk',
    channel_ids: ['U06GPN3P36C', 'C06ABCDEF12'],
    initial_comment: 'New APK build'
  )
end
```

You can also pass DM channel ids directly:

```ruby
anisco_slack_upload(
  file_path: './build/app/outputs/flutter-apk/app-release.apk',
  channel_ids: ['D0AU1SPLTGX', 'D0AU1SPLTGY'],
  initial_comment: 'New APK build'
)
```

## Run tests for this plugin

To run both the tests, and code style validation, run

```
rake
```

To automatically fix many of the styling issues, use
```
rubocop -a
```

## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to this repository.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
