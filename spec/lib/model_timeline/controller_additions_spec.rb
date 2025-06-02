require 'spec_helper'

RSpec.describe ModelTimeline::ControllerAdditions do
  let(:controller) { ModelTimeline::Test::TestController.new }
  let(:user) { create(:user) }

  before do
    # Mock the included module
    controller.extend(ModelTimeline::ControllerAdditions)
    controller.set_current_user(user)
    ModelTimeline.clear_request_store
  end

  describe '#set_model_timeline_info' do
    it 'stores user and IP information' do
      # Manually call the method since we're not in a real controller
      allow(ModelTimeline).to receive(:store_user_and_ip)
      controller.set_model_timeline_info

      expect(ModelTimeline).to have_received(:store_user_and_ip).with(user, '192.168.1.1')
    end
  end

  describe '#clear_model_timeline_info' do
    it 'clears request store' do
      expect(ModelTimeline).to receive(:clear_request_store)
      controller.clear_model_timeline_info
    end
  end
end
