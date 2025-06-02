require 'rails/generators'
require 'rails/generators/active_record'

module ModelTimeline
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('templates', __dir__)

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def create_migration_file
        migration_template 'migration.rb.tt', 'db/migrate/create_model_timeline_tables.rb'
      end
    end
  end
end
