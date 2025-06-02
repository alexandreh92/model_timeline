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

    context 'when user method is not available' do
      before do
        allow(controller).to receive(:respond_to?).with(ModelTimeline.current_user_method, true).and_return(false)
      end

      it 'passes nil as the user' do
        allow(ModelTimeline).to receive(:store_user_and_ip)
        controller.set_model_timeline_info
        expect(ModelTimeline).to have_received(:store_user_and_ip).with(nil, '192.168.1.1')
      end
    end

    context 'when IP resolution methods vary' do
      it 'uses remote_ip as fallback when configured method is unavailable' do
        allow(ModelTimeline).to receive(:current_ip_method).and_return(:nonexistent_method)
        allow(controller.request).to receive(:respond_to?).with(:nonexistent_method).and_return(false)
        allow(controller.request).to receive(:remote_ip).and_return('10.0.0.1')

        allow(ModelTimeline).to receive(:store_user_and_ip)
        controller.set_model_timeline_info

        expect(ModelTimeline).to have_received(:store_user_and_ip).with(user, '10.0.0.1')
      end

      it 'handles exceptions when IP resolution fails' do
        allow(controller.request).to receive(:remote_ip).and_raise(StandardError)

        allow(ModelTimeline).to receive(:store_user_and_ip)
        controller.set_model_timeline_info

        expect(ModelTimeline).to have_received(:store_user_and_ip).with(user, nil)
      end
    end
  end

  describe '#clear_model_timeline_info' do
    it 'clears request store' do
      expect(ModelTimeline).to receive(:clear_request_store)
      controller.clear_model_timeline_info
    end
  end

  describe '.track_actions_with_model_timeline' do
    let(:controller_class) { Class.new }

    it 'includes the ControllerAdditions module' do
      expect(controller_class).to receive(:include).with(ModelTimeline::ControllerAdditions)
      controller_class.extend(ModelTimeline::ControllerAdditions::ClassMethods)
      controller_class.track_actions_with_model_timeline
    end
  end

  describe 'callbacks' do
    let(:controller_class) { Class.new }

    it 'sets up before_action and after_action callbacks' do
      expect(controller_class).to receive(:before_action).with(:set_model_timeline_info)
      expect(controller_class).to receive(:after_action).with(:clear_model_timeline_info)

      controller_class.send(:include, ModelTimeline::ControllerAdditions)
    end
  end
end
