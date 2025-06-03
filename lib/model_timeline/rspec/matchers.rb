# frozen_string_literal: true

module ModelTimeline
  module RSpec
    # rubocop:disable Naming/PredicateName
    # Custom RSpec matchers for testing model timeline entries
    #
    # These matchers help you test the timeline entries created by the ModelTimeline gem.
    # Use them in your specs to verify that your models are correctly recording timeline events.
    #
    # @example Basic usage with different matchers
    #   # Check for any timeline entries
    #   expect(user).to have_timeline_entries
    #
    #   # Check for specific number of entries
    #   expect(user).to have_timeline_entries(3)
    #
    #   # Check for specific action
    #   expect(user).to have_timelined_action(:update)
    #
    #   # Check for changes to a specific attribute
    #   expect(user).to have_timelined_change(:email)
    #
    #   # Check for specific value change
    #   expect(user).to have_timelined_entry(:status, "active")
    module Matchers
      # Check if a model has timeline entries
      #
      # @param count [Integer, nil] The expected number of timeline entries (optional)
      # @return [HaveTimelineEntriesMatcher] A matcher that checks for timeline entries
      # @example Without count parameter
      #   expect(user).to have_timeline_entries
      # @example With count parameter
      #   expect(user).to have_timeline_entries(3)
      def have_timeline_entries(count = nil)
        HaveTimelineEntriesMatcher.new(count)
      end

      # Check if a specific action was recorded in the timeline
      #
      # @param action [String, Symbol] The action name to look for
      # @return [HaveTimelinedAction] A matcher that checks for a specific action
      # @example
      #   expect(user).to have_timelined_action(:create)
      #   expect(user).to have_timelined_action("update")
      def have_timelined_action(action)
        HaveTimelinedAction.new(action)
      end

      # Check if a specific attribute change was recorded in the timeline
      #
      # @param attribute [String, Symbol] The attribute name to check for changes
      # @return [HaveTimelinedChange] A matcher that checks if an attribute was changed
      # @example
      #   expect(user).to have_timelined_change(:email)
      #   expect(user).to have_timelined_change("status")
      def have_timelined_change(attribute)
        HaveTimelinedChange.new(attribute)
      end

      # Check if an attribute was changed to a specific value in the timeline
      #
      # @param attribute [String, Symbol] The attribute name to check
      # @param value [Object] The value to check for
      # @return [HaveTimelinedEntry] A matcher that checks for specific attribute values
      # @example
      #   expect(user).to have_timelined_entry(:status, "active")
      #   expect(user).to have_timelined_entry(:role, :admin)
      def have_timelined_entry(attribute, value)
        HaveTimelinedEntry.new(attribute, value)
      end

      # RSpec matcher to check if a model has timeline entries
      #
      # @api private
      class HaveTimelineEntriesMatcher
        # Initialize the matcher
        #
        # @param expected_count [Integer, nil] The expected number of timeline entries
        def initialize(expected_count)
          @expected_count = expected_count
        end

        # Check if the subject matches the expectations
        #
        # @param subject [Object] The model to check for timeline entries
        # @return [Boolean] True if the model has the expected number of timeline entries
        def matches?(subject)
          @subject = subject
          if @expected_count.nil?
            subject.timeline_entries.any?
          else
            subject.timeline_entries.count == @expected_count
          end
        end

        # Message displayed when the expectation fails
        #
        # @return [String] A descriptive failure message
        def failure_message
          if @expected_count.nil?
            "expected #{@subject} to have timeline entries, but found none"
          else
            "expected #{@subject} to have #{@expected_count} timeline entries, " \
              "but found #{@subject.timeline_entries.count}"
          end
        end

        # Message displayed when the negated expectation fails
        #
        # @return [String] A descriptive failure message for negated expectations
        def failure_message_when_negated
          if @expected_count.nil?
            "expected #{@subject} not to have any timeline entries, but found #{@subject.timeline_entries.count}"
          else
            "expected #{@subject} not to have #{@expected_count} timeline entries, but found exactly that many"
          end
        end
      end

      # RSpec matcher to check if a model has timeline entries with a specific action
      #
      # @api private
      class HaveTimelinedAction
        # Initialize the matcher
        #
        # @param action [String, Symbol] The action to look for
        def initialize(action)
          @action = action.to_s
        end

        # Check if the subject matches the expectations
        #
        # @param subject [Object] The model to check for timeline entries
        # @return [Boolean] True if the model has timeline entries with the specified action
        def matches?(subject)
          @subject = subject
          subject.timeline_entries.where(action: @action).exists?
        end

        # Message displayed when the expectation fails
        #
        # @return [String] A descriptive failure message
        def failure_message
          "expected #{@subject} to have recorded action '#{@action}', but none was found"
        end

        # Message displayed when the negated expectation fails
        #
        # @return [String] A descriptive failure message for negated expectations
        def failure_message_when_negated
          "expected #{@subject} not to have recorded action '#{@action}', but it was found"
        end
      end

      # RSpec matcher to check if a model has timeline entries with changes to a specific attribute
      #
      # @api private
      class HaveTimelinedChange
        # Initialize the matcher
        #
        # @param attribute [String, Symbol] The attribute to check for changes
        def initialize(attribute)
          @attribute = attribute.to_s
        end

        # Check if the subject matches the expectations
        #
        # @param subject [Object] The model to check for timeline entries
        # @return [Boolean] True if the model has timeline entries with changes to the specified attribute
        def matches?(subject)
          @subject = subject
          subject.timeline_entries.with_changed_attribute(@attribute).exists?
        end

        # Message displayed when the expectation fails
        #
        # @return [String] A descriptive failure message
        def failure_message
          "expected #{@subject} to have tracked changes to '#{@attribute}', but none was found"
        end

        # Message displayed when the negated expectation fails
        #
        # @return [String] A descriptive failure message for negated expectations
        def failure_message_when_negated
          "expected #{@subject} not to have tracked changes to '#{@attribute}', but changes were found"
        end
      end

      # RSpec matcher to check if a model has timeline entries where an attribute changed to a specific value
      #
      # @api private
      class HaveTimelinedEntry
        # Initialize the matcher
        #
        # @param attribute [String, Symbol] The attribute to check
        # @param value [Object] The value the attribute should have changed to
        def initialize(attribute, value)
          @attribute = attribute.to_s
          @value = value
        end

        # Check if the subject matches the expectations
        #
        # @param subject [Object] The model to check for timeline entries
        # @return [Boolean] True if the model has timeline entries where the attribute changed to the specified value
        def matches?(subject)
          @subject = subject
          subject.timeline_entries.with_changed_value(@attribute, @value).exists?
        end

        # Message displayed when the expectation fails
        #
        # @return [String] A descriptive failure message
        def failure_message
          "expected #{@subject} to have tracked '#{@attribute}' changing to '#{@value}', but no such change was found"
        end

        # Message displayed when the negated expectation fails
        #
        # @return [String] A descriptive failure message for negated expectations
        def failure_message_when_negated
          "expected #{@subject} not to have tracked '#{@attribute}' changing to '#{@value}', but such a change was found"
        end
      end
    end
    # rubocop:enable Naming/PredicateName
  end
end
