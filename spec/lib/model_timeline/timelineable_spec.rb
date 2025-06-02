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
        expect(entry.action).to eq('create')
        expect(entry.object_changes).to include('title')
      end
    end

    context 'when updating a record' do
      let!(:post) { create(:post, title: nil) }

      it 'creates a timeline entry for update' do
        expect do
          post.update(title: 'Updated Title')
        end.to change(post.timeline_entries, :count).by(1)

        entry = post.timeline_entries.last
        expect(entry.action).to eq('update')
        expect(entry.object_changes['title']).to eq([nil, 'Updated Title'])
      end
    end

    context 'when deleting a record' do
      let!(:post) { create(:post) }

      it 'creates a timeline entry for deletion' do
        expect do
          post.destroy
        end.to change(ModelTimeline::TimelineEntry, :count).by(1)

        entry = ModelTimeline::TimelineEntry.last
        expect(entry.action).to eq('destroy')
      end
    end
  end

  context 'when a model have multiple definitions of the same configuration' do
    let(:post_class) do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'posts'

        has_timeline :timeline_entries
        has_timeline :timeline_entries, on: [:create]

        belongs_to :user
      end
    end

    it 'raises an Error' do
      expect do
        post_class
      end.to raise_exception(ModelTimeline::ConfigurationError, /Multiple definitions of the same configuration/)
    end
  end

  context 'when filtering by :only' do
    let!(:post) { post_class.create(title: 'Initial', content: 'Initial') }

    let(:post_class) do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'posts'

        has_timeline :timeline_entries, only: [:title]
        belongs_to :user
      end
    end

    before { stub_const('Post', post_class) }

    it 'creates a timeline record when changing title' do
      expect do
        post.update(title: 'Updated Title')
      end.to change(post.timeline_entries.where(action: 'update'), :count).by(1)
    end

    it 'does not create a timeline record when changing content' do
      expect do
        post.update(content: 'updated')
      end.not_to change(post.timeline_entries.where(action: 'update'), :count)
    end
  end

  context 'when filtering by :ignore' do
    let!(:post) { post_class.create(title: 'Initial', content: 'Initial') }

    let(:post_class) do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'posts'

        has_timeline :timeline_entries, ignore: %i[title updated_at]
        belongs_to :user
      end
    end

    before { stub_const('Post', post_class) }

    it 'creates a timeline record when changing content' do
      expect do
        post.update(content: 'updated')
      end.to change(post.timeline_entries.where(action: 'update'), :count).by(1)
    end

    it 'does not create a timeline record when changing title' do
      expect do
        post.update(title: 'Updated Title')
      end.not_to change(post.timeline_entries.where(action: 'update'), :count)
    end
  end

  context 'when filtering by :on' do
    context 'when only on: create' do
      let(:post) { post_class.create!(title: 'Initial', content: 'Initial') }

      let(:post_class) do
        Class.new(ActiveRecord::Base) do
          self.table_name = 'posts'

          has_timeline :timeline_entries, on: [:create]
          belongs_to :user
        end
      end

      before { stub_const('Post', post_class) }

      it 'creates a timeline record for creation' do
        expect(post.reload.timeline_entries.where(action: 'create').count).to eq(1)
      end

      it 'does not create a record for update' do
        expect do
          post.update!(title: 'updated')
        end.not_to change(post.timeline_entries.where(action: 'update'), :count)
      end

      it 'does not create a timeline record for destroy' do
        expect do
          post.destroy!
        end.not_to change(ModelTimeline::TimelineEntry.where(action: 'destroy'), :count)
      end
    end

    context 'when on: update' do
      let(:post) { post_class.create!(title: 'Initial', content: 'Initial') }

      let(:post_class) do
        Class.new(ActiveRecord::Base) do
          self.table_name = 'posts'

          has_timeline :timeline_entries, on: [:update]
          belongs_to :user
        end
      end

      before { stub_const('Post', post_class) }

      it 'does not create a timeline record for creation' do
        expect(post.reload.timeline_entries.where(action: 'create').count).to eq(0)
      end

      it 'creates a record for update' do
        expect do
          post.update!(title: 'updated')
        end.to change(post.timeline_entries.where(action: 'update'), :count).by(1)
      end

      it 'does not create a timeline record for destroy' do
        expect do
          post.destroy!
        end.not_to change(ModelTimeline::TimelineEntry.where(action: 'destroy'), :count)
      end
    end

    context 'when on: destroy' do
      let(:post) { post_class.create!(title: 'Initial', content: 'Initial') }

      let(:post_class) do
        Class.new(ActiveRecord::Base) do
          self.table_name = 'posts'

          has_timeline :timeline_entries, on: [:destroy]
          belongs_to :user
        end
      end

      before { stub_const('Post', post_class) }

      it 'does not create a timeline record for creation' do
        expect(post.reload.timeline_entries.where(action: 'create').count).to eq(0)
      end

      it 'does not create a record for update' do
        expect do
          post.update!(title: 'updated')
        end.not_to change(post.timeline_entries.where(action: 'update'), :count)
      end

      it 'creates a timeline record for destroy' do
        expect do
          post.destroy!
        end.to change(ModelTimeline::TimelineEntry.where(action: 'destroy'), :count).by(1)
      end
    end
  end
end
