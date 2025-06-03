# frozen_string_literal: true

module ModelTimeline
  # Error raised when there's an issue with ModelTimeline configuration.
  # This error is typically raised when attempting to define multiple timeline
  # configurations for the same model and timeline entry class combination.
  #
  # @example Raising the error
  #   raise ModelTimeline::ConfigurationError.new
  #
  # @example With custom message
  #   raise ModelTimeline::ConfigurationError.new("Custom error message")
  #
  class ConfigurationError < StandardError
    # Initialize a new ConfigurationError
    #
    # @param message [String] Custom error message
    # @return [ModelTimeline::ConfigurationError] A new instance of ConfigurationError
    def initialize(message = 'Multiple definitions of the same configuration found. ' \
                             'Please ensure that each configuration is unique.')
      super
    end
  end
end
