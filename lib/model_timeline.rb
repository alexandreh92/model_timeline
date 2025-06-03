# frozen_string_literal: true

require 'model_timeline/version'
require 'model_timeline/timelineable'
require 'model_timeline/timeline_entry'
require 'model_timeline/controller_additions'
require 'model_timeline/configuration_error'
require 'model_timeline/generators/install_generator' if defined?(Rails)
require 'model_timeline/railtie' if defined?(Rails)
require 'model_timeline/rspec' if defined?(RSpec)
require 'model_timeline/rspec/matchers' if defined?(RSpec)

# A module for tracking and recording changes to ActiveRecord models.
#
# ModelTimeline provides functionality to create and maintain a history of model changes,
# including user attribution, timestamps, and additional contextual metadata.
#
# @example Basic configuration
#   ModelTimeline.configure do |config|
#     config.current_user_method = :current_admin
#     config.current_ip_method = :visitor_ip
#   end
#
# @example Temporarily disabling timeline tracking
#   ModelTimeline.without_timeline do
#     # Changes made here won't be recorded
#     user.update(name: 'New Name')
#   end
#
# @example Using with custom user and metadata
#   ModelTimeline.with_timeline(current_user: admin, metadata: {reason: 'Admin action'}) do
#     user.update(status: 'suspended')
#   end
#
module ModelTimeline
  class << self
    # Sets the method name used to retrieve the current user
    # @param method_name [Symbol, String] The method name to call
    attr_writer :current_user_method

    # Sets the method name used to retrieve the client IP address
    # @param method_name [Symbol, String] The method name to call
    attr_writer :current_ip_method

    # Sets whether timeline recording is enabled
    # @param value [Boolean] true to enable, false to disable
    attr_writer :enabled

    # Configures the ModelTimeline module
    #
    # @yield [self] Yields the ModelTimeline module for configuration
    # @return [void]
    def configure
      yield self if block_given?
    end

    # Gets the method name used to retrieve the current user
    #
    # @return [Symbol] The method name, defaults to :current_user
    def current_user_method
      @current_user_method || :current_user
    end

    # Gets the method name used to retrieve the client IP address
    #
    # @return [Symbol] The method name, defaults to :remote_ip
    def current_ip_method
      @current_ip_method || :remote_ip
    end

    # Checks if timeline recording is enabled
    #
    # @return [Boolean] true if enabled or not explicitly disabled, false otherwise
    def enabled?
      @enabled.nil? || @enabled
    end

    # Enables timeline recording
    #
    # @return [true] Always returns true
    def enable!
      self.enabled = true
    end

    # Disables timeline recording
    #
    # @return [false] Always returns false
    def disable!
      self.enabled = false
    end

    # Temporarily disables timeline recording for the duration of the block
    #
    # @yield The block to execute with timeline recording disabled
    # @return [Object] Returns the result of the block
    def without_timeline
      previous_state = enabled?
      disable!
      yield
    ensure
      self.enabled = previous_state
    end

    # Temporarily sets custom user, IP, and metadata for timeline entries
    #
    # @param current_user [Object, nil] The user to associate with timeline entries
    # @param current_ip [String, nil] The IP address to associate with timeline entries
    # @param metadata [Hash] Additional metadata to store with timeline entries
    # @yield The block to execute with the custom context
    # @return [Object] Returns the result of the block
    def with_timeline(current_user: nil, current_ip: nil, metadata: {}, &block)
      previous_user = ModelTimeline.current_user
      previous_ip = ModelTimeline.current_ip
      previous_metadata = ModelTimeline.metadata.dup

      ModelTimeline.store_user_and_ip(current_user, current_ip) if current_user || current_ip
      ModelTimeline.with_metadata(metadata, &block)
    ensure
      ModelTimeline.store_user_and_ip(previous_user, previous_ip)
      ModelTimeline.metadata = previous_metadata
    end

    # Gets the thread-local storage hash for the current request
    #
    # @api private
    # @return [Hash] The request store hash
    def request_store
      Thread.current[:model_timeline_request_store] ||= {}
    end

    # Stores the current user and IP address in thread-local storage
    #
    # @param user [Object] The current user
    # @param ip_address [String] The current IP address
    # @return [void]
    def store_user_and_ip(user, ip_address)
      request_store[:current_user] = user
      request_store[:ip_address] = ip_address
    end

    # Gets the current user from thread-local storage
    #
    # @return [Object, nil] The current user or nil if not set
    def current_user
      request_store[:current_user]
    end

    # Gets the current IP address from thread-local storage
    #
    # @return [String, nil] The current IP address or nil if not set
    def current_ip
      request_store[:ip_address]
    end

    # Clears all data from the request store
    #
    # @return [Hash] The empty request store
    def clear_request_store
      Thread.current[:model_timeline_request_store] = {}
    end

    # Gets the current metadata hash from thread-local storage
    #
    # @return [Hash] The metadata hash
    def metadata
      Thread.current[:model_timeline_metadata] ||= {}
    end

    # Sets the metadata hash in thread-local storage
    #
    # @param hash [Hash] The metadata hash to store
    # @return [Hash] The provided metadata hash
    def metadata=(hash)
      Thread.current[:model_timeline_metadata] = hash
    end

    # Temporarily merges additional metadata for the duration of the block
    #
    # @param hash [Hash] The metadata to merge with the current metadata
    # @yield The block to execute with the merged metadata
    # @return [Object] Returns the result of the block
    def with_metadata(hash)
      previous_metadata = metadata.dup
      self.metadata = metadata.merge(hash)
      yield
    ensure
      self.metadata = previous_metadata
    end

    # Clears all metadata from thread-local storage
    #
    # @return [Hash] The empty metadata hash
    def clear_metadata!
      Thread.current[:model_timeline_metadata] = {}
    end
  end
end
