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

  # Class variable to store request information
  @@request_store = {}

  def self.store_user_and_ip(user, ip_address)
    @@request_store[:current_user] = user
    @@request_store[:ip_address] = ip_address
  end

  def self.current_user
    @@request_store[:current_user]
  end

  def self.current_ip
    @@request_store[:ip_address]
  end

  def self.clear_request_store
    @@request_store = {}
  end
end
