module ModelTimeline
  class Railtie < Rails::Railtie
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
