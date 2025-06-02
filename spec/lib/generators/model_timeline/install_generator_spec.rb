require 'spec_helper'
require 'generators/model_timeline/install_generator'
require 'rails/generators/testing/behaviour'
require 'rails/generators/testing/assertions'

RSpec.describe ModelTimeline::Generators::InstallGenerator do
  include Rails::Generators::Testing::Behaviour
  include Rails::Generators::Testing::Assertions

  # Use a temp directory for generator tests
  destination File.expand_path('../../../../tmp', __dir__)

  before do
    prepare_destination

    # Create a mock migration directory
    FileUtils.mkdir_p("#{destination_root}/db/migrate")
  end

  it 'creates a migration file' do
    # Run generator in isolation
    allow_any_instance_of(described_class).to receive(:next_migration_number).and_return('20240601000000')
    run_generator

    # Assert migration file was created
    assert_migration 'db/migrate/20240601000000_create_model_timeline_tables.rb' do |migration|
      assert_match(/create_table :model_timeline_audit_instances/, migration)
      assert_match(/t.jsonb :changes/, migration)
    end
  end
end
