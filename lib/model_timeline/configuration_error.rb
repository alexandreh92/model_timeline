module ModelTimeline
  class ConfigurationError < StandardError
    def initialize(message = 'Multiple definitions of the same configuration found. ' \
                             'Please ensure that each configuration is unique.')
      super
    end
  end
end
