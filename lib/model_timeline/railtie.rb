# frozen_string_literal: true

module ModelTimeline
  # Rails integration for ModelTimeline.
  # This Railtie automatically integrates ModelTimeline with Rails by:
  #   - Including the Timelineable module in all ActiveRecord models
  #   - Making controller helper methods available in all ActionControllers
  #
  # @example
  #   # This class is automatically loaded by Rails, no manual inclusion required
  #   # Rails.application.initialize!
  #
  class Railtie < Rails::Railtie
    # @!method initializer(name, &block)
    #   Initializes ModelTimeline by including necessary modules in Rails components.
    #   Called automatically when Rails loads.
    #
    #   @param name [String] The name of the initializer
    #   @param block [Proc] The initialization code to run
    #   @return [void]
    initializer 'model_timeline.initialize' do
      ActiveSupport.on_load(:active_record) do
        include Timelineable
      end

      ActiveSupport.on_load(:action_controller) do
        include ControllerAdditions::ClassMethods
      end
    end
  end
end
