require 'spec_helper'

RSpec.describe ModelTimeline::Timelineable do
  before do
    # Set up current user and IP for testing
    ModelTimeline.store_user_and_ip(create(:user), '192.168.1.1')
  end

  after do
    ModelTimeline.clear_request_store
  end

  describe 'model callbacks' do
    context 'when creating a record' do
      let!(:post) { create(:post) }

      it 'creates a timeline entry for creation' do
        entry = post.timeline_entries.last
        expect(entry.audit_action).to eq('create')
        expect(entry.object_changes).to include('title')
      end
    end

    context 'when updating a record' do
      let!(:post) { create(:post, title: nil) }

      it 'creates a timeline entry for update' do
        expect {
          post.update(title: 'Updated Title')
        }.to change(post.timeline_entries, :count).by(1)

        entry = post.timeline_entries.last
        expect(entry.audit_action).to eq('update')
        expect(entry.object_changes['title']).to eq([nil, 'Updated Title'])
      end
    end

    context 'when deleting a record' do
      let!(:post) { create(:post) }

      it 'creates a timeline entry for deletion' do
        expect {
          post.destroy
        }.to change(ModelTimeline::TimelineEntry, :count).by(1)


        entry = ModelTimeline::TimelineEntry.last
        expect(entry.audit_action).to eq('destroy')
      end
    end
  end
end
