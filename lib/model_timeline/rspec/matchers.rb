# frozen_string_literal: true

module ModelTimeline
  module RSpec
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
    #   expect(user).to have_timeline_entry_action(:update)
    #
    #   # Check for changes to a specific attribute
    #   expect(user).to have_timeline_entry_change(:email)
    #
    #   # Check for specific value change
    #   expect(user).to have_timeline_entry(:status, "active")
    module Matchers
      def self.included(base)
        base.include define_timeline_matchers_for(:timeline_entries)
      end

      def self.define_timeline_matchers_for(association_name)
        association_name_singularized = association_name.to_s.singularize

        Module.new do
          # Check if a model has timeline entries
          #
          # @param count [Integer, nil] The expected number of timeline entries (optional)
          # @return [HaveTimelineEntriesMatcher] A matcher that checks for timeline entries
          # @example Without count parameter
          #   expect(user).to have_timeline_entries
          # @example With count parameter
          #   expect(user).to have_timeline_entries(3)
          define_method(:"have_#{association_name}") do |count = nil|
            HaveTimelineEntriesMatcher.new(count, association_name)
          end

          # Check if a specific action was recorded in the timeline
          #
          # @param action [String, Symbol] The action name to look for
          # @return [HaveTimelineAction] A matcher that checks for a specific action
          # @example
          #   expect(user).to have_timeline_entry_action(:create)
          #   expect(user).to have_timeline_entry_action("update")
          define_method(:"have_#{association_name_singularized}_action") do |action|
            HaveTimelineAction.new(action, association_name)
          end

          # Check if a specific attribute change was recorded in the timeline
          #
          # @param attribute [String, Symbol] The attribute name to check for changes
          # @return [HaveTimelineChange] A matcher that checks if an attribute was changed
          # @example
          #   expect(user).to have_timeline_entry_change(:email)
          #   expect(user).to have_timeline_entry_change("status")
          define_method(:"have_#{association_name_singularized}_change") do |attribute|
            HaveTimelineChange.new(attribute, association_name)
          end

          # Check if an attribute was changed to a specific value in the timeline
          #
          # @param attribute [String, Symbol] The attribute name to check
          # @param value [Object] The value to check for
          # @return [HaveTimelineEntry] A matcher that checks for specific attribute values
          # @example
          #   expect(user).to have_timeline_entry(:status, "active")
          #   expect(user).to have_timeline_entry(:role, :admin)
          define_method(:"have_#{association_name_singularized}") do |attribute, value|
            HaveTimelineEntry.new(attribute, value, association_name)
          end

          # Check if a model has timeline entries with specific metadata
          #
          # @param expected_metadata [Hash] The metadata key-value pairs to check for
          # @return [HaveTimelineEntryMetadata] A matcher that checks for specific metadata
          # @example
          #   expect(user).to have_timeline_entry_metadata(foo: 'bar', baz: 'biz')
          define_method(:"have_#{association_name_singularized}_metadata") do |expected_metadata|
            HaveTimelineEntryMetadata.new(expected_metadata, association_name)
          end
        end
      end

      # RSpec matcher to check if a model has timeline entries
      #
      # @api private
      class HaveTimelineEntriesMatcher
        # Initialize the matcher
        #
        # @param expected_count [Integer, nil] The expected number of timeline entries
        def initialize(expected_count, association_name)
          @expected_count = expected_count
          @association_name = association_name
        end

        # Check if the subject matches the expectations
        #
        # @param subject [Object] The model to check for timeline entries
        # @return [Boolean] True if the model has the expected number of timeline entries
        def matches?(subject)
          @subject = subject
          if @expected_count.nil?
            subject.public_send(@association_name).any?
          else
            subject.public_send(@association_name).count == @expected_count
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
              "but found #{@subject.public_send(@association_name).count}"
          end
        end

        # Message displayed when the negated expectation fails
        #
        # @return [String] A descriptive failure message for negated expectations
        def failure_message_when_negated
          if @expected_count.nil?
            "expected #{@subject} not to have any timeline entries, but found #{@subject.public_send(@association_name).count}"
          else
            "expected #{@subject} not to have #{@expected_count} timeline entries, but found exactly that many"
          end
        end
      end

      # RSpec matcher to check if a model has timeline entries with a specific action
      #
      # @api private
      class HaveTimelineAction
        # Initialize the matcher
        #
        # @param action [String, Symbol] The action to look for
        def initialize(action, association_name)
          @action = action.to_s
          @association_name = association_name
        end

        # Check if the subject matches the expectations
        #
        # @param subject [Object] The model to check for timeline entries
        # @return [Boolean] True if the model has timeline entries with the specified action
        def matches?(subject)
          @subject = subject
          @subject.public_send(@association_name).where(action: @action).exists?
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
      class HaveTimelineChange
        # Initialize the matcher
        #
        # @param attribute [String, Symbol] The attribute to check for changes
        def initialize(attribute, association_name)
          @attribute = attribute.to_s
          @association_name = association_name
        end

        # Check if the subject matches the expectations
        #
        # @param subject [Object] The model to check for timeline entries
        # @return [Boolean] True if the model has timeline entries with changes to the specified attribute
        def matches?(subject)
          @subject = subject
          @subject.public_send(@association_name).with_changed_attribute(@attribute).exists?
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
      class HaveTimelineEntry
        # Initialize the matcher
        #
        # @param attribute [String, Symbol] The attribute to check
        # @param value [Object] The value the attribute should have changed to
        def initialize(attribute, value, association_name)
          @attribute = attribute.to_s
          @value = value
          @association_name = association_name
        end

        # Check if the subject matches the expectations
        #
        # @param subject [Object] The model to check for timeline entries
        # @return [Boolean] True if the model has timeline entries where the attribute changed to the specified value
        def matches?(subject)
          @subject = subject
          @subject.public_send(@association_name).with_changed_value(@attribute, @value).exists?
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

      # RSpec matcher to check if a model has timeline entries with specific metadata
      #
      # @api private
      class HaveTimelineEntryMetadata
        # Initialize the matcher
        #
        # @param expected_metadata [Hash] The metadata key-value pairs to check for
        # @param association_name [Symbol] The name of the timeline association
        def initialize(expected_metadata, association_name)
          @expected_metadata = expected_metadata
          @association_name = association_name
        end

        # Check if the subject matches the expectations
        #
        # @param subject [Object] The model to check for timeline entries
        # @return [Boolean] True if the model has timeline entries with the specified metadata
        def matches?(subject)
          @subject = subject

          # Build a query that checks for each key-value pair in the metadata
          entries = subject.public_send(@association_name)

          # Construct queries for each metadata key-value pair
          @expected_metadata.all? do |key, value|
            # Use a JSON containment query to check if the metadata contains the key-value pair
            # This syntax works with PostgreSQL's JSONB containment operator @>
            entries.where('metadata @> ?', { key.to_s => value }.to_json).exists?
          end
        end

        # Message displayed when the expectation fails
        #
        # @return [String] A descriptive failure message
        def failure_message
          "expected #{@subject} to have timeline entries with metadata #{@expected_metadata.inspect}, but none was found"
        end

        # Message displayed when the negated expectation fails
        #
        # @return [String] A descriptive failure message for negated expectations
        def failure_message_when_negated
          "expected #{@subject} not to have timeline entries with metadata #{@expected_metadata.inspect}, but such entries were found"
        end
      end
    end
  end
end
