# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ModelTimeline::RSpec do
  let(:user) { create(:user) }

  it 'has timeline disabled by default' do
    expect(ModelTimeline.enabled?).to be false

    user.update(username: 'updated')

    expect(user).not_to have_timeline_entry_change(:username)
  end

  context 'with :with_timeline metadata', :with_timeline do
    it 'enables timeline recording' do
      expect(ModelTimeline.enabled?).to be true

      user.update(username: 'updated')

      expect(user).to have_timeline_entry_change(:username)
    end
  end

  context 'when after a test with :with_timeline' do
    it 'has timeline disabled again' do
      expect(ModelTimeline.enabled?).to be false
    end
  end
end
