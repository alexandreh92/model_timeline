# frozen_string_literal: true

module ModelTimeline
  module ControllerAdditions
    extend ActiveSupport::Concern

    included do
      before_action :set_model_timeline_info
      after_action :clear_model_timeline_info
    end

    # Set user and IP address for the current request
    def set_model_timeline_info
      user = if respond_to?(ModelTimeline.current_user_method, true)
               send(ModelTimeline.current_user_method)
             else
               nil
             end

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

    # Clear stored info after request is completed
    def clear_model_timeline_info
      ModelTimeline.clear_request_store
    end

    module ClassMethods
      # Include this method in your ApplicationController to enable ModelTimeline
      def track_actions_with_model_timeline
        include ModelTimeline::ControllerAdditions
      end
    end
  end
end
