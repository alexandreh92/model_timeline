# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'

module ModelTimeline
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('templates', __dir__)

      class_option :table_name, type: :string, desc: 'Name for the timeline entries table'

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def create_migration_file
        @table_name = options[:table_name] || 'model_timeline_timeline_entries'
        migration_template 'migration.rb.tt', 'db/migrate/create_model_timeline_tables.rb'
      end
    end
  end
end
