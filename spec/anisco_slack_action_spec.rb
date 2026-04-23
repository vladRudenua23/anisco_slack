describe Fastlane::Actions::AniscoSlackAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The anisco_slack plugin is working!")

      Fastlane::Actions::AniscoSlackAction.run(nil)
    end
  end
end
