# frozen_string_literal: true

require 'spec_helper'
require 'model_timeline/generators/install_generator'

RSpec.describe ModelTimeline::Generators::InstallGenerator, type: :generator do
  destination File.expand_path('../../../../tmp', __dir__)

  before do
    prepare_destination
    run_generator
  end

  it 'creates a migration file with the correct name' do
    migration = Dir.glob(File.join(destination_root, 'db/migrate/*_create_model_timeline_tables.rb')).first
    expect(migration).not_to be_nil
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'includes expected content in the migration file' do
    migration = Dir.glob(File.join(destination_root, 'db/migrate/*_create_model_timeline_tables.rb')).first
    content = File.read(migration)

    expect(content).to include('create_table :model_timeline_timeline_entries')

    expect(content).to include('t.string :timelineable_type')
    expect(content).to include('t.bigint :timelineable_id')
    expect(content).to include('t.string :action, null: false')
    expect(content).to include('t.jsonb :object_changes, default: {}, null: false')
    expect(content).to include('t.string :user_type')
    expect(content).to include('t.bigint :user_id')
    expect(content).to include('t.string :username')
    expect(content).to include('t.inet :ip_address')
    expect(content).to include('t.timestamps')

    # rubocop:disable Layout/LineLength
    expect(content).to include("add_index :model_timeline_timeline_entries, [:timelineable_type, :timelineable_id], name: 'idx_timeline_on_timelineable'")
    expect(content).to include("add_index :model_timeline_timeline_entries, [:user_type, :user_id], name: 'idx_timeline_on_user'")
    expect(content).to include("add_index :model_timeline_timeline_entries, :object_changes, using: :gin, name: 'idx_timeline_on_changes'")
    expect(content).to include("add_index :model_timeline_timeline_entries, :ip_address, name: 'idx_timeline_on_ip'")
    # rubocop:enable Layout/LineLength
  end
  # rubocop:enable RSpec/MultipleExpectations

  context 'with custom table name' do
    before do
      prepare_destination
      run_generator(['--table_name=custom_timeline_entries'])
    end

    it 'creates a migration file with the correct name' do
      migration = Dir.glob(File.join(destination_root, 'db/migrate/*_create_model_timeline_tables.rb')).first
      expect(migration).not_to be_nil
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'includes custom table name in the migration file' do
      migration = Dir.glob(File.join(destination_root, 'db/migrate/*_create_model_timeline_tables.rb')).first
      content = File.read(migration)

      expect(content).to include('create_table :custom_timeline_entries')

      # Check that indexes use the custom table name
      # rubocop:disable Layout/LineLength
      expect(content).to include("add_index :custom_timeline_entries, [:timelineable_type, :timelineable_id], name: 'idx_timeline_on_timelineable'")
      expect(content).to include("add_index :custom_timeline_entries, [:user_type, :user_id], name: 'idx_timeline_on_user'")
      expect(content).to include("add_index :custom_timeline_entries, :object_changes, using: :gin, name: 'idx_timeline_on_changes'")
      expect(content).to include("add_index :custom_timeline_entries, :ip_address, name: 'idx_timeline_on_ip'")
      # rubocop:enable Layout/LineLength
    end
    # rubocop:enable RSpec/MultipleExpectations
  end
end
