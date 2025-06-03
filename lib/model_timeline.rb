# frozen_string_literal: true

require 'model_timeline/version'
require 'model_timeline/timelineable'
require 'model_timeline/timeline_entry'
require 'model_timeline/controller_additions'
require 'model_timeline/configuration_error'
require 'model_timeline/generators/install_generator' if defined?(Rails)
require 'model_timeline/railtie' if defined?(Rails)

module ModelTimeline
  # Configuration options
  class << self
    attr_writer :current_user_method, :current_ip_method

    def configure
      yield self if block_given?
    end

    def current_user_method
      @current_user_method || :current_user
    end

    def current_ip_method
      @current_ip_method || :remote_ip
    end
  end

  # Thread-local storage for request information
  def self.request_store
    Thread.current[:model_timeline_request_store] ||= {}
  end

  def self.store_user_and_ip(user, ip_address)
    request_store[:current_user] = user
    request_store[:ip_address] = ip_address
  end

  def self.current_user
    request_store[:current_user]
  end

  def self.current_ip
    request_store[:ip_address]
  end

  def self.clear_request_store
    Thread.current[:model_timeline_request_store] = {}
  end

  # Metadata handling
  def self.metadata
    Thread.current[:model_timeline_metadata] ||= {}
  end

  def self.metadata=(hash)
    Thread.current[:model_timeline_metadata] = hash
  end

  def self.with_metadata(hash)
    previous_metadata = metadata.dup
    self.metadata = metadata.merge(hash)
    yield
  ensure
    self.metadata = previous_metadata
  end

  def self.clear_metadata!
    Thread.current[:model_timeline_metadata] = {}
  end
end
