# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ModelTimeline::RSpec::Matchers, :with_timeline do
  let(:user) { create(:user) }

  describe '#have_timeline_entries' do
    context 'with no entries' do
      it 'fails when expecting entries' do
        ModelTimeline.disable!

        expect do
          expect(user).to have_timeline_entries
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end

      it 'passes when not expecting entries' do
        ModelTimeline.disable!

        expect(user).not_to have_timeline_entries
      end

      it 'fails when expecting specific count' do
        expect do
          expect(user).to have_timeline_entries(2)
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
    end

    context 'with entries' do
      before do
        user.update(username: 'new_username')
        user.update(email: 'new@example.com')
      end

      it 'passes when expecting any entries' do
        expect(user).to have_timeline_entries
      end

      it 'fails when not expecting entries' do
        expect do
          expect(user).not_to have_timeline_entries
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end

      it 'passes when expecting correct count' do
        expect(user).to have_timeline_entries(3)
      end

      it 'fails when expecting incorrect count' do
        expect do
          expect(user).to have_timeline_entries(4)
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
    end
  end

  describe '#have_timeline_entry_action' do
    context 'with an action' do
      before do
        user.update(username: 'new_username')
      end

      it 'passes when checking for the correct action' do
        expect(user).to have_timeline_entry_action(:update)
      end

      it 'passes when checking for the correct action as string' do
        expect(user).to have_timeline_entry_action('update')
      end

      it 'fails with matcher for wrong action' do
        expect do
          expect(user).to have_timeline_entry_action(:destroy)
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end

      it 'passes with negated matcher for wrong action' do
        expect(user).not_to have_timeline_entry_action(:destroy)
      end

      it 'fails with negated matcher for correct action' do
        expect do
          expect(user).not_to have_timeline_entry_action(:update)
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
    end
  end

  describe '#have_timeline_entry_change' do
    before do
      user.update(username: 'new_username', email: 'new@example.com')
    end

    context 'when checking for an attribute that changed' do
      it 'passes when the attribute changed' do
        expect(user).to have_timeline_entry_change(:username)
      end

      it 'passes for multiple changed attributes' do
        expect(user).to have_timeline_entry_change(:username)
        expect(user).to have_timeline_entry_change(:email)
      end

      it 'passes with string attribute names' do
        expect(user).to have_timeline_entry_change('username')
      end

      it 'fails when the attribute did not change' do
        expect do
          expect(user).to have_timeline_entry_change(:non_existent_attribute)
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
    end

    context 'with negated matcher' do
      it 'passes when attribute did not change' do
        expect(user).not_to have_timeline_entry_change(:non_existent_attribute)
      end

      it 'fails when attribute did change' do
        expect do
          expect(user).not_to have_timeline_entry_change(:username)
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
    end

    context 'when timeline has multiple entries' do
      before do
        user.update(username: 'another_username')
      end

      it 'detects the attribute change' do
        expect(user).to have_timeline_entry_change(:username)
      end

      it 'detects all changed attributes across multiple entries' do
        expect(user).to have_timeline_entry_change(:username)
        expect(user).to have_timeline_entry_change(:email)
      end
    end
  end

  describe '#have_timeline_entry' do
    context 'with specific value changes' do
      before do
        user.update(username: 'specific_value')
      end

      it 'passes when attribute changed to the specified value' do
        expect(user).to have_timeline_entry(:username, 'specific_value')
      end

      it 'fails when attribute changed to a different value' do
        expect do
          expect(user).to have_timeline_entry(:username, 'wrong_value')
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end

      it 'fails when attribute did not change' do
        expect do
          expect(user).to have_timeline_entry(:non_existent, 'any_value')
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end

      it 'passes with negated matcher when value does not match' do
        expect(user).not_to have_timeline_entry(:username, 'wrong_value')
      end

      it 'fails with negated matcher when value matches' do
        expect do
          expect(user).not_to have_timeline_entry(:username, 'specific_value')
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
    end

    context 'with multiple entries and value changes' do
      before do
        user.update(username: 'first_value')
        user.update(username: 'second_value')
      end

      it 'finds the most recent value by default' do
        expect(user).to have_timeline_entry(:username, 'second_value')
      end

      it 'can find older values too' do
        expect(user).to have_timeline_entry(:username, 'first_value')
      end
    end
  end

  describe 'combined matchers' do
    before do
      user.update(username: 'new_value', email: 'new@example.com')
    end

    it 'works with multiple expectations' do
      aggregate_failures do
        expect(user).to have_timeline_entries
        expect(user).to have_timeline_entries(2)
        expect(user).to have_timeline_entry_action(:update)
        expect(user).to have_timeline_entry_change(:username)
        expect(user).to have_timeline_entry_change(:email)
        expect(user).to have_timeline_entry(:username, 'new_value')
        expect(user).to have_timeline_entry(:email, 'new@example.com')
      end
    end
  end

  describe '#have_timeline_entry_metadata' do
    context 'when entries have metadata' do
      before do
        # Create a timeline entry with metadata
        user.update(username: 'new_username')
        # Access the last timeline entry and add metadata
        user.timeline_entries.last.update(
          metadata: {
            source: 'admin_panel',
            reason: 'profile_update',
            user_agent: 'Mozilla/5.0'
          }
        )
      end

      it 'passes when checking for existing metadata' do
        expect(user).to have_timeline_entry_metadata(source: 'admin_panel')
      end

      it 'passes when checking for multiple metadata fields' do
        expect(user).to have_timeline_entry_metadata(source: 'admin_panel', reason: 'profile_update')
      end

      it 'fails when checking for non-existent metadata' do
        expect do
          expect(user).to have_timeline_entry_metadata(source: 'api')
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end

      it 'fails when checking for wrong value in metadata' do
        expect do
          expect(user).to have_timeline_entry_metadata(source: 'admin_panel', reason: 'security_concern')
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end

      it 'passes with negated matcher when metadata does not exist' do
        expect(user).not_to have_timeline_entry_metadata(missing: 'value')
      end

      it 'fails with negated matcher when metadata exists' do
        expect do
          expect(user).not_to have_timeline_entry_metadata(source: 'admin_panel')
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
    end

    context 'with complex metadata values' do
      before do
        user.update(username: 'complex_metadata')
        user.timeline_entries.last.update(
          metadata: {
            nested: { foo: 'bar', baz: 123 },
            array: [1, 2, 3],
            boolean: true
          }
        )
      end

      it 'handles boolean values' do
        expect(user).to have_timeline_entry_metadata(boolean: true)
        expect(user).not_to have_timeline_entry_metadata(boolean: false)
      end

      it 'handles nested structures as exact matches' do
        # NOTE: This depends on the implementation - some implementations
        # might only check top-level keys or compare JSON serializations
        expect(user).to have_timeline_entry_metadata(nested: { foo: 'bar', baz: 123 })
      end
    end
  end

  describe 'edge cases' do
    it 'handles nil values correctly' do
      user.update(username: 'initial_value')
      user.update(username: nil)
      expect(user).to have_timeline_entry_change(:username)
    end

    it 'handles special characters in values' do
      user.update(username: 'value with spaces & symbols!')
      expect(user).to have_timeline_entry_change(:username)
      expect(user).to have_timeline_entry(:username, 'value with spaces & symbols!')
    end
  end
end
