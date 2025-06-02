require 'spec_helper'

RSpec.describe ModelTimeline do
  describe '.configure' do
    after do
      # Reset configuration after each test
      described_class.instance_variable_set(:@current_user_method, nil)
      described_class.instance_variable_set(:@current_ip_method, nil)
    end

    it 'allows setting current_user_method' do
      described_class.configure do |config|
        config.current_user_method = :custom_user_method
      end

      expect(described_class.current_user_method).to eq(:custom_user_method)
    end

    it 'allows setting current_ip_method' do
      described_class.configure do |config|
        config.current_ip_method = :custom_ip_method
      end

      expect(described_class.current_ip_method).to eq(:custom_ip_method)
    end
  end

  describe 'request store methods' do
    before do
      described_class.clear_request_store
    end

    it 'stores and retrieves user and ip' do
      user = build(:user)
      ip = '192.168.1.1'

      described_class.store_user_and_ip(user, ip)

      expect(described_class.current_user).to eq(user)
      expect(described_class.current_ip).to eq(ip)
    end

    it 'clears the request store' do
      described_class.store_user_and_ip('user', 'ip')
      described_class.clear_request_store

      expect(described_class.current_user).to be_nil
      expect(described_class.current_ip).to be_nil
    end
  end
end
