# frozen_string_literal: true

module ModelTimeline
  module Timelineable
    extend ActiveSupport::Concern

    included do
      class_attribute :audit_loggers, default: {}
    end

    class_methods do
      # rubocop:disable Metrics/CyclomaticComplexity
      def has_timeline(association_name = :timeline_entries, options = {}) # rubocop:disable Naming/PredicateName
        klass = (options[:class_name] || 'ModelTimeline::TimelineEntry').constantize

        config = {
          on: options[:on] || %i[create update destroy],
          only: options[:only],
          ignore: options[:ignore] || [],
          klass: klass
        }

        config_key = "#{to_s.underscore}-#{klass}"
        raise ::ModelTimeline::ConfigurationError if audit_loggers[config_key].present?

        audit_loggers[config_key] = config

        after_save -> { log_after_save(config_key) } if config[:on].include?(:create) || config[:on].include?(:update)

        after_destroy -> { log_audit_deletion(config_key) } if config[:on].include?(:destroy)

        has_many association_name.to_sym, class_name: klass.name, as: :timelineable
      end
      # rubocop:enable Metrics/CyclomaticComplexity
    end

    private

      def log_after_save(config_key)
        config = self.class.audit_loggers[config_key]
        return unless config

        object_changes = filter_attributes(previous_changes, config)
        return if object_changes.empty?

        action = previously_new_record? ? :create : :update
        return unless config[:on].include?(action)

        config[:klass].create!(
          timelineable_type: self.class.name,
          timelineable_id: id,
          action: action,
          object_changes: object_changes,
          ip_address: current_ip_address,
          **current_user_attributes
        )
      end

      def log_audit_deletion(config_key)
        config = self.class.audit_loggers[config_key]
        return unless config

        config[:klass].create!(
          timelineable_type: self.class.name,
          timelineable_id: id,
          action: 'destroy',
          object_changes: {},
          ip_address: current_ip_address,
          **current_user_attributes
        )
      end

      def current_user_id
        return unless respond_to?(ModelTimeline.current_user_method)

        user = send(ModelTimeline.current_user_method)
        user.respond_to?(:id) ? user.id : nil
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
        result = result.slice(*config[:only]) if config[:only].present?
        result = result.except(*config[:ignore]) if config[:ignore].present?

        result
      end
  end
end
