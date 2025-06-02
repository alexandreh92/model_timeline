require "spec_helper"
require 'model_timeline/generators/install_generator'

RSpec.describe ModelTimeline::Generators::InstallGenerator, type: :generator do
  destination File.expand_path("../../../../../tmp", __FILE__)

  before(:all) do
    prepare_destination
    run_generator
  end

  it "creates a migration file with the correct name" do
    migration = Dir.glob(File.join(destination_root, "db/migrate/*_create_model_timeline_tables.rb")).first
    expect(migration).to_not be_nil
  end

  it "includes expected content in the migration file" do
    migration = Dir.glob(File.join(destination_root, "db/migrate/*_create_model_timeline_tables.rb")).first
    content = File.read(migration)

    expect(content).to include("create_table :model_timeline_timeline_entries")
    expect(content).to include("t.jsonb :object_changes")
    expect(content).to include("add_index :model_timeline_timeline_entries, [:auditable_type, :auditable_id]")
  end
end
