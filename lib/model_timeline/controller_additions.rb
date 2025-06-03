# frozen_string_literal: true

module ModelTimeline
  # Provides controller functionality for automatically tracking model timeline information.
  # When included in a controller, this module will capture the current user and IP address
  # for each request and make them available for timeline entries.
  #
  # @example Adding to a specific controller
  #   class ApplicationController < ActionController::Base
  #     include ModelTimeline::ControllerAdditions
  #   end
  #
  # @example Using the class method
  #   class ApplicationController < ActionController::Base
  #     track_actions_with_model_timeline
  #   end
  #
  module ControllerAdditions
    extend ActiveSupport::Concern

    included do
      before_action :set_model_timeline_info
      after_action :clear_model_timeline_info
    end

    # Sets the current user and IP address in the request store.
    # Called automatically as a before_action.
    #
    # @return [void]
    def set_model_timeline_info
      user = (send(ModelTimeline.current_user_method) if respond_to?(ModelTimeline.current_user_method, true))

      ip = begin
        if request.respond_to?(ModelTimeline.current_ip_method)
          request.send(ModelTimeline.current_ip_method)
        else
          request.remote_ip
        end
      rescue StandardError
        nil
      end

      ModelTimeline.store_user_and_ip(user, ip)
    end

    # Clears the request store after the request is complete.
    # Called automatically as an after_action.
    #
    # @return [void]
    def clear_model_timeline_info
      ModelTimeline.clear_request_store
    end

    #   Class methods added to the including controller.
    module ClassMethods
      # Convenience method to include ModelTimeline::ControllerAdditions in a controller.
      #
      # @return [void]
      def track_actions_with_model_timeline
        include ModelTimeline::ControllerAdditions
      end
    end
  end
end
