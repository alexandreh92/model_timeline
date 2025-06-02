require 'spec_helper'

RSpec.describe ModelTimeline::TimelineEntry do
  let(:user) { create(:user) }
  let(:post) { create(:post, user: user) }

  # We'll create a sample entry for testing
  let!(:entry) do
    described_class.create!(
      auditable: post,
      audit_log_table: 'content_changes',
      audit_action: 'update',
      object_changes: { 'title' => ['Old Title', 'New Title'] },
      audited_at: Time.current,
      user: user,
      ip_address: '192.168.1.1'
    )
  end

  describe '.for_auditable' do
    it 'finds entries for a specific auditable object' do
      results = described_class.for_auditable(post)
      expect(results).to include(entry)
    end
  end

  describe '.for_log_table' do
    it 'finds entries for a specific log table' do
      results = described_class.for_log_table('content_changes')
      expect(results).to include(entry)
    end
  end

  describe '.for_user' do
    it 'finds entries for a specific user' do
      results = described_class.for_user(user)
      expect(results).to include(entry)
    end
  end

  describe '.for_ip_address' do
    it 'finds entries for a specific IP address' do
      results = described_class.for_ip_address('192.168.1.1')
      expect(results).to include(entry)
    end
  end

  describe '.with_changed_attribute' do
    it 'finds entries where a specific attribute was changed' do
      results = described_class.with_changed_attribute('title')
      expect(results).to include(entry)
    end
  end

  describe '.with_changed_value' do
    it 'finds entries where an attribute was changed to a specific value' do
      results = described_class.with_changed_value('title', 'New Title')
      expect(results).to include(entry)
    end
  end
end
