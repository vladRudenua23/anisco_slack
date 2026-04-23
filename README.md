# anisco_slack plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-anisco_slack)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-anisco_slack`, add it to your project by running:

```bash
fastlane add_plugin anisco_slack
```

## About anisco_slack

Fastlane plugin for uploading APK, AAB, and IPA files to Slack channels or direct messages using Slack external upload API.

The plugin accepts:
- a Slack channel id such as `C...`
- a DM channel id such as `D...`
- a member id such as `U...`

When a member id is passed, the plugin resolves the DM channel automatically via `conversations.open`.

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
    channel_id: 'U06GPN3P36C',
    initial_comment: 'New APK build'
  )
end
```

You can also pass a DM channel id directly:

```ruby
anisco_slack_upload(
  file_path: './build/app/outputs/flutter-apk/app-release.apk',
  channel_id: 'D0AU1SPLTGX',
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
