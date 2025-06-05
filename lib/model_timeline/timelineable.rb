# frozen_string_literal: true

module ModelTimeline
  # Provides timeline tracking functionality for ActiveRecord models.
  # When included in a model, this module allows tracking changes to model attributes
  # over time by creating timeline entries.
  #
  # @example Basic usage
  #   class User < ApplicationRecord
  #     has_timeline
  #   end
  #
  # @example With custom options
  #   class Product < ApplicationRecord
  #     has_timeline :product_history,
  #                 only: [:name, :price],
  #                 on: [:update, :destroy]
  #   end
  #
  module Timelineable
    extend ActiveSupport::Concern

    included do
      class_attribute :loggers, default: {}
    end

    # Methods that will be added as class methods to the including class
    class_methods do
      # Enables timeline tracking for the model.
      # This method configures the model to record timeline entries on various
      # lifecycle events (create, update, destroy).
      #
      # @param association_name [Symbol] The name for the timeline entries association
      # @param options [Hash] Configuration options
      # @option options [Array<Symbol>] :on ([:create, :update, :destroy]) Which events to track
      # @option options [Array<Symbol>] :only Limit tracking to these attributes only
      # @option options [Array<Symbol>] :ignore ([]) Attributes to exclude from tracking
      # @option options [String] :class_name ('ModelTimeline::TimelineEntry') The timeline entry class
      # @option options [Hash] :meta ({}) Additional metadata to include with each entry
      # @return [void]
      # @raise [ModelTimeline::ConfigurationError] If timeline has already been configured
      #
      # @example Track all changes
      #   has_timeline
      #
      # @example Track only specific attributes
      #   has_timeline(only: [:name, :status])
      #
      # @example Use a custom association name
      #   has_timeline(:audit_log)
      #
      # @example Add metadata to entries
      #   has_timeline(meta: { app_version: APP_VERSION })
      #
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Naming/PredicateName
      def has_timeline(*args, **kwargs)
        if defined?(Rails.env) && Rails.env.development? && caller.any? { |line| line.include?('reload!') }
          loggers.clear # Reset loggers during reload! in console
        end

        association_name = args.first.is_a?(Symbol) ? args.shift : :timeline_entries

        klass = (kwargs[:class_name] || 'ModelTimeline::TimelineEntry').constantize

        config = {
          on: kwargs[:on] || %i[create update destroy],
          only: kwargs[:only],
          ignore: kwargs[:ignore] || [],
          klass: klass,
          meta: kwargs[:meta] || {}
        }

        config_key = "#{to_s.underscore}-#{klass}"
        raise ::ModelTimeline::ConfigurationError if loggers[config_key].present?

        loggers[config_key] = config

        after_save -> { log_after_save(config_key) } if config[:on].include?(:create) || config[:on].include?(:update)

        after_destroy -> { log_audit_deletion(config_key) } if config[:on].include?(:destroy)

        has_many association_name.to_sym, class_name: klass.name, as: :timelineable
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Naming/PredicateName
    end

    private

      # Records timeline entries after a model is saved (create or update)
      #
      # @param config_key [String] The configuration key for this model
      # @return [void]
      def log_after_save(config_key)
        return unless ModelTimeline.enabled?

        config = self.class.loggers[config_key]
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
          metadata: object_metadata(config),
          ip_address: current_ip_address,
          **current_user_attributes,
          **column_metadata(config)
        )
      end

      # Records timeline entries after a model is destroyed
      #
      # @param config_key [String] The configuration key for this model
      # @return [void]
      def log_audit_deletion(config_key)
        return unless ModelTimeline.enabled?

        config = self.class.loggers[config_key]
        return unless config

        config[:klass].create!(
          timelineable_type: self.class.name,
          timelineable_id: id,
          action: 'destroy',
          object_changes: {},
          metadata: object_metadata(config),
          ip_address: current_ip_address,
          **current_user_attributes,
          **column_metadata(config)
        )
      end

      # Gets the current user ID if available
      #
      # @return [Integer, nil] The current user ID or nil if not available
      def current_user_id
        return unless respond_to?(ModelTimeline.current_user_method)

        user = send(ModelTimeline.current_user_method)
        user.respond_to?(:id) ? user.id : nil
      end

      # Gets the current IP address from the request store
      #
      # @return [String, nil] The current IP address or nil if not available
      def current_ip_address
        ModelTimeline.current_ip
      end

      # Prepares user attributes for the timeline entry
      #
      # @return [Hash] User attributes for the timeline entry
      def current_user_attributes
        user = ModelTimeline.current_user
        return {} if user.nil?

        return { username: user.to_s } if user.is_a?(String) || user.is_a?(Symbol)

        return { user_id: user.id, user_type: user.class.name } if user.respond_to?(:id) &&
                                                                   user.class.ancestors.include?(ActiveRecord::Base)

        return { username: user.to_s } if user.respond_to?(:to_s)

        {}
      end

      # Filters attributes based on configuration
      #
      # @param attrs [Hash] The attributes to filter
      # @param config [Hash] The timeline configuration
      # @return [Hash] Filtered attributes
      def filter_attributes(attrs, config)
        result = attrs.dup.with_indifferent_access
        result = result.slice(*config[:only]) if config[:only].present?
        result = result.except(*config[:ignore]) if config[:ignore].present?

        result
      end

      # Collects metadata for the timeline entry
      #
      # @param meta_config [Hash, Proc] The metadata configuration
      # @return [Hash] Collected metadata
      def collect_metadata(meta_config)
        metadata = {}

        # First, add any thread-level metadata
        metadata.merge!(ModelTimeline.metadata)

        # Then, add any model-specific metadata from config
        metadata.merge!(resolve_metadata_value(meta_config))

        metadata
      end

      # Recursively resolves metadata values
      #
      # @param value [Hash, Proc, Symbol, Object] The value to resolve
      # @return [Hash, Object] The resolved value
      def resolve_metadata_value(value)
        case value
        when Proc
          # If it's a Proc, execute it and process the result recursively
          proc_result = instance_exec(self, &value)
          proc_result.is_a?(Hash) ? process_metadata_hash(proc_result) : proc_result
        when Hash
          # If it's a Hash, process each key-value pair
          process_metadata_hash(value)
        when Symbol
          # If it's a Symbol, try to call the method
          respond_to?(value) ? send(value) : value
        else
          # Any other value, return as-is
          value
        end
      end

      # Processes a metadata hash by resolving each value
      #
      # @param hash [Hash] The hash to process
      # @return [Hash] The processed hash
      def process_metadata_hash(hash)
        result = {}
        hash.each do |key, val|
          result[key] = resolve_metadata_value(val)
        end
        result
      end

      def column_metadata(config)
        metadata = collect_metadata(config[:meta])
        column_names = config[:klass].column_names.map(&:to_sym)
        metadata.slice(*column_names)
      end

      def object_metadata(config)
        metadata = collect_metadata(config[:meta])
        column_names = config[:klass].column_names.map(&:to_sym)
        metadata.except(*column_names)
      end
  end
end
