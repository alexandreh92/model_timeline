module ModelTimeline
  module Timelineable
    extend ActiveSupport::Concern

    included do
      class_attribute :audit_loggers, default: {}
    end

    class_methods do
      def has_timeline(association_name = 'timeline_entries', options = {})

        klass = (options[:class_name] || 'ModelTimeline::TimelineEntry').constantize

        # Default options
        config = {
          table_name: options[:table_name] || "model_timeline_timeline_entries",
          on: options[:on] || [:create, :update, :destroy],
          only: options[:only],
          ignore: options[:ignore] || [],
          klass: klass
        }

        # Store configuration
        self.audit_loggers[association_name] = config

        # Set up callbacks based on events
        if config[:on].include?(:create) || config[:on].include?(:update)
          after_save -> { log_after_save(association_name) }
        end

        if config[:on].include?(:destroy)
          after_destroy -> { log_audit_deletion(association_name) }
        end

        has_many association_name.to_sym, class_name: klass.name, as: :auditable
      end
    end

    private

    def log_after_save(association_name)
      config = self.class.audit_loggers[association_name]
      return unless config

      object_changes = filter_attributes(self.previous_changes, config)
      return if object_changes.empty?

      action = previously_new_record? ? 'create' : 'update'

      config[:klass].create!(
        auditable_type: self.class.name,
        auditable_id: self.id,
        audit_log_table: config[:table_name],
        audit_action: action,
        object_changes: object_changes,
        audited_at: Time.current,
        ip_address: current_ip_address,
        **current_user_attributes
      )
    end

    def log_audit_deletion(association_name)
      config = self.class.audit_loggers[association_name]
      return unless config

      config[:klass].create!(
        auditable_type: self.class.name,
        auditable_id: self.id,
        audit_log_table: config[:table_name],
        audit_action: 'destroy',
        object_changes: {},
        audited_at: Time.current,
        ip_address: current_ip_address,
        **current_user_attributes
      )
    end

    def current_user_id
      if respond_to?(ModelTimeline.current_user_method)
        user = send(ModelTimeline.current_user_method)
        user.respond_to?(:id) ? user.id : nil
      end
    end

    def current_ip_address
      ModelTimeline.current_ip
    end

    def current_user_attributes
      user = ModelTimeline.current_user
      return {} if user.nil?

      return { username: user.to_s } if user.is_a?(String) || user.is_a?(Symbol)

      return { user_id: user.id, user_type: user.class.name } if user.respond_to?(:id) &&
        user.class.ancestors.include?(ActiveRecord::Base)

      return { username: user.to_s } if user.respond_to?(:to_s)

      {}
    end

    def filter_attributes(attrs, config)
      result = attrs.dup.with_indifferent_access

      # Apply "only" filter if present
      if config[:only].present?
        result = result.slice(*config[:only])
      end

      # Apply "ignore" filter if present
      if config[:ignore].present?
        result = result.except(*config[:ignore])
      end

      result
    end
  end
end
