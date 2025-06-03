# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'

module ModelTimeline
  # Contains generators for setting up ModelTimeline in a Rails application.
  # These generators help with creating necessary database tables and configurations.
  module Generators
    # Rails generator that creates the necessary migration file for ModelTimeline.
    # his generator creates a migration to set up the timeline entries table.
    #
    # @example
    #   $ rails generate model_timeline:install
    #
    # @example With custom table name
    #   $ rails generate model_timeline:install --table_name=custom_timeline_entries
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('templates', __dir__)

      # @option options [String] :table_name ('model_timeline_timeline_entries')
      #   The name to use for the timeline entries database table
      class_option :table_name, type: :string, desc: 'Name for the timeline entries table'

      #   Returns the next migration number to be used in the migration filename
      #
      # @param [String] dirname The directory where migrations are stored
      # @return [String] The next migration number
      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      # Creates the migration file for ModelTimeline tables
      #
      # @return [void]
      def create_migration_file
        @table_name = options[:table_name] || 'model_timeline_timeline_entries'
        migration_template 'migration.rb.tt', 'db/migrate/create_model_timeline_tables.rb'
      end
    end
  end
end
