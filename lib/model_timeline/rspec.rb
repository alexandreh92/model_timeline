# frozen_string_literal: true

require 'model_timeline/rspec/matchers'
module ModelTimeline
  # Helper module that configures RSpec to work with ModelTimeline
  #
  # This module provides RSpec configuration for ModelTimeline, including:
  # - Disabling timeline recording by default for faster tests
  # - Enabling timeline recording only when specifically requested
  # - Including custom RSpec matchers for testing timeline entries
  #
  # @example Including in RSpec configuration
  #   # In spec_helper.rb or rails_helper.rb
  #   RSpec.configure do |config|
  #     config.include ModelTimelineHelper
  #   end
  #
  # @example Running a test with timeline recording enabled
  #   # Use the :with_timeline metadata to enable recording
  #   describe User, :with_timeline do
  #     it "records timeline entries when updated" do
  #       user.update(name: "New Name")
  #       expect(user).to have_timelined_change(:name)
  #     end
  #   end
  module RSpec
    # Configures RSpec with ModelTimeline hooks when included
    #
    # @param config [RSpec::Core::Configuration] The RSpec configuration object
    # @return [void]
    def self.included(config)
      # Reset timeline state before each example
      config.before(:each) do |example|
        ModelTimeline.disable! unless example.metadata[:with_timeline]
      end

      # Enable timeline when the :with_timeline metadata is present
      config.around(:each, :with_timeline) do |example|
        ModelTimeline.enable!
        example.run
      ensure
        ModelTimeline.disable!
      end

      # Include custom RSpec matchers for testing timeline entries
      config.include ModelTimeline::RSpec::Matchers
    end
  end
end
