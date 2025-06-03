# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ModelTimeline, :with_timeline do
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

  describe 'enable/disable functionality' do
    after do
      # Reset enabled state after tests
      described_class.instance_variable_set(:@enabled, nil)
    end

    it 'is enabled by default' do
      expect(described_class.enabled?).to be true
    end

    it 'can be disabled' do
      described_class.disable!
      expect(described_class.enabled?).to be false
    end

    it 'can be re-enabled' do
      described_class.disable!
      described_class.enable!
      expect(described_class.enabled?).to be true
    end

    it 'temporarily disables timeline with without_timeline' do
      result = described_class.without_timeline do
        expect(described_class.enabled?).to be false
        'test result'
      end

      expect(result).to eq('test result')
      expect(described_class.enabled?).to be true
    end

    it 'restores previous state after without_timeline' do
      described_class.disable!
      described_class.without_timeline do
        # Still disabled inside block
      end
      expect(described_class.enabled?).to be false
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

  describe 'metadata methods' do
    before do
      described_class.clear_metadata!
    end

    it 'stores and retrieves metadata' do
      described_class.metadata = { key: 'value' }
      expect(described_class.metadata).to eq({ key: 'value' })
    end

    it 'merges metadata' do
      described_class.metadata = { existing: 'data' }

      described_class.with_metadata({ new: 'info' }) do
        expect(described_class.metadata).to eq({ existing: 'data', new: 'info' })
      end

      expect(described_class.metadata).to eq({ existing: 'data' })
    end

    it 'clears metadata' do
      described_class.metadata = { key: 'value' }
      described_class.clear_metadata!
      expect(described_class.metadata).to eq({})
    end
  end

  describe 'with_timeline method' do
    let(:user) { build(:user) }
    let(:ip) { '192.168.1.1' }
    let(:metadata) { { source: 'test' } }

    before do
      described_class.clear_request_store
      described_class.clear_metadata!
    end

    it 'sets user, ip and metadata for the block' do
      described_class.with_timeline(current_user: user, current_ip: ip, metadata: metadata) do
        expect(described_class.current_user).to eq(user)
        expect(described_class.current_ip).to eq(ip)
        expect(described_class.metadata).to eq(metadata)
      end
    end

    it 'restores previous values after the block' do
      original_user = 'original_user'
      original_ip = 'original_ip'
      original_metadata = { original: true }

      described_class.store_user_and_ip(original_user, original_ip)
      described_class.metadata = original_metadata

      described_class.with_timeline(current_user: user, current_ip: ip, metadata: metadata) do
        # Values changed inside block
      end

      expect(described_class.current_user).to eq(original_user)
      expect(described_class.current_ip).to eq(original_ip)
      expect(described_class.metadata).to eq(original_metadata)
    end
  end
end
