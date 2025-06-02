ActiveRecord::Schema.define do
   # Timeline entries table
  create_table :model_timeline_timeline_entries, force: true do |t|
    t.string :auditable_type
    t.bigint :auditable_id
    t.string :audit_log_table, null: false
    t.string :audit_action, null: false
    t.jsonb :object_changes, default: {}, null: false
    t.datetime :audited_at

    # Polymorphic user association
    t.string :user_type
    t.bigint :user_id
    t.string :username

    # IP address tracking
    t.inet :ip_address

    t.timestamps
  end

  # Use shorter index names to avoid PostgreSQL's 63-character limit
  add_index :model_timeline_timeline_entries, [:auditable_type, :auditable_id], name: 'idx_timeline_on_auditable'
  add_index :model_timeline_timeline_entries, :audit_log_table, name: 'idx_timeline_on_log_table'
  add_index :model_timeline_timeline_entries, [:user_type, :user_id], name: 'idx_timeline_on_user'
  add_index :model_timeline_timeline_entries, :object_changes, using: :gin, name: 'idx_timeline_on_object_changes'
  add_index :model_timeline_timeline_entries, :ip_address, name: 'idx_timeline_on_ip'

  # Test models
  create_table :users, force: true do |t|
    t.string :username
    t.string :email
    t.string :password_digest

    t.timestamps
  end

  create_table :posts, force: true do |t|
    t.string :title
    t.text :content
    t.references :user, foreign_key: true

    t.timestamps
  end
end
